#!/usr/bin/env bash
# Banco de casos dos hooks do runx. Monta uma ocorrencia de mentira em /tmp e
# roda cada hook contra ela, conferindo o codigo de saida esperado.
set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1  # a suíte não deixa .pyc na árvore dos hooks (DR-89)

H="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="$(mktemp -d)"
# $W e um repositorio git de verdade (nao so um diretorio .git vazio): alguns
# hooks precisam de raiz_repo() funcionando de verdade, e a suite de arvore
# limpa precisa de `git status` de verdade. WT e um worktree derivado de $W,
# usado pelo caso que prova o comportamento de raiz_repo() dentro dele.
git -C "$W" init -q -b main
git -C "$W" config user.email "t@t.local"; git -C "$W" config user.name "teste"
printf '.expx/\ndocs/eventos/\n' > "$W/.gitignore"
git -C "$W" add -A -- .gitignore >/dev/null 2>&1 || true
git -C "$W" -c commit.gpgsign=false commit -q -m init --allow-empty >/dev/null 2>&1
WT="${W}--worktree"
git -C "$W" worktree add -q -b fix/OC-2026-0142 "$WT" main >/dev/null 2>&1
trap 'git -C "$W" worktree remove --force "$WT" >/dev/null 2>&1; rm -rf "$W" "$WT"' EXIT
OC="$W/docs/manutencao/OC-2026-0142-calculo-frete"
mkdir -p "$OC/sprint-01" "$OC/base" "$W/src/frete" "$W/docs/relatorios/2026-08-29-OC-2026-0142-calculo-frete"
mkdir -p "$WT/src"

