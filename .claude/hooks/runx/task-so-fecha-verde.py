#!/usr/bin/env python3
"""Barra `status: concluida` sem suite verde ou parcial, e sem os dois testes.

`PreToolUse` em Write|Edit sobre `tasks.md`. Le a escrita PROPOSTA — nao o
arquivo em disco — porque o que interessa e o que esta prestes a ser gravado.

Regras 4 e 9 do SKILL.md: nao existe "concluido com ressalva". Com
`revisao_por_task.modo: obrigatoria` (pelo leitor do nucleo), a task que a escrita
leva a `concluida` precisa tambem da evidencia da revisao por task
(docs/entregas/<OC-ID>/revisao/<T-NN.MM>.json, arquivo comum; DR-106).
Nasce em AVISO. Falha ABERTA.
"""

import os
import re
import sys

sys.dont_write_bytecode = True  # o __pycache__ viraria desvio no E1 da mergex
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))
import expx_rastro as R  # noqa: E402

NOME = "task-so-fecha-verde"
ALVO = re.compile(r"(?:^|/)docs/manutencao/([^/]+)/sprint-[^/]+/tasks\.md$")
# o id do contrato expx-revisao, que vira nome de arquivo: nada alem disso
TASK_ID = re.compile(r"^T-(?:\d+|\d{2}\.\d{2})$")
LEITOR = (".expx", "marketplace", "plugins", "expx", "nucleo", "scripts", "expx-fatiamento.mjs")


def modo_revisao(raiz):
    """O `revisao_por_task.modo` que o leitor do nucleo imprime, ou None quando nao da para saber.

    Sem o leitor, sem `node`, com o leitor falhando ou com a linha fora da forma, o modo e
    desconhecido e o hook nao exige a evidencia: o passo 8 do 03-fix ja bloqueia com
    `prerequisito_ausente`, e o aviso aqui seria falso.
    """
    leitor = os.path.join(raiz, *LEITOR)
    if not os.path.isfile(leitor):
        return None
    try:
        import subprocess

        proc = subprocess.run(["node", leitor, "--formato", "env", "--raiz", raiz],
                              capture_output=True, text=True, timeout=3)
    except (OSError, ValueError, subprocess.SubprocessError):
        return None
    if proc.returncode != 0:
        return None
    for linha in proc.stdout.splitlines():
        if linha.startswith("EXPX_REVISAO_POR_TASK="):
            modo = linha.split("=", 1)[1]
            return modo if modo in ("obrigatoria", "se_disponivel", "desligada") else None
    return None


def concluidas_no_disco(caminho_abs):
    """As ids `concluida` no tasks.md de hoje: o antes da escrita. Ausente ou ilegivel, nenhuma."""
    try:
        with open(caminho_abs, "r", encoding="utf-8") as fh:
            texto = fh.read()
    except (OSError, UnicodeDecodeError):
        return set()
    fm = R._parse(bloco_yaml(texto))
    return {t.get("id") for t in R.lista(fm.get("tasks")) if isinstance(t, dict) and t.get("status") == "concluida"}


def tem_evidencia(raiz, trabalho, tid):
    """docs/entregas/<trabalho>/revisao/<tid>.json como arquivo comum: link nao vale."""
    import stat

    try:
        return stat.S_ISREG(os.lstat(os.path.join(raiz, "docs", "entregas", trabalho, "revisao", f"{tid}.json")).st_mode)
    except OSError:
        return False


def conteudo_proposto(evento, caminho_abs):
    """O texto que o arquivo tera depois desta ferramenta.

    Write traz o arquivo inteiro. Edit traz so o trecho, entao aplicamos a
    substituicao sobre o disco para ver o resultado.
    """
    entrada = evento.get("tool_input") or {}
    if isinstance(entrada.get("content"), str):
        return entrada["content"]

    velho, novo = entrada.get("old_string"), entrada.get("new_string")
    if not isinstance(novo, str):
        return None
    try:
        with open(caminho_abs, "r", encoding="utf-8") as fh:
            atual = fh.read()
    except (OSError, UnicodeDecodeError):
        return novo
    if isinstance(velho, str) and velho in atual:
        if entrada.get("replace_all"):
            return atual.replace(velho, novo)
        return atual.replace(velho, novo, 1)
    # `old_string` nao bate com o disco: nao da para reconstruir com honestidade.
    # Devolver o arquivo atual + o trecho novo faria o bloco YAML ser lido do
    # disco velho e a checagem passar por engano. Melhor conferir so o trecho.
    return novo


