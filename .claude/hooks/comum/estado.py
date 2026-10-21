#!/usr/bin/env python3
"""Mantém estado e handoff derivados somente nos marcos da RunX."""

import argparse
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import expx_rastro as R  # noqa: E402
import rastro as CLI_RASTRO  # noqa: E402


PADRAO = {
    "expx_estado": 1,
    "atualizado_em": None,
    "trabalho": None,
    "ferramenta": "runx",
    "titulo_curto": None,
    "fase": None,
    "task": None,
    "tasks_concluidas": 0,
    "tasks_total": 0,
    "raio": None,
    "orcamento_arquivos": None,
    "orcamento_linhas": None,
    "branch": None,
    "pr_estado": None,
    "bloqueios": 0,
}
TIPOS = {"transicao", "bloqueio", "decisao", "termino"}
TRANSICOES = {
    ("e1", "e2"), ("e2", "e3"), ("e3", "e1"),
    ("e3", "e4"), ("e4", "e3"), ("e4", "e5"),
}


def agora_padrao():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def escrever_atomico(caminho, conteudo, modo=0o600):
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    fd, temporario = tempfile.mkstemp(
        dir=os.path.dirname(caminho), prefix=os.path.basename(caminho) + ".", suffix=".tmp"
    )
    try:
        os.chmod(temporario, modo)
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as arquivo:
            arquivo.write(conteudo)
            arquivo.flush()
            os.fsync(arquivo.fileno())
        os.replace(temporario, caminho)
    finally:
        try:
            os.unlink(temporario)
        except FileNotFoundError:
            pass


def ler_estado(caminho):
    estado = dict(PADRAO)
    try:
        with open(caminho, encoding="utf-8") as arquivo:
            anterior = json.load(arquivo)
        if isinstance(anterior, dict):
            estado.update(anterior)
    except (OSError, ValueError):
        pass
    return estado


def artefatos(ocorrencia):
    orquestrador = os.path.join(ocorrencia, "ORQUESTRADOR.md")
    fm_orq = R.frontmatter(orquestrador)
    tasks = []
    for base, _, nomes in os.walk(ocorrencia):
        for nome in nomes:
            if nome != "tasks.md":
                continue
            fm = R.frontmatter(os.path.join(base, nome))
            tasks.extend(R.lista(fm.get("tasks")))
    tasks = [R.mapa(task) for task in tasks]
    concluidas = sum(task.get("status") == "concluida" for task in tasks)
    corrente = next((str(task.get("id")) for task in tasks if task.get("status") == "em_andamento"), None)
    bloqueios = R.lista(R.frontmatter(os.path.join(ocorrencia, "BLOQUEIOS.md")).get("bloqueios"))
    abertos = sum(R.mapa(item).get("resolvido_em") in (None, "") for item in bloqueios)
    return fm_orq, tasks, concluidas, corrente, abertos


def atualizar_orquestrador(caminho, fase, tipo, agora):
    try:
        with open(caminho, encoding="utf-8") as arquivo:
            texto = arquivo.read()
    except OSError:
        raise ValueError("ORQUESTRADOR.md ausente")
    data = agora[:10]
    texto = re.sub(r"(?m)^estagio:.*$", f"estagio: {fase}", texto, count=1)
    texto = re.sub(r"(?m)^atualizado_em:.*$", f"atualizado_em: {data}", texto, count=1)
    if tipo == "termino":
        texto = re.sub(r"(?m)^status:.*$", "status: concluido", texto, count=1)
        texto = re.sub(r"(?m)^concluido_em:.*$", f"concluido_em: {data}", texto, count=1)
    escrever_atomico(caminho, texto, 0o644)


def caminhos_handoff(raiz, ocorrencia):
    candidatos = [
        "ORQUESTRADOR.md", "01-CAUSA-RAIZ.md", "BLOQUEIOS.md",
        "00-DECISOES.md", "QA.md",
    ]
    candidatos.extend(
        os.path.relpath(os.path.join(base, nome), ocorrencia)
        for base, _, nomes in os.walk(ocorrencia)
        for nome in nomes if nome == "tasks.md"
    )
    saida = []
    for relativo in candidatos:
        absoluto = os.path.join(ocorrencia, relativo)
        if os.path.isfile(absoluto):
            saida.append(os.path.relpath(absoluto, raiz).replace(os.sep, "/"))
    return saida