ok=0; falhou=0
caso() { # caso <nome> <esperado> <hook> <json>
  local nome="$1" esperado="$2" hook="$3" json="$4" saida real
  saida=$(printf '%s' "$json" | (cd "$W" && python3 "$hook") 2>&1); real=$?
  if [ "$real" -eq "$esperado" ]; then
    ok=$((ok+1)); printf '  ok   %-46s exit=%s\n' "$nome" "$real"
  else
    falhou=$((falhou+1)); printf '  FALHA %-45s esperado=%s real=%s\n     %s\n' \
      "$nome" "$esperado" "$real" "$(printf '%s' "$saida" | head -3)"
  fi
}
w() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$W/$1" "$2"; }
# caso_py <nome> <cwd> <expressao-esperada> <expressao-python> — compara a saida
# de uma expressao python (biblioteca comum, sem passar por um hook) contra o
# valor esperado, com sys.path apontando para comum/.
caso_py() {
  local nome="$1" cwd="$2" esperado="$3" expr="$4" real esperado_real
  real=$(cd "$cwd" && python3 -c "
import sys; sys.path.insert(0, '$H/comum')
import expx_rastro as R
print($expr)
" 2>&1)
  # raiz_repo() resolve symlink (os.path.realpath); no macOS /var -> /private/var,
  # entao o esperado tambem precisa ser resolvido antes de comparar.
  esperado_real=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$esperado" 2>/dev/null || printf '%s' "$esperado")
  if [ "$real" = "$esperado_real" ]; then
    ok=$((ok+1)); printf '  ok   %-46s => %s\n' "$nome" "$real"
  else
    falhou=$((falhou+1)); printf '  FALHA %-45s esperado=%s real=%s\n' "$nome" "$esperado" "$real"
  fi
}
# script_py <nome> <script-python> — como `caso_py`, mas o script e um bloco
# multi-linha (heredoc) em vez de uma expressao unica; o script IMPRIME
# "True" ou "False" na ultima linha, comparado como string.
script_py() {
  local nome="$1" script="$2" real
  real=$(cd "$W" && python3 -c "
import sys; sys.path.insert(0, '$H/comum')
import expx_rastro as R
$script
" 2>&1)
  if [ "$real" = "True" ]; then
    ok=$((ok+1)); printf '  ok   %-46s => %s\n' "$nome" "$real"
  else
    falhou=$((falhou+1)); printf '  FALHA %-45s esperado=True real=%s\n' "$nome" "$real"
  fi
}

escreve_causa() { cat > "$OC/01-CAUSA-RAIZ.md" <<EOF
---
expx_schema: 1
expx_tool: runx
kind: causa_raiz
trabalho_id: OC-2026-0142
modo: causa_raiz
comprovada: $1
evidencia: teste_falho
arquivos_impactados: [src/frete/calculo.ts]
atualizado_em: 2026-08-29
---
EOF
}
escreve_tasks() { cat > "$OC/sprint-01/tasks.md" <<EOF
---
expx_schema: 1
expx_tool: runx
kind: tasks
trabalho_id: OC-2026-0142
sprint_id: sprint-01
atualizado_em: 2026-08-29
tasks:
  - id: T-01.01
    titulo: Teste de regressao
    fase: F-01.1
    status: em_andamento
    objetivo: Reproduzir
    arquivos:
      cria: [src/frete/calculo.test.ts]
      altera: []
    teste_regressao: $1
    teste_integracao: Chama o endpoint de cotacao
    teste_funcional: Dado 60kg retorna 120
    criterio_aceite: Falha antes e passa depois
    depende_de: []
    paralelizavel: false
    concluida_em: null
    suite: nao_executada
  - id: T-01.02
    titulo: Corrigir
    fase: F-01.1
    status: pendente
    objetivo: Ajustar faixa
    arquivos:
      cria: []
      altera: [src/frete/calculo.ts]
    teste_regressao: null
    teste_integracao: Tabela oficial
    teste_funcional: Dado 50.5kg retorna 110
    criterio_aceite: Faixas batem
    depende_de: [T-01.01]
    paralelizavel: false
    concluida_em: null
    suite: nao_executada
---
EOF
}
cat > "$OC/00-OCORRENCIA.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: ocorrencia
trabalho_id: OC-2026-0142
titulo: Calculo de frete divergente
tipo_ocorrencia: bug
recebido_em: 2026-08-28
origem: ticket-4471
tem_reproducao: true
modulo_afetado: [frete]
---
EOF
cat > "$OC/ORQUESTRADOR.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: orquestrador
trabalho_id: OC-2026-0142
titulo: Calculo de frete divergente
tipo_trabalho: ocorrencia
tipo_ocorrencia: bug
estagio: e3
status: em_andamento
sprints: [sprint-01]
caminho_critico: [F-01.1]
concluido_em: null
---
EOF

echo "== segredo-no-commit (seguranca: nasce em BLOQUEIO) =="
caso "chave AWS barrada"        2 "$H/comum/segredo-no-commit.py" "$(w src/frete/calculo.ts '"const k = \"AKIAQY7RZ3LKMNBVCXZQ\""')"
caso "token github barrado"     2 "$H/comum/segredo-no-commit.py" "$(w src/a.ts '"ghp_A1b2C3d4E5f6G7h8I9j0KlMnOpQrStUvWxYz"')"
caso "placeholder da AWS passa" 0 "$H/comum/segredo-no-commit.py" "$(w src/a.ts '"AKIAIOSFODNN7EXAMPLE"')"
caso "chave privada barrada"    2 "$H/comum/segredo-no-commit.py" "$(w src/a.pem '"-----BEGIN RSA PRIVATE KEY-----\nMIIE"')"
caso "senha em url de banco"    2 "$H/comum/segredo-no-commit.py" "$(w src/db.ts '"postgres://admin:s3nh4Sup3r@10.0.0.1/prod"')"
caso "placeholder passa"        0 "$H/comum/segredo-no-commit.py" "$(w src/a.ts '"const k = \"<SUA_CHAVE_AQUI>\""')"
caso "codigo normal passa"      0 "$H/comum/segredo-no-commit.py" "$(w src/frete/calculo.ts '"export function frete(p){ return p*2 }"')"
caso ".env ignorado"            0 "$H/comum/segredo-no-commit.py" "$(w .env '"AWS=AKIAIOSFODNN7EXAMPLE"')"

echo "== causa-antes-do-plano =="
rm -f "$OC/01-CAUSA-RAIZ.md"
caso "sem causa raiz avisa"     0 "$H/runx/causa-antes-do-plano.py" "$(w docs/manutencao/OC-2026-0142-calculo-frete/sprint-01/tasks.md '"x"')"
escreve_causa false
caso "causa nao comprovada"     0 "$H/runx/causa-antes-do-plano.py" "$(w docs/manutencao/OC-2026-0142-calculo-frete/sprint-01/tasks.md '"x"')"
escreve_causa true
caso "causa comprovada passa"   0 "$H/runx/causa-antes-do-plano.py" "$(w docs/manutencao/OC-2026-0142-calculo-frete/sprint-01/tasks.md '"x"')"
caso "fora de sprint passa"     0 "$H/runx/causa-antes-do-plano.py" "$(w src/frete/calculo.ts '"x"')"

echo "== causa-antes-do-plano em modo bloqueio =="
mkdir -p "$W/.expx"; echo '{"hooks":{"causa-antes-do-plano":"bloqueio"}}' > "$W/.expx/hooks.json"
escreve_causa false
caso "bloqueio barra mesmo"     2 "$H/runx/causa-antes-do-plano.py" "$(w docs/manutencao/OC-2026-0142-calculo-frete/sprint-01/tasks.md '"x"')"
rm -f "$W/.expx/hooks.json"
escreve_causa true

echo "== regressao-antes-do-fix =="
escreve_tasks "null"
caso "producao sem regressao"   0 "$H/runx/regressao-antes-do-fix.py" "$(w src/frete/calculo.ts '"fix"')"
caso "teste sempre passa"       0 "$H/runx/regressao-antes-do-fix.py" "$(w src/frete/calculo.test.ts '"teste"')"
caso "markdown passa"           0 "$H/runx/regressao-antes-do-fix.py" "$(w README.md '"doc"')"
escreve_tasks "Pedido de 60kg cobra 120 e hoje cobra 90"
caso "com regressao passa"      0 "$H/runx/regressao-antes-do-fix.py" "$(w src/frete/calculo.ts '"fix"')"
echo '{"hooks":{"regressao-antes-do-fix":"bloqueio"}}' > "$W/.expx/hooks.json" 2>/dev/null || mkdir -p "$W/.expx" && echo '{"hooks":{"regressao-antes-do-fix":"bloqueio"}}' > "$W/.expx/hooks.json"
escreve_tasks "null"
caso "bloqueio barra producao"  2 "$H/runx/regressao-antes-do-fix.py" "$(w src/frete/calculo.ts '"fix"')"
rm -f "$W/.expx/hooks.json"; escreve_tasks "Pedido de 60kg cobra 120"

echo "== task-so-fecha-verde =="
T="docs/manutencao/OC-2026-0142-calculo-frete/sprint-01/tasks.md"
mk() { python3 - "$1" "$2" "$3" <<'PY'
import json,sys
st,su,ti=sys.argv[1],sys.argv[2],sys.argv[3]
c=f"""---
kind: tasks
trabalho_id: OC-2026-0142
tasks:
  - id: T-01.01
    status: {st}
    teste_integracao: {ti}
    teste_funcional: Dado 60kg retorna 120
    suite: {su}
---
"""
print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[4] if len(sys.argv)>4 else "","content":c}}))
PY
}
J=$(mk concluida verde "Chama endpoint" ); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "concluida verde passa"    0 "$H/runx/task-so-fecha-verde.py" "$J"
J=$(mk concluida vermelha "Chama endpoint"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "concluida vermelha avisa" 0 "$H/runx/task-so-fecha-verde.py" "$J"
J=$(mk concluida verde "null"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "sem teste_integracao"     0 "$H/runx/task-so-fecha-verde.py" "$J"
J=$(mk em_andamento nao_executada "Chama endpoint"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "em_andamento passa"       0 "$H/runx/task-so-fecha-verde.py" "$J"
mkdir -p "$W/.expx"; echo '{"hooks":{"task-so-fecha-verde":"bloqueio"}}' > "$W/.expx/hooks.json"
J=$(mk concluida vermelha "Chama endpoint"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "bloqueio barra vermelha"  2 "$H/runx/task-so-fecha-verde.py" "$J"
# Regra 9 nova: o E3 roda o subconjunto afetado e grava `suite: parcial`; a suite
# inteira e exigida uma vez no E4. Em modo BLOQUEIO — onde vermelha barra — parcial
# tem que passar, senao o hook barraria toda conclusao de task.
J=$(mk concluida parcial "Chama endpoint"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "bloqueio aceita parcial"  0 "$H/runx/task-so-fecha-verde.py" "$J"
J=$(mk concluida nao_executada "Chama endpoint"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "bloqueio barra nao_executada" 2 "$H/runx/task-so-fecha-verde.py" "$J"
# parcial nao dispensa os dois testes: a regra 4 continua valendo.
J=$(mk concluida parcial "null"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
caso "parcial sem teste barra"  2 "$H/runx/task-so-fecha-verde.py" "$J"
rm -f "$W/.expx/hooks.json"
# A evidencia da revisao por task (desenho de 2026-10-18, 4.2): em `obrigatoria`, a task que ESTA
# escrita leva a `concluida` precisa de docs/entregas/<OC-ID>/revisao/<T>.json, arquivo comum. O
# modo vem do leitor do nucleo; sem ele, ou com ele falhando, o hook nao exige (o E3 ja bloqueia).
EN="$W/.expx/marketplace/plugins/expx/nucleo/scripts"; EV="$W/docs/entregas/OC-2026-0142/revisao"
leitor() { rm -rf "$EN"; [ "$1" = nenhum ] && return 0; mkdir -p "$EN"
  if [ "$1" = falha ]; then printf 'process.exit(1);\n' > "$EN/expx-fatiamento.mjs"
  else printf 'process.stdout.write("EXPX_ENTREGA=sprint\\nEXPX_REVISAO_POR_TASK=%s\\n");\n' "$1" > "$EN/expx-fatiamento.mjs"; fi; }
evid() { rm -rf "$W/docs/entregas"; case "$1" in
  arquivo) mkdir -p "$EV"; printf '{}' > "$EV/T-01.01.json" ;;
  link) mkdir -p "$EV"; printf '{}' > "$W/alvo.json"; ln -s ../../../../alvo.json "$EV/T-01.01.json" ;; esac; }
caso_aviso() { # caso_aviso <nome> <0|1: espera o aviso da evidencia> <json>
  local saida; saida=$(printf '%s' "$3" | (cd "$W" && python3 "$H/runx/task-so-fecha-verde.py") 2>&1)
  case "$saida" in *"evidencia da revisao por task"*) r=1 ;; *) r=0 ;; esac
  if [ "$r" = "$2" ]; then ok=$((ok+1)); printf '  ok   %-46s aviso=%s\n' "$1" "$r"
  else falhou=$((falhou+1)); printf '  FALHA %-45s esperado=%s real=%s\n     %s\n' "$1" "$2" "$r" "$(printf '%s' "$saida" | head -3)"; fi
}
J=$(mk concluida verde "Chama endpoint"); J=${J/\"file_path\": \"\"/\"file_path\": \"$W/$T\"}
escreve_tasks "Pedido de 60kg cobra 120"
leitor obrigatoria; evid nenhuma
caso_aviso "evidencia: obrigatoria sem ela avisa"      1 "$J"
evid arquivo; caso_aviso "evidencia: arquivo comum silencia"   0 "$J"
evid link;    caso_aviso "evidencia: link nao vale"            1 "$J"
evid nenhuma
leitor se_disponivel; caso_aviso "evidencia: se_disponivel nao exige" 0 "$J"
leitor falha;   caso_aviso "evidencia: leitor falhando nao exige"   0 "$J"
leitor nenhum;  caso_aviso "evidencia: sem leitor nao exige"        0 "$J"
leitor obrigatoria
# so a transicao: a task ja concluida no disco nao e cobrada de novo
sed -i.bak 's/^    status: em_andamento$/    status: concluida/' "$OC/sprint-01/tasks.md"
caso_aviso "evidencia: ja concluida no disco nao exige" 0 "$J"
escreve_tasks "Pedido de 60kg cobra 120"
mkdir -p "$W/.expx"; echo '{"hooks":{"task-so-fecha-verde":"bloqueio"}}' > "$W/.expx/hooks.json"
caso "evidencia: modo bloqueio barra"        2 "$H/runx/task-so-fecha-verde.py" "$J"
evid arquivo
caso "evidencia: bloqueio com ela passa"     0 "$H/runx/task-so-fecha-verde.py" "$J"
# id fora da forma (ou ausente): a evidencia nao pode ser conferida, e isso avisa (CodeAnt/CodeRabbit no runx#20)
rm -f "$W/.expx/hooks.json"; evid nenhuma
JM=${J/\"id\": \"T-01.01\"/\"id\": \"T-1.1\"}; JM=${J//T-01.01/T-1.1}
caso_aviso "evidencia: id fora da forma avisa"     1 "$JM"
rm -f "$W/.expx/hooks.json" "$OC/sprint-01/tasks.md.bak" "$W/alvo.json"; evid nenhuma; leitor nenhum

echo "== task-reivindicada =="
# trabalho_id() le 01-CAUSA-RAIZ.md/tasks.md, ja gravados nesta fixture pelas
# secoes anteriores (escreve_causa/escreve_tasks) com trabalho_id: OC-2026-0142
# explicito — e por isso, nao pelo nome da pasta, que o rastro tem esse nome.
RASTRO="$W/docs/eventos/OC-2026-0142.jsonl"
mkdir -p "$(dirname "$RASTRO")"
mk_em_andamento() { # mk_em_andamento <sessao no json, para o campo tool_input.session_id, ou omita>
  python3 - "$1" <<'PY'
import json, sys
sid = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] != "-" else None
c = """---
kind: tasks
trabalho_id: OC-2026-0142
tasks:
  - id: T-01.01
    status: em_andamento
    teste_integracao: Chama endpoint
    teste_funcional: Dado 60kg retorna 120
    suite: nao_executada
---
"""
entrada = {"file_path": "PLACEHOLDER", "content": c}
evento = {"tool_name": "Write", "tool_input": entrada}
if sid:
    evento["session_id"] = sid
print(json.dumps(evento))
PY
}
grava_evento() { # grava_evento <evento> <sessao|->
  python3 -c "
import json, sys
sys.path.insert(0, '$H/comum')
import expx_rastro as R
kw = {}
if sys.argv[2] != '-':
    kw['sessao_id'] = sys.argv[2]
R.grava(sys.argv[1], trabalho='OC-2026-0142', task='T-01.01', fase='e3', raiz='$W', **kw)
" "$1" "$2"
}
: > "$RASTRO"
J=$(mk_em_andamento -); J=${J/\"file_path\": \"PLACEHOLDER\"/\"file_path\": \"$W/$T\"}
caso "sem rastro nunca avisa"          0 "$H/runx/task-reivindicada.py" "$J"

: > "$RASTRO"; grava_evento task_iniciada "opencode@abc"
J=$(mk_em_andamento -); J=${J/\"file_path\": \"PLACEHOLDER\"/\"file_path\": \"$W/$T\"}
caso "reivindicada por outra sessao avisa" 0 "$H/runx/task-reivindicada.py" "$J"

: > "$RASTRO"; grava_evento task_iniciada "opencode@abc"
J=$(mk_em_andamento "opencode@abc"); J=${J/\"file_path\": \"PLACEHOLDER\"/\"file_path\": \"$W/$T\"}
caso "mesma sessao nao avisa"          0 "$H/runx/task-reivindicada.py" "$J"

: > "$RASTRO"; grava_evento task_iniciada "opencode@abc"; grava_evento task_concluida "opencode@abc"
J=$(mk_em_andamento "claude-code@xyz"); J=${J/\"file_path\": \"PLACEHOLDER\"/\"file_path\": \"$W/$T\"}
caso "fechada por task_concluida nao avisa" 0 "$H/runx/task-reivindicada.py" "$J"

: > "$RASTRO"
python3 -c "
import json
linha = {'ts':'2026-08-29T00:00:00Z','expx_eventos':1,'trabalho_id':'OC-2026-0142','ferramenta':'runx','origem':'hook','evento':'task_iniciada','fase':'e3','task':'T-01.01','agente':'principal','resultado':'ok','detalhe':None,'arquivos':[]}
open('$RASTRO','a').write(json.dumps(linha)+'\n')
"
J=$(mk_em_andamento "claude-code@xyz"); J=${J/\"file_path\": \"PLACEHOLDER\"/\"file_path\": \"$W/$T\"}
caso "rastro sem sessao (legado) nunca avisa" 0 "$H/runx/task-reivindicada.py" "$J"

: > "$RASTRO"; grava_evento task_iniciada "opencode@abc"
mkdir -p "$W/.expx"; echo '{"hooks":{"task-reivindicada":"bloqueio"}}' > "$W/.expx/hooks.json"
J=$(mk_em_andamento -); J=${J/\"file_path\": \"PLACEHOLDER\"/\"file_path\": \"$W/$T\"}
caso "bloqueio barra reivindicada"     2 "$H/runx/task-reivindicada.py" "$J"
mv "$RASTRO" "${RASTRO%.jsonl}.1.jsonl"
grava_evento suite_executada "opencode@abc"
J=$(mk_em_andamento "claude-code@xyz"); J=${J/\"file_path\": \"PLACEHOLDER\"/\"file_path\": \"$W/$T\"}
caso "reivindicacao sobrevive rotacao e evento neutro" 2 "$H/runx/task-reivindicada.py" "$J"
rm -f "${RASTRO%.jsonl}.1.jsonl"

rm -f "$W/.expx/hooks.json"
: > "$RASTRO"

echo "== escopo-da-ocorrencia =="
escreve_tasks "Pedido de 60kg cobra 120"
caso "arquivo no escopo passa"  0 "$H/runx/escopo-da-ocorrencia.py" "$(w src/frete/calculo.ts '"x"')"
caso "teste no escopo passa"    0 "$H/runx/escopo-da-ocorrencia.py" "$(w src/frete/calculo.test.ts '"x"')"
caso "fora do escopo avisa"     0 "$H/runx/escopo-da-ocorrencia.py" "$(w src/pedido/outro.ts '"refactor de brinde"')"
caso "docs/manutencao livre"    0 "$H/runx/escopo-da-ocorrencia.py" "$(w docs/manutencao/OC-2026-0142-calculo-frete/QA.md '"x"')"
mkdir -p "$W/.expx"; echo '{"hooks":{"escopo-da-ocorrencia":"bloqueio"}}' > "$W/.expx/hooks.json"
caso "bloqueio barra fora"      2 "$H/runx/escopo-da-ocorrencia.py" "$(w src/pedido/outro.ts '"x"')"
rm -f "$W/.expx/hooks.json"

echo "== uma-ocorrencia-por-arvore =="
OC2="$W/docs/manutencao/OC-2026-0200-outra-ocorrencia"
mkdir -p "$OC2"
cat > "$OC2/00-OCORRENCIA.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: ocorrencia
trabalho_id: OC-2026-0200
titulo: Outra ocorrencia aberta
tipo_ocorrencia: bug
recebido_em: 2026-08-29
tem_reproducao: true
modulo_afetado: []
worktree: null
---
EOF
caso "outra ocorrencia aberta avisa" 0 "$H/runx/uma-ocorrencia-por-arvore.py" \
  "$(w docs/manutencao/OC-2026-0300-terceira/00-OCORRENCIA.md '"---\nkind: ocorrencia\ntrabalho_id: OC-2026-0300\n---\n"')"
caso "escrever na propria ocorrencia passa" 0 "$H/runx/uma-ocorrencia-por-arvore.py" \
  "$(w docs/manutencao/OC-2026-0200-outra-ocorrencia/00-OCORRENCIA.md '"---\nkind: ocorrencia\ntrabalho_id: OC-2026-0200\n---\n"')"
cat > "$OC2/ORQUESTRADOR.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: orquestrador
trabalho_id: OC-2026-0200
estagio: e5
status: concluido
concluido_em: 2026-08-30
sprints: [sprint-01]
caminho_critico: [F-01.1]
---
EOF
caso "ocorrencia encerrada nao conta" 0 "$H/runx/uma-ocorrencia-por-arvore.py" \
  "$(w docs/manutencao/OC-2026-0300-terceira/00-OCORRENCIA.md '"---\nkind: ocorrencia\ntrabalho_id: OC-2026-0300\n---\n"')"
sed -i.bak 's/^status: concluido$/status: em_andamento/; s/^concluido_em: .*/concluido_em: null/' "$OC2/ORQUESTRADOR.md"; rm -f "$OC2/ORQUESTRADOR.md.bak"
mkdir -p "$W/.expx"; echo '{"hooks":{"uma-ocorrencia-por-arvore":"bloqueio"}}' > "$W/.expx/hooks.json"
caso "bloqueio barra outra aberta"    2 "$H/runx/uma-ocorrencia-por-arvore.py" \
  "$(w docs/manutencao/OC-2026-0300-terceira/00-OCORRENCIA.md '"---\nkind: ocorrencia\ntrabalho_id: OC-2026-0300\n---\n"')"
rm -f "$W/.expx/hooks.json"
rm -rf "$OC2"

echo "== sem-jargao-no-uso (PostToolUse) =="
U="docs/relatorios/2026-08-29-OC-2026-0142-calculo-frete/uso.md"
p() { printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$W/$U"; }
cat > "$W/$U" <<'EOF'
---
kind: relatorio_uso
trabalho_id: OC-2026-0142
---
# O que mudou
O valor do frete para encomendas acima de 50 quilos estava sendo cobrado a menos.
Agora o valor cobrado confere com a tabela combinada. Nao e preciso fazer nada.
EOF
caso "uso limpo passa"          0 "$H/runx/sem-jargao-no-uso.py" "$(p)"
cat > "$W/$U" <<'EOF'
---
kind: relatorio_uso
---
# O que mudou
Corrigimos a funcao calcularFrete() em src/frete/calculo.ts, que fazia um SELECT
na tabela de faixas com arredondamento errado.
EOF
# Em modo aviso o hook registra e NAO interrompe (exit 0); so em bloqueio ele
# devolve o texto ao modelo para reescrita (exit 2).
caso "uso com jargao: aviso nao trava" 0 "$H/runx/sem-jargao-no-uso.py" "$(p)"
mkdir -p "$W/.expx"; echo '{"hooks":{"sem-jargao-no-uso":"bloqueio"}}' > "$W/.expx/hooks.json"
caso "uso com jargao: bloqueio devolve" 2 "$H/runx/sem-jargao-no-uso.py" "$(p)"
rm -f "$W/.expx/hooks.json"
mkdir -p "$W/.expx"; echo '{"hooks":{"sem-jargao-no-uso":"desligado"}}' > "$W/.expx/hooks.json"
caso "desligado passa"          0 "$H/runx/sem-jargao-no-uso.py" "$(p)"
rm -f "$W/.expx/hooks.json"

echo "== rastro =="
caso "rastro-arquivo grava"     0 "$H/comum/rastro-arquivo.py" "$(w src/frete/calculo.ts '"x"')"
caso "rastro-suite verde"       0 "$H/comum/rastro-suite.py" '{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"exit_code":0}}'
caso "rastro-suite vermelha"    0 "$H/comum/rastro-suite.py" '{"tool_name":"Bash","tool_input":{"command":"npx vitest run"},"tool_response":{"exit_code":1}}'
caso "comando comum ignorado"   0 "$H/comum/rastro-suite.py" '{"tool_name":"Bash","tool_input":{"command":"ls -la"},"tool_response":{"exit_code":0}}'
script_py "rastro-suite grava HEAD e sujos_fora_escopo" '
import subprocess, json
subprocess.run(["python3", "'"$H"'/comum/rastro-suite.py"],
                input=json.dumps({"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"exit_code":0}}),
                text=True, cwd="'"$W"'")
linhas = open("'"$W"'/docs/eventos/OC-2026-0142.jsonl").readlines()
d = json.loads(linhas[-1])
print("@" in d["detalhe"] and "sujos_fora_escopo=" in d["detalhe"])
'

echo "== identidade de sessao (sessoes paralelas) =="

script_py "sessao-por-env" '
import os
for k in ("EXPX_SESSAO", "EXPX_HARNESS", "CLAUDECODE", "CLAUDE_CODE_SESSION_ID"):
    os.environ.pop(k, None)
os.environ["EXPX_SESSAO"] = "opencode@abc"
print(R.sessao() == "opencode@abc")
'

script_py "sessao-por-payload" '
import os
for k in ("EXPX_SESSAO", "CLAUDECODE", "CLAUDE_CODE_SESSION_ID"):
    os.environ.pop(k, None)
os.environ["EXPX_HARNESS"] = "mimocode"
print(R.sessao({"session_id": "xyz"}) == "mimocode@xyz")
'

script_py "sessao-por-ancestral" '
import os
from unittest import mock
for k in ("EXPX_SESSAO", "EXPX_HARNESS", "CLAUDECODE", "CLAUDE_CODE_SESSION_ID"):
    os.environ.pop(k, None)
with mock.patch.object(R, "_ancestral_harness_pid", return_value=(None, None)):
    print(R.sessao() == "desconhecido@sem-id")
'

script_py "extras-depois-das-doze" '
import os, json
os.environ["EXPX_SESSAO"] = "claude-code@teste"
os.environ["EXPX_HARNESS"] = "claude-code"
R.grava("arquivo_alterado", trabalho="OC-TESTE-EXTRAS", arquivos=["a.ts"], raiz="'"$W"'")
linha = open("'"$W"'/docs/eventos/OC-TESTE-EXTRAS.jsonl").readlines()[-1]
d = json.loads(linha)
chaves = list(d.keys())
doze = chaves[:12] == ["ts","expx_eventos","trabalho_id","ferramenta","origem","evento",
                        "fase","task","agente","resultado","detalhe","arquivos"]
extras = chaves[12:14] == ["sessao", "harness"]
print(doze and extras and d["sessao"] == "claude-code@teste" and d["harness"] == "claude-code")
'

echo "== arvore-limpa-antes-da-suite =="
SETA_REL='src/pedido/nome -> final.py'
mkdir -p "$W/src/pedido"; touch "$W/$SETA_REL"
script_py "git-status-preserva-seta-literal" '
print(any(caminho == "src/pedido/nome -> final.py" for _status, caminho in R.status_git("'"$W"'")))
'
rm -f "$W/$SETA_REL"

# Precisa de escopo declarado (causa raiz com arquivos_impactados) e de um
# arquivo de verdade sujo no git para $W, que ja e repositorio real. Limpeza
# cirurgica dos arquivos desta secao apenas — nunca `git clean -fdx`, que
# apagaria docs/manutencao/ inteiro e quebraria as secoes seguintes do script.
escreve_causa true; escreve_tasks "Pedido de 60kg cobra 120"
bash_ev() { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
limpa_sujeira() { rm -rf "$W/src/pedido" "$W/tests" "$W/src/frete/calculo.ts"; }
limpa_sujeira
touch "$W/src/frete/calculo.ts"  # no escopo (arquivos_impactados)
caso "sujo no escopo nao avisa"   0 "$H/runx/arvore-limpa-antes-da-suite.py" "$(bash_ev 'npm test')"
limpa_sujeira
mkdir -p "$W/src/pedido"; touch "$W/src/pedido/fora.ts"  # fora do escopo
caso "sujo fora do escopo avisa" 0 "$H/runx/arvore-limpa-antes-da-suite.py" "$(bash_ev 'npm test')"
limpa_sujeira
mkdir -p "$W/tests"; touch "$W/tests/frete_test.py"  # teste, sempre livre
caso "sujo de teste nao avisa"    0 "$H/runx/arvore-limpa-antes-da-suite.py" "$(bash_ev 'npm test')"
limpa_sujeira
caso "comando comum nao dispara"  0 "$H/runx/arvore-limpa-antes-da-suite.py" "$(bash_ev 'ls -la')"
mkdir -p "$W/src/pedido"; touch "$W/src/pedido/fora.ts"
mkdir -p "$W/.expx"; echo '{"hooks":{"arvore-limpa-antes-da-suite":"bloqueio"}}' > "$W/.expx/hooks.json"
caso "bloqueio barra sujo fora"   2 "$H/runx/arvore-limpa-antes-da-suite.py" "$(bash_ev 'npm test')"
limpa_sujeira
# git status da caminho relativo a raiz: `outro/src/frete/calculo.ts` nao e o
# `src/frete/calculo.ts` autorizado so por terminar igual (CodeAnt, conselhos#208)
mkdir -p "$W/outro/src/frete"; touch "$W/outro/src/frete/calculo.ts"
caso "sufixo de caminho nao autoriza"   2 "$H/runx/arvore-limpa-antes-da-suite.py" "$(bash_ev 'npm test')"
rm -rf "$W/outro"
touch "$W/src/frete/calculo.ts"
caso "caminho igual segue autorizado"   0 "$H/runx/arvore-limpa-antes-da-suite.py" "$(bash_ev 'npm test')"
rm -f "$W/.expx/hooks.json"
limpa_sujeira
SEMGIT="$(mktemp -d)"
saida=$(printf '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' | (cd "$SEMGIT" && python3 "$H/runx/arvore-limpa-antes-da-suite.py") 2>&1); real=$?
if [ "$real" -eq 0 ]; then ok=$((ok+1)); printf '  ok   %-46s exit=%s\n' "sem git nunca avisa" "$real"
else falhou=$((falhou+1)); printf '  FALHA %-45s esperado=0 real=%s\n     %s\n' "sem git nunca avisa" "$real" "$saida"; fi
rm -rf "$SEMGIT"

echo "== frontmatter: lista inline com aspas e trabalho_id inseguro =="
script_py "lista-inline-aspas-com-virgula" '
print(R._valor("[\"src/a,b.ts\", c.ts, '"'"'d,e.py'"'"']") == ["src/a,b.ts", "c.ts", "d,e.py"])
'
script_py "lista-inline-sem-aspas-inalterada" '
print(R._valor("[a, b, 3]") == ["a", "b", 3] and R._valor("[]") == [])
'
INSEG="$(mktemp -d)"
mkdir -p "$INSEG/repo/docs/manutencao/OC-9-x"
printf -- '---\nkind: ocorrencia\ntrabalho_id: ../../../fora\n---\n' > "$INSEG/repo/docs/manutencao/OC-9-x/00-OCORRENCIA.md"
script_py "trabalho-id-com-ponto-ponto-cai-no-nome-da-pasta" '
print(R.trabalho_id("'"$INSEG"'/repo/docs/manutencao/OC-9-x") == "OC-9-x")
'
script_py "grava-recusa-trabalho-fora-de-docs-eventos" '
import os
for t in ("../../../fora", "'"$INSEG"'/abs", "a/b"):
    R.grava("teste", trabalho=t, raiz="'"$INSEG"'/repo")
print(not os.path.exists("'"$INSEG"'/fora.jsonl") and not os.path.exists("'"$INSEG"'/abs.jsonl")
      and not os.path.exists("'"$INSEG"'/repo/docs/eventos/a") and R.caminhos_rastro("'"$INSEG"'/repo", "../x") == [])
'
rm -rf "$INSEG"

echo "== raiz_repo em worktree =="
# .git dentro de um worktree e ARQUIVO (gitdir: <principal>/.git/worktrees/<nome>),
# nao diretorio. raiz_repo() hoje so testa os.path.isdir(".git") e, chamada de um
# subdiretorio do worktree, cai no fallback (devolve o proprio subdiretorio).
caso_py "raiz-em-worktree" "$WT/src" "$WT" "R.raiz_repo()"

echo "== pasta_ocorrencia pela branch =="
# Numa worktree nova de OC, antes do 00-OCORRENCIA.md dela, a escolha por mtime
# caia na ocorrencia FECHADA mais recente e o rastro ia para ela (conselhos,
# OC-2026-0007 e 0009 gravaram em OC-2026-0006.jsonl). A branch decide antes.
PB="$(mktemp -d)"
nova_oc() { # nova_oc <raiz> <pasta> <id> <arquivo> <status>
  mkdir -p "$1/docs/manutencao/$2"
  printf -- '---\nexpx_tool: runx\nkind: x\ntrabalho_id: %s\nstatus: %s\n---\n' "$3" "$5" > "$1/docs/manutencao/$2/$4"
}
repo_na_branch() { # repo_na_branch <dir> <branch>
  git init -q "$1" && git -C "$1" symbolic-ref HEAD "refs/heads/$2"
  nova_oc "$1" OC-2026-0005-z OC-2026-0005 ORQUESTRADOR.md concluido
  nova_oc "$1" OC-2026-0006-fechada OC-2026-0006 ORQUESTRADOR.md concluido
}
caso_valor() { # caso_valor <nome> <cwd> <esperado> <expressao-python> — compara texto, sem realpath
  local real
  real=$(cd "$2" && python3 -c "
import sys; sys.path.insert(0, '$H/comum')
import expx_rastro as R
print($4)
" 2>&1)
  if [ "$real" = "$3" ]; then ok=$((ok+1)); printf '  ok   %-46s => %s\n' "$1" "$real"
  else falhou=$((falhou+1)); printf '  FALHA %-45s esperado=%s real=%s\n' "$1" "$3" "$real"; fi
}
repo_na_branch "$PB/a" fix/OC-2026-0007-nova
caso_valor "branch-de-oc-sem-pasta-nao-cai-na-fechada" "$PB/a" "None" "R.pasta_ocorrencia()"
nova_oc "$PB/a" OC-2026-0007-nova OC-2026-0007 00-OCORRENCIA.md em_andamento
caso_valor "branch-de-oc-acha-a-pasta-no-e1" "$PB/a" "OC-2026-0007" "R.trabalho_id(R.pasta_ocorrencia())"
repo_na_branch "$PB/b" fix/OC-2026-0007-outro-slug
nova_oc "$PB/b" OC-2026-0007-nova OC-2026-0007 ORQUESTRADOR.md em_andamento
caso_valor "branch-de-oc-acha-pelo-id-com-outro-slug" "$PB/b" "OC-2026-0007" "R.trabalho_id(R.pasta_ocorrencia())"
repo_na_branch "$PB/c" chore/OC-2026-0006-fechada
nova_oc "$PB/c" OC-2026-0008-aberta OC-2026-0008 ORQUESTRADOR.md em_andamento
caso_valor "branch-da-fechada-cede-a-aberta-com-orquestrador" "$PB/c" "OC-2026-0008" "R.trabalho_id(R.pasta_ocorrencia())"
repo_na_branch "$PB/d" main
nova_oc "$PB/d" OC-2026-0008-aberta OC-2026-0008 ORQUESTRADOR.md em_andamento
caso_valor "fora-de-branch-de-oc-a-aberta-vence" "$PB/d" "OC-2026-0008" "R.trabalho_id(R.pasta_ocorrencia())"
repo_na_branch "$PB/e" feature/OC-2026-0006-fechada
nova_oc "$PB/e" OC-2026-0008-aberta OC-2026-0008 ORQUESTRADOR.md em_andamento
caso_valor "branch-nao-oc-com-nome-da-fechada-nao-decide" "$PB/e" "OC-2026-0008" "R.trabalho_id(R.pasta_ocorrencia())"
# Ocorrencia nova aberta sem worktree, numa branch de outra ocorrencia (com ou sem a pasta
# dela, fechada): a aberta vence; a fechada da branch so vale sem nenhuma aberta (E5 dela).
repo_na_branch "$PB/g" fix/OC-2026-0006-fechada
nova_oc "$PB/g" OC-2026-0009-sem-worktree OC-2026-0009 00-OCORRENCIA.md em_andamento
caso_valor "branch-de-oc-fechada-cede-a-aberta" "$PB/g" "OC-2026-0009" "R.trabalho_id(R.pasta_ocorrencia())"
repo_na_branch "$PB/h" fix/OC-2026-0004-sem-pasta
nova_oc "$PB/h" OC-2026-0009-sem-worktree OC-2026-0009 00-OCORRENCIA.md em_andamento
caso_valor "branch-de-oc-sem-pasta-acha-a-aberta" "$PB/h" "OC-2026-0009" "R.trabalho_id(R.pasta_ocorrencia())"
repo_na_branch "$PB/i" fix/OC-2026-0006-fechada
caso_valor "branch-de-oc-fechada-sem-aberta-e-ela" "$PB/i" "OC-2026-0006" "R.trabalho_id(R.pasta_ocorrencia())"
# A pasta pelo nome ou pelo OC-ID so vale se o trabalho_id dela e o da branch.
repo_na_branch "$PB/j" fix/OC-2026-0007-nova
nova_oc "$PB/j" OC-2026-0007-nova OC-2026-0008 00-OCORRENCIA.md em_andamento
caso_valor "pasta-da-branch-com-outro-id-nao-vale" "$PB/j" "None" "R.pasta_ocorrencia()"
nova_oc "$PB/j" OC-2026-0007-outra OC-2026-0007 00-OCORRENCIA.md em_andamento
caso_valor "pasta-da-branch-com-outro-id-nao-cede-a-outra-do-oc" "$PB/j" "None" "R.pasta_ocorrencia()"
repo_na_branch "$PB/k" fix/OC-2026-0007-sem-pasta
nova_oc "$PB/k" OC-2026-0007-a OC-2026-0007 00-OCORRENCIA.md em_andamento
nova_oc "$PB/k" OC-2026-0007-b OC-2026-0008 00-OCORRENCIA.md em_andamento
caso_valor "pastas-do-oc-que-se-contradizem-nao-decidem" "$PB/k" "None" "R.pasta_ocorrencia()"
# A aberta que veio da main (commitada, de outro trabalho) nao e a desta worktree: so a criada
# nesta arvore, ainda fora do HEAD, vale sem a pasta da branch (conselhos#292, OC-0008/0011).
comita() { git -C "$1" add -A && git -C "$1" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -qm base; }
repo_na_branch "$PB/l" fix/OC-2026-0012-nova
nova_oc "$PB/l" OC-2026-0011-aberta-na-main OC-2026-0011 ORQUESTRADOR.md em_andamento
comita "$PB/l"
caso_valor "aberta-commitada-de-outra-oc-nao-recebe-a-nova" "$PB/l" "None" "R.pasta_ocorrencia()"
nova_oc "$PB/l" OC-2026-0013-sem-worktree OC-2026-0013 00-OCORRENCIA.md em_andamento
caso_valor "aberta-criada-nesta-arvore-vale-sem-a-pasta" "$PB/l" "OC-2026-0013" "R.trabalho_id(R.pasta_ocorrencia())"
repo_na_branch "$PB/m" fix/OC-2026-0006-fechada
nova_oc "$PB/m" OC-2026-0011-aberta-na-main OC-2026-0011 ORQUESTRADOR.md em_andamento
comita "$PB/m"
caso_valor "fechada-da-branch-vence-a-aberta-commitada" "$PB/m" "OC-2026-0006" "R.trabalho_id(R.pasta_ocorrencia())"
# Git que falha (GIT_DIR invalido) nao e "sem commit": sem saber de onde a pasta veio, nenhuma.
gq=$(cd "$PB/l" && GIT_DIR="$PB/nao-existe" python3 -c "
import sys; sys.path.insert(0, '$H/comum')
import expx_rastro as R
print(R._fora_do_head(R.raiz_repo(), [p for _, p in R._ocorrencias('docs/manutencao', sorted(__import__('os').listdir('docs/manutencao')))[0]]))
" 2>&1)
if [ "$gq" = "None" ]; then ok=$((ok+1)); printf '  ok   %-46s => %s\n' "git-falhando-nao-escolhe-nenhuma" "$gq"
else falhou=$((falhou+1)); printf '  FALHA %-45s real=%s\n' "git-falhando-nao-escolhe-nenhuma" "$gq"; fi
# Git falhando tambem nao cai na fechada da branch (CodeRabbit no #19): sem saber, nenhuma.
nova_oc "$PB/m" OC-2026-0013-sem-worktree OC-2026-0013 00-OCORRENCIA.md em_andamento
gf=$(cd "$PB/m" && GIT_DIR="$PB/nao-existe" python3 -c "
import sys; sys.path.insert(0, '$H/comum')
import expx_rastro as R
print(R.pasta_ocorrencia())
" 2>&1)
if [ "$gf" = "None" ]; then ok=$((ok+1)); printf '  ok   %-46s => %s\n' "git-falhando-nao-cai-na-fechada-da-branch" "$gf"
else falhou=$((falhou+1)); printf '  FALHA %-45s real=%s\n' "git-falhando-nao-cai-na-fechada-da-branch" "$gf"; fi
# ...nem sem aberta nenhuma: a lista vazia voltava [] sem consultar o Git, e a fechada da branch
# passava (CodeAnt no conselhos#293, expx_rastro.py:514 e 597).
gz=$(cd "$PB/i" && GIT_DIR="$PB/nao-existe" python3 -c "
import sys; sys.path.insert(0, '$H/comum')
import expx_rastro as R
print(R.pasta_ocorrencia())
" 2>&1)
if [ "$gz" = "None" ]; then ok=$((ok+1)); printf '  ok   %-46s => %s\n' "git-falhando-sem-aberta-nao-cai-na-fechada" "$gz"
else falhou=$((falhou+1)); printf '  FALHA %-45s real=%s\n' "git-falhando-sem-aberta-nao-cai-na-fechada" "$gz"; fi
# Branch orfa num repositorio com commits: o rev-parse sai 1, mas nao e "sem commit" (CodeAnt no #19).
repo_na_branch "$PB/n" main
nova_oc "$PB/n" OC-2026-0011-aberta-na-main OC-2026-0011 ORQUESTRADOR.md em_andamento
comita "$PB/n"
git -C "$PB/n" symbolic-ref HEAD refs/heads/fix/OC-2026-0012-orfa
caso_valor "branch-orfa-nao-trata-a-aberta-da-main-como-nova" "$PB/n" "None" "R.pasta_ocorrencia()"
# Worktree vinculada (.git arquivo, gitdir absoluto e relativo) e HEAD destacado.
repo_na_branch "$PB/f" main
git -C "$PB/f" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m i
git -C "$PB/f" worktree add -q -b fix/OC-2026-0007-nova "$PB/f-wt" >/dev/null 2>&1
caso_valor "worktree-gitdir-absoluto" "$PB/f-wt" "fix/OC-2026-0007-nova" "R.branch_atual(R.raiz_repo())"
caso_valor "worktree-de-oc-sem-pasta" "$PB/f-wt" "None" "R.pasta_ocorrencia()"
gd="$(sed -n 's/^gitdir: //p' "$PB/f-wt/.git")"
printf 'gitdir: %s\n' "$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$gd" "$PB/f-wt")" > "$PB/f-wt/.git"
caso_valor "worktree-gitdir-relativo" "$PB/f-wt" "fix/OC-2026-0007-nova" "R.branch_atual(R.raiz_repo())"
git -C "$PB/f" checkout -q --detach
caso_valor "head-destacado-sem-branch" "$PB/f" "None" "R.branch_atual(R.raiz_repo())"
# Sem pasta, o segredo continua barrando, sem traceback e sem gravar na fechada.
seg=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"ghp_A1b2C3d4E5f6G7h8I9j0KlMnOpQrStUvWxYz"}}' "$PB/a/src/a.ts" \
  | (cd "$PB/a" && rm -rf docs/manutencao/OC-2026-0007-nova && python3 "$H/comum/segredo-no-commit.py") 2>&1); seg_rc=$?
if [ "$seg_rc" -eq 2 ] && ! printf '%s' "$seg" | grep -q Traceback && [ ! -e "$PB/a/docs/eventos/OC-2026-0006.jsonl" ]; then
  ok=$((ok+1)); printf '  ok   %-46s exit=%s\n' "segredo-barra-sem-pasta-da-oc" "$seg_rc"
else
  falhou=$((falhou+1)); printf '  FALHA %-45s exit=%s\n     %s\n' "segredo-barra-sem-pasta-da-oc" "$seg_rc" "$(printf '%s' "$seg" | head -3)"
fi
rm -rf "$PB"

echo "== robustez: entrada invalida nunca trava =="
for hk in comum/rastro-arquivo comum/rastro-suite runx/causa-antes-do-plano \
          runx/regressao-antes-do-fix runx/task-so-fecha-verde \
          runx/escopo-da-ocorrencia runx/sem-jargao-no-uso; do
  caso "$(basename $hk) stdin vazio"  0 "$H/$hk.py" ''
  caso "$(basename $hk) json quebrado" 0 "$H/$hk.py" '{nao e json'
done

echo "== despachante: um processo, mesma semantica =="
DESP="$H/comum/despachante.py"
PRE7="comum/segredo-no-commit runx/causa-antes-do-plano runx/regressao-antes-do-fix runx/task-so-fecha-verde runx/escopo-da-ocorrencia runx/uma-ocorrencia-por-arvore runx/task-reivindicada"
dcaso(){ local esp="$1" desc="$2" ev="$3" c
  printf '%s' "$ev" | (cd "$W" && python3 "$DESP" $PRE7) >/dev/null 2>&1; c=$?
  if [ "$c" -eq "$esp" ]; then ok=$((ok+1)); printf '  ok   %-46s exit=%s\n' "$desc" "$c"
  else falhou=$((falhou+1)); printf '  FALHA %-45s esperado=%s real=%s\n' "$desc" "$esp" "$c"; fi; }
escreve_causa true; escreve_tasks "Pedido de 60kg cobra 120"
dcaso 0 "escrita no escopo passa"      "$(w src/frete/calculo.ts '"x"')"
dcaso 2 "segredo barra pelo despachante" "$(w src/frete/calculo.ts '"ghp_A1b2C3d4E5f6G7h8I9j0KlMnOpQrStUvWxYz"')"
dcaso 0 "fora do escopo so avisa"      "$(w src/pedido/outro.ts '"x"')"
mkdir -p "$W/.expx"; echo '{"hooks":{"escopo-da-ocorrencia":"bloqueio"}}' > "$W/.expx/hooks.json"
dcaso 2 "modo bloqueio propaga"        "$(w src/pedido/outro.ts '"x"')"
rm -f "$W/.expx/hooks.json"
dcaso 0 "stdin vazio"                  ''
dcaso 0 "json quebrado"                '{quebrado'

echo "== despachante: grupo PreToolUse/Bash com o hook novo =="
dcaso_bash(){ local esp="$1" desc="$2" ev="$3" c
  printf '%s' "$ev" | (cd "$W" && python3 "$DESP" runx/arvore-limpa-antes-da-suite) >/dev/null 2>&1; c=$?
  if [ "$c" -eq "$esp" ]; then ok=$((ok+1)); printf '  ok   %-46s exit=%s\n' "$desc" "$c"
  else falhou=$((falhou+1)); printf '  FALHA %-45s esperado=%s real=%s\n' "$desc" "$esp" "$c"; fi; }
dcaso_bash 0 "comando de suite via despachante passa" '{"tool_name":"Bash","tool_input":{"command":"npm test"}}'

echo "== hooks.json e hooks.exemplo.json validos, doctor lista nove hooks =="
script_py "hooks.json e json valido" '
import json
print(bool(json.load(open("'"$H"'/hooks.json"))))
'
script_py "hooks.exemplo.json e json valido" '
import json
print(bool(json.load(open("'"$H"'/hooks.exemplo.json"))))
'
script_py "hooks.json tem o grupo PreToolUse/Bash" '
import json
d = json.load(open("'"$H"'/hooks.json"))
print(any(g.get("matcher") == "Bash" for g in d["hooks"]["PreToolUse"]))
'
script_py "doctor.py lista nove hooks" '
import subprocess, re
r = subprocess.run(["python3", "'"$H"'/comum/doctor.py"], capture_output=True, text=True, cwd="'"$W"'")
nomes = {"segredo-no-commit","causa-antes-do-plano","regressao-antes-do-fix","task-so-fecha-verde","escopo-da-ocorrencia","sem-jargao-no-uso","uma-ocorrencia-por-arvore","task-reivindicada","arvore-limpa-antes-da-suite"}
# so a linha da TABELA (nome seguido de espacos e depois "seguranca"/"metodo")
achados = {m.group(1) for l in r.stdout.splitlines()
           if (m := re.match(r"\s*([a-z-]+)\s+(seguranca|metodo)\s", l))}
print(achados == nomes)
'

echo
echo "== rastro gravado =="
if [ -f "$W/docs/eventos/OC-2026-0142.jsonl" ]; then
  python3 - "$W/docs/eventos/OC-2026-0142.jsonl" <<'PY'
import json,sys,collections
linhas=[json.loads(l) for l in open(sys.argv[1]) if l.strip()]
print(f"  {len(linhas)} eventos:", dict(collections.Counter(e["evento"] for e in linhas)))
# O contrato exige que as 12 chaves ESTEJAM na linha, nao que sejam as unicas:
# chaves extras declaradas (`hook` na mergex e na legadox, `faixa` na legadox)
# sao legitimas. Um `set(e)!=chaves` reprovaria toda linha dessas duas skills.
chaves={"ts","expx_eventos","trabalho_id","ferramenta","origem","evento","fase","task","agente","resultado","detalhe","arquivos"}
extras_ok={"hook","faixa"}
ruins=[e for e in linhas if not chaves <= set(e)]
desconhecidas=sorted({k for e in linhas for k in set(e)-chaves-extras_ok})
print("  todas as linhas com as 12 chaves do contrato:", not ruins)
if desconhecidas:
    print("  AVISO chaves fora do contrato:", ", ".join(desconhecidas))
print("  exemplo:", json.dumps(linhas[0], ensure_ascii=False)[:150])
PY
else
  echo "  NENHUM evento gravado — o rastro nao funcionou"; falhou=$((falhou+1))
fi

echo
echo "== suites de conteudo, espelho e instalacao =="
for suite in testar-conteudo.sh testar-espelho.sh testar-instalacao.sh testar-estado.sh testar-rotacao.sh; do
  if bash "$(dirname "${BASH_SOURCE[0]}")/$suite"; then
    ok=$((ok+1)); printf '  ok   %-46s exit=0\n' "$suite"
  else
    falhou=$((falhou+1)); printf '  FALHA %-45s exit!=0\n' "$suite"
  fi
done

echo
echo "  $ok ok, $falhou falhas"
[ "$falhou" -eq 0 ]