def bloco_yaml(texto):
    linhas = texto.splitlines()
    if not linhas or linhas[0].strip() != "---":
        return []
    corpo = []
    for linha in linhas[1:]:
        if linha.strip() == "---":
            return corpo
        corpo.append(linha)
    return []


def vazio(valor):
    """True quando o campo nao tem conteudo util.

    Chave escrita sem valor (`teste_integracao:`) chega como None pelo parser,
    e conta como vazia — igual a `null`.
    """
    s = R.texto(valor)
    return not (s and s.strip() and s.strip().lower() != "null")


def main():
    evento = R.ler_evento()
    caminho = R.caminho_da_ferramenta(evento)
    if not caminho:
        sys.exit(0)

    m = ALVO.search(caminho.replace(os.sep, "/"))
    if not m:
        sys.exit(0)

    raiz = R.raiz_repo()
    texto = conteudo_proposto(evento, os.path.join(raiz, caminho))
    if not texto:
        sys.exit(0)

    fm = R._parse(bloco_yaml(texto))
    tasks = [t for t in R.lista(fm.get("tasks")) if isinstance(t, dict)]
    if not tasks:
        sys.exit(0)

    problemas = []
    for t in tasks:
        if t.get("status") != "concluida":
            continue
        tid = t.get("id") or "?"
        faltas = []
        # Regra 9: o E3 roda o subconjunto afetado pela task e grava `parcial`; a
        # suite inteira e exigida uma vez no E4, antes do veredito. Os dois valores
        # significam "o que rodou passou" — o que nao passa e `vermelha` (falhou) e
        # `nao_executada` (ninguem rodou nada).
        if t.get("suite") not in ("verde", "parcial"):
            faltas.append(f"`suite: {t.get('suite')}` (esperado `verde` ou `parcial`)")
        if vazio(t.get("teste_integracao")):
            faltas.append("`teste_integracao` vazio")
        if vazio(t.get("teste_funcional")):
            faltas.append("`teste_funcional` vazio")
        if faltas:
            problemas.append(f"{tid}: " + ", ".join(faltas))

    # A evidencia da revisao por task (desenho de 2026-10-18, 4.2), so na transicao: a task
    # que ESTA escrita leva a `concluida`. Uma edicao de task ja concluida nao a cobra de novo.
    antes = concluidas_no_disco(os.path.join(raiz, caminho))
    novas = [t.get("id") for t in tasks if t.get("status") == "concluida" and t.get("id") not in antes]
    trabalho = R.trabalho_id(os.path.join(raiz, "docs", "manutencao", m.group(1))) if novas else None
    if novas and trabalho and modo_revisao(raiz) == "obrigatoria":
        for tid in novas:
            # id fora da forma nao vira caminho, e a evidencia nao pode ser conferida: avisa
            if not (isinstance(tid, str) and TASK_ID.match(tid)):
                problemas.append(f"{tid or '?'}: id fora da forma T-NN.MM, a evidencia da revisao por task nao pode ser conferida")
            elif not tem_evidencia(raiz, trabalho, tid):
                problemas.append(f"{tid}: sem evidencia da revisao por task (docs/entregas/{trabalho}/revisao/{tid}.json), "
                                 "em modo obrigatoria: rode o passo 8 do 03-fix antes de concluir")

    if not problemas:
        sys.exit(0)

    R.barra_ou_avisa(
        NOME,
        "Task marcada `concluida` sem cumprir a definicao de pronto — "
        + "; ".join(problemas) + ".\n"
        "Toda task tem teste de integracao e teste funcional (regra 4), e a "
        "subconjunto afetado roda antes de concluir e a suite inteira no E4 "
        "(regra 9). Nao existe "
        "\"concluido com ressalva\": ou vira `bloqueada` com registro em "
        "BLOQUEIOS.md, ou fica `em_andamento` ate os testes passarem.",
        trabalho=R.trabalho_id(os.path.join(raiz, "docs", "manutencao", m.group(1))),
        fase="e3", task=problemas[0].split(":")[0], arquivos=[caminho], raiz=raiz,
    )


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:  # hook de metodo falha ABERTA
        sys.exit(0)
