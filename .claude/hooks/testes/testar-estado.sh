#!/usr/bin/env bash
# Contrato executável de marcos, recuperação e handoff da RunX.
set -uo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
HELPER="$R/.claude/hooks/comum/estado.py"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
W="$T/projeto"
O="$W/docs/manutencao/OC-2026-0042-cache"
mkdir -p "$O/sprint-01" "$W/.expx" "$W/docs/eventos"
touch "$W/.git"

cat > "$O/ORQUESTRADOR.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: orquestrador
trabalho_id: OC-2026-0042
titulo: Cache divergente
tipo_trabalho: ocorrencia
tipo_ocorrencia: bug
estagio: e3
status: em_andamento
criado_em: 2026-10-20
atualizado_em: 2026-10-20
concluido_em: null
sprints: [sprint-01]
caminho_critico: [T-01.01, T-01.02]
---
# Orquestrador
EOF

cat > "$O/sprint-01/tasks.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: tasks
trabalho_id: OC-2026-0042
sprint_id: sprint-01
atualizado_em: 2026-10-20
tasks:
  - id: T-01.01
    status: concluida
  - id: T-01.02
    status: em_andamento
---
EOF

cat > "$O/BLOQUEIOS.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: bloqueios
trabalho_id: OC-2026-0042
atualizado_em: 2026-10-20
bloqueios: []
---
EOF
printf '%s\n' '# Decisões' 'D-01 | usar cache local | remoto | latência' > "$O/00-DECISOES.md"
printf '%s\n' '# Causa' 'CAUSA-SEGREDO-NAO-COPIAR' > "$O/01-CAUSA-RAIZ.md"

cat > "$W/.expx/estado.json" <<'EOF'
{"expx_estado":1,"atualizado_em":null,"trabalho":"OC-2026-0042","ferramenta":"runx","titulo_curto":"Cache divergente","fase":"e2","task":null,"tasks_concluidas":0,"tasks_total":2,"raio":9,"orcamento_arquivos":12,"orcamento_linhas":300,"branch":"fix/cache","pr_estado":null,"bloqueios":0}
EOF
printf '%s\n' '# handoff antigo' > "$W/.expx/handoff.md"

ok=0; falhou=0
afirma() {
  local nome="$1" desc="$2"; shift 2
  if "$@"; then ok=$((ok+1)); printf '  ok    %-30s %s\n' "$nome" "$desc"
  else falhou=$((falhou+1)); printf '  FALHA %-30s %s\n' "$nome" "$desc"; fi
}

echo "== helper de marcos e recuperação =="
afirma helper-existe "estado.py existe" test -f "$HELPER"

# E1 ainda não tem ORQUESTRADOR.md: o marco E1→E2 precisa nascer dos
# artefatos da ocorrência, sem antecipar a criação do mapa do plano.
N="$W/docs/manutencao/OC-2026-0043-bootstrap"
mkdir -p "$N"
cat > "$N/00-OCORRENCIA.md" <<'EOF'
---
expx_schema: 1
expx_tool: runx
kind: ocorrencia
trabalho_id: OC-2026-0043
titulo: Bootstrap sem orquestrador
---
EOF
bootstrap_saida=$(cd "$W" && python3 "$HELPER" marco --ocorrencia "$N" \
  --tipo transicao --id E1-E2 --resultado e2 --agora 2026-10-21T11:59:00Z 2>&1); bootstrap=$?
afirma bootstrap-e1-e2 "E1→E2 funciona antes de existir ORQUESTRADOR.md" \
  bash -c '[ "$1" -eq 0 ] && [ -z "$2" ] && [ ! -e "$3/ORQUESTRADOR.md" ] && \
    python3 -c "import json,sys; e=json.load(open(sys.argv[1])); assert e[\"trabalho\"]==\"OC-2026-0043\" and e[\"fase\"]==\"e2\"" "$4/.expx/estado.json"' \
  _ "$bootstrap" "$bootstrap_saida" "$N" "$W"