def derivar(raiz, ocorrencia, agora, marco_tipo=None, marco_id=None, fase_forcada=None):
    orquestrador = os.path.join(ocorrencia, "ORQUESTRADOR.md")
    fm, tasks, concluidas, corrente, bloqueios = artefatos(ocorrencia)
    fase = fase_forcada or R.texto(fm.get("estagio"))
    trabalho = R.texto(fm.get("trabalho_id")) or os.path.basename(ocorrencia).split("-")[0]
    titulo = " ".join((R.texto(fm.get("titulo")) or trabalho).split())[:30]
    estado_path = os.path.join(raiz, ".expx", "estado.json")
    estado = ler_estado(estado_path)
    estado.update({
        "expx_estado": 1,
        "atualizado_em": agora,
        "trabalho": None if marco_tipo == "termino" else trabalho,
        "ferramenta": "runx",
        "titulo_curto": titulo,
        "fase": None if marco_tipo == "termino" else fase,
        "task": None if marco_tipo == "termino" else corrente,
        "tasks_concluidas": concluidas,
        "tasks_total": len(tasks),
        "bloqueios": bloqueios,
    })
    if os.path.isdir(os.path.join(raiz, ".expx")):
        bruto = json.dumps(estado, ensure_ascii=False, separators=(",", ":")) + "\n"
        if len(bruto.encode("utf-8")) >= 1024:
            raise ValueError("estado excede 1 KB")
        escrever_atomico(estado_path, bruto)

        linhas = [
            "# Handoff RunX",
            f"- trabalho: {trabalho}",
            f"- estágio: {fase}",
            f"- task: {corrente or 'nenhuma'}",
            f"- progresso: {concluidas}/{len(tasks)}",
        ]
        if marco_tipo:
            linhas.append(f"- último marco: {marco_tipo}/{marco_id}")
        linhas.append("- artefatos:")
        linhas.extend(f"  - `{p}`" for p in caminhos_handoff(raiz, ocorrencia))
        linhas.append(f"- próximo comando: `estado.py reconstruir --ocorrencia {os.path.relpath(ocorrencia, raiz).replace(os.sep, '/')}`")
        handoff = "\n".join(linhas) + "\n"
        if len(handoff.encode("utf-8")) > 2000:
            raise ValueError("handoff excede 500 tokens")
        escrever_atomico(os.path.join(raiz, ".expx", "handoff.md"), handoff)
    return trabalho, fase


def executar(args):
    raiz = os.path.realpath(os.getcwd())
    ocorrencia = os.path.realpath(args.ocorrencia)
    if os.path.commonpath((raiz, ocorrencia)) != raiz:
        raise ValueError("ocorrencia fora da raiz")
    agora = args.agora or agora_padrao()

    if args.comando == "reconstruir":
        derivar(raiz, ocorrencia, agora)
        return 0

    if args.tipo not in TIPOS:
        raise ValueError("tipo de marco invalido")
    fm = R.frontmatter(os.path.join(ocorrencia, "ORQUESTRADOR.md"))
    fase_atual = R.texto(fm.get("estagio"))
    fase_nova = fase_atual
    if args.tipo == "transicao":
        fase_nova = args.resultado
        if (fase_atual, fase_nova) not in TRANSICOES:
            raise ValueError("transicao invalida")
    atualizar_orquestrador(os.path.join(ocorrencia, "ORQUESTRADOR.md"), fase_nova, args.tipo, agora)
    trabalho, fase = derivar(raiz, ocorrencia, agora, args.tipo, args.id, fase_nova)
    CLI_RASTRO.gravar_mecanico(
        tipo=args.tipo, trabalho=trabalho, fase=fase, identificador=args.id,
        resultado=args.resultado, raiz=raiz,
    )
    return 0


def parser():
    p = argparse.ArgumentParser(description="mantém estado derivado da RunX")
    sub = p.add_subparsers(dest="comando", required=True)
    marco = sub.add_parser("marco")
    marco.add_argument("--ocorrencia", required=True)
    marco.add_argument("--tipo", required=True, choices=sorted(TIPOS))
    marco.add_argument("--id", required=True)
    marco.add_argument("--resultado", required=True)
    marco.add_argument("--agora")
    reconstruir = sub.add_parser("reconstruir")
    reconstruir.add_argument("--ocorrencia", required=True)
    reconstruir.add_argument("--agora")
    return p


def main():
    try:
        return executar(parser().parse_args())
    except Exception:
        return 1


if __name__ == "__main__":
    sys.exit(main())