# Restaura a ocorrência principal para os casos seguintes.
python3 - "$W/.expx/estado.json" <<'PY'
import json, sys
p=sys.argv[1]; e=json.load(open(p)); e.update(trabalho="OC-2026-0042", fase="e2");
open(p,"w").write(json.dumps(e)+"\n")
PY

# Evento mecânico usa o rastro existente e não pode provocar churn de estado.
antes_estado=$(sha256sum "$W/.expx/estado.json" | cut -d' ' -f1)
antes_orq=$(sha256sum "$O/ORQUESTRADOR.md" | cut -d' ' -f1)
antes_handoff=$(sha256sum "$W/.expx/handoff.md" | cut -d' ' -f1)
(cd "$W" && python3 "$R/.claude/hooks/comum/rastro.py" --evento task_concluida \
  --trabalho OC-2026-0042 --fase e3 --task T-01.01 >/dev/null 2>&1)
afirma mecanico-sem-churn "evento mecânico não reescreve estado/orquestrador/handoff" \
  bash -c '[ "$1" = "$(sha256sum "$4/.expx/estado.json" | cut -d" " -f1)" ] && \
    [ "$2" = "$(sha256sum "$5/ORQUESTRADOR.md" | cut -d" " -f1)" ] && \
    [ "$3" = "$(sha256sum "$4/.expx/handoff.md" | cut -d" " -f1)" ]' \
  _ "$antes_estado" "$antes_orq" "$antes_handoff" "$W" "$O"
afirma jsonl-mecanico-pequeno "evento mecânico gera JSONL abaixo de 1 KB" \
  bash -c 'f="$1/docs/eventos/OC-2026-0042.jsonl"; [ -s "$f" ] && [ "$(wc -c < "$f")" -lt 1024 ]' _ "$W"
if [ ! -s "$W/docs/eventos/OC-2026-0042.jsonl" ]; then
  printf '        diagnóstico: JSONL não foi criado\n'
elif [ "$(wc -c < "$W/docs/eventos/OC-2026-0042.jsonl")" -ge 1024 ]; then
  printf '        diagnóstico: JSONL tem %s bytes\n' "$(wc -c < "$W/docs/eventos/OC-2026-0042.jsonl")"
fi

saida=""; codigo=127
if [ -f "$HELPER" ]; then
  saida=$(cd "$W" && python3 "$HELPER" marco --ocorrencia "$O" --tipo transicao \
    --id E3-E4 --resultado e4 --agora 2026-10-21T12:00:00Z 2>&1); codigo=$?
fi
afirma marco-sai-zero-sem-stdout "transição é determinística e silenciosa" \
  bash -c '[ "$1" -eq 0 ] && [ -z "$2" ]' _ "$codigo" "$saida"
afirma marco-atualiza-tres "transição atualiza orquestrador, estado e handoff" \
  bash -c 'grep -q "estagio: e4" "$1/ORQUESTRADOR.md" && \
    python3 -c "import json,sys; e=json.load(open(sys.argv[1])); assert e[\"fase\"]==\"e4\" and e[\"tasks_concluidas\"]==1 and e[\"tasks_total\"]==2 and e[\"task\"]==\"T-01.02\" and e[\"raio\"]==9" "$2/.expx/estado.json" && \
    grep -q "ORQUESTRADOR.md" "$2/.expx/handoff.md"' _ "$O" "$W"
afirma handoff-ponteiros-limite "handoff usa ponteiros, não copia causa/log, e cabe em 500 tokens" \
  bash -c 'f="$1/.expx/handoff.md"; [ "$(wc -c < "$f")" -le 2000 ] && \
    ! grep -q "CAUSA-SEGREDO-NAO-COPIAR" "$f" && grep -q "01-CAUSA-RAIZ.md" "$f"' _ "$W"
afirma marco-atomico-jsonl "marco deixa JSON válido, sem temporário, e JSONL pequeno" \
  bash -c '[ "$1" -eq 0 ] && python3 -m json.tool "$2/.expx/estado.json" >/dev/null && \
    grep -q "2026-10-21T12:00:00Z" "$2/.expx/estado.json" && \
    ! find "$2/.expx" -name "*.tmp" -print -quit | grep -q . && \
    [ "$(wc -c < "$2/docs/eventos/OC-2026-0042.jsonl")" -lt 1024 ]' _ "$codigo" "$W"

# Retorno explícito E4→E3 é uma transição válida.
volta=127
if [ -f "$HELPER" ]; then
  (cd "$W" && python3 "$HELPER" marco --ocorrencia "$O" --tipo transicao \
    --id E4-E3 --resultado e3 --agora 2026-10-21T12:01:00Z >/dev/null 2>&1); volta=$?
fi
afirma retorno-e4-e3 "retorno E4→E3 é aceito e persistido" \
  bash -c '[ "$1" -eq 0 ] && grep -q "estagio: e3" "$2/ORQUESTRADOR.md" && \
    python3 -c "import json,sys; assert json.load(open(sys.argv[1]))[\"fase\"]==\"e3\"" "$3/.expx/estado.json"' \
  _ "$volta" "$O" "$W"

# Simula queda: task foi persistida, cache ficou atrasado. Reconstrução deriva do disco.
sed -i 's/status: em_andamento/status: concluida/' "$O/sprint-01/tasks.md"
recon_saida=""; recon=127
if [ -f "$HELPER" ]; then
  recon_saida=$(cd "$W" && python3 "$HELPER" reconstruir --ocorrencia "$O" \
    --agora 2026-10-21T12:02:00Z 2>&1); recon=$?
fi
afirma reconstruir-interrupcao "reconstrução recupera estágio e contadores após queda" \
  bash -c '[ "$1" -eq 0 ] && [ -z "$2" ] && python3 -c "import json,sys; e=json.load(open(sys.argv[1])); assert e[\"fase\"]==\"e3\" and e[\"tasks_concluidas\"]==2 and e[\"tasks_total\"]==2 and e[\"task\"] is None" "$3/.expx/estado.json"' \
  _ "$recon" "$recon_saida" "$W"

# SessionStart usa o trabalho do cache apenas para localizar a fonte versionada
# e então a reconstrói; não depende de uma chamada do modelo.
sed -i 's/"tasks_concluidas": 2/"tasks_concluidas": 0/' "$W/.expx/estado.json"
sessao_saida=$(printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$W" | \
  (cd "$W" && python3 "$HELPER" session-start) 2>&1); sessao=$?
afirma session-start-reconstroi "SessionStart recupera cache atrasado sem stdout" \
  bash -c '[ "$1" -eq 0 ] && [ -z "$2" ] && python3 -c "import json,sys; assert json.load(open(sys.argv[1]))[\"tasks_concluidas\"]==2" "$3/.expx/estado.json"' \
  _ "$sessao" "$sessao_saida" "$W"

# O encerramento é fato versionado e precisa sobreviver a qualquer reconstrução.
sed -i 's/^status: em_andamento$/status: concluido/; s/^concluido_em: null$/concluido_em: 2026-10-21/' "$O/ORQUESTRADOR.md"
(cd "$W" && python3 "$HELPER" reconstruir --ocorrencia "$O" --agora 2026-10-21T12:03:00Z >/dev/null 2>&1); encerrado=$?
afirma reconstruir-termino "reconstrução conserva trabalho, fase e task nulos após término" \
  bash -c '[ "$1" -eq 0 ] && python3 -c "import json,sys; e=json.load(open(sys.argv[1])); assert e[\"trabalho\"] is None and e[\"fase\"] is None and e[\"task\"] is None" "$2/.expx/estado.json"' \
  _ "$encerrado" "$W"

printf '\n  %s ok, %s falhas\n' "$ok" "$falhou"
[ "$falhou" -eq 0 ]
