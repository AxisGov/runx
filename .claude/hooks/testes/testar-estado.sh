#!/usr/bin/env bash
# Contrato executável de marcos, recuperação e handoff da RunX.
set -uo pipefail

# A mesma suite roda pela fonte (.claude/hooks/testes) e pela copia no marketplace
# do expx (.expx/marketplace/plugins/expx/hooks/testes): os helpers sao achados a
# partir da arvore de hooks que contem este script, nunca da raiz do repositorio.
HK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$HK/comum/estado.py"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
hash_arquivo() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -- "$1" | awk '{print $1}'
  else
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  fi
}
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
antes_estado=$(hash_arquivo "$W/.expx/estado.json")
antes_orq=$(hash_arquivo "$O/ORQUESTRADOR.md")
antes_handoff=$(hash_arquivo "$W/.expx/handoff.md")
(cd "$W" && python3 "$HK/comum/rastro.py" --evento task_concluida \
  --trabalho OC-2026-0042 --fase e3 --task T-01.01 >/dev/null 2>&1)
depois_estado=$(hash_arquivo "$W/.expx/estado.json")
depois_orq=$(hash_arquivo "$O/ORQUESTRADOR.md")
depois_handoff=$(hash_arquivo "$W/.expx/handoff.md")
afirma mecanico-sem-churn "evento mecânico não reescreve estado/orquestrador/handoff" \
  bash -c '[ "$1" = "$4" ] && [ "$2" = "$5" ] && [ "$3" = "$6" ]' \
  _ "$antes_estado" "$antes_orq" "$antes_handoff" "$depois_estado" "$depois_orq" "$depois_handoff"
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
sed 's/status: em_andamento/status: concluida/' "$O/sprint-01/tasks.md" > "$O/sprint-01/tasks.md.edicao" && mv "$O/sprint-01/tasks.md.edicao" "$O/sprint-01/tasks.md"
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
sed 's/"tasks_concluidas": 2/"tasks_concluidas": 0/' "$W/.expx/estado.json" > "$W/.expx/estado.json.edicao" && mv "$W/.expx/estado.json.edicao" "$W/.expx/estado.json"
sessao_saida=$(printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$W" | \
  (cd "$W" && python3 "$HELPER" session-start) 2>&1); sessao=$?
afirma session-start-reconstroi "SessionStart recupera cache atrasado sem stdout" \
  bash -c '[ "$1" -eq 0 ] && [ -z "$2" ] && python3 -c "import json,sys; assert json.load(open(sys.argv[1]))[\"tasks_concluidas\"]==2" "$3/.expx/estado.json"' \
  _ "$sessao" "$sessao_saida" "$W"

# O encerramento é fato versionado e precisa sobreviver a qualquer reconstrução.
sed 's/^status: em_andamento$/status: concluido/; s/^concluido_em: null$/concluido_em: 2026-10-21/' "$O/ORQUESTRADOR.md" > "$O/ORQUESTRADOR.md.edicao" && mv "$O/ORQUESTRADOR.md.edicao" "$O/ORQUESTRADOR.md"
(cd "$W" && python3 "$HELPER" reconstruir --ocorrencia "$O" --agora 2026-10-21T12:03:00Z >/dev/null 2>&1); encerrado=$?
afirma reconstruir-termino "reconstrução conserva trabalho, fase e task nulos após término" \
  bash -c '[ "$1" -eq 0 ] && python3 -c "import json,sys; e=json.load(open(sys.argv[1])); assert e[\"trabalho\"] is None and e[\"fase\"] is None and e[\"task\"] is None" "$2/.expx/estado.json"' \
  _ "$encerrado" "$W"

# Handoff acima do limite recusa o marco inteiro: nada de estado.json novo com
# handoff.md velho (katosmv/conselhos-municipais#208). Muitas sprints estouram os
# ponteiros do handoff; a validação vem antes de qualquer escrita.
G="$W/docs/manutencao/OC-2026-0044-grande"
mkdir -p "$G"
sed 's/OC-2026-0042/OC-2026-0044/; s/^status: concluido$/status: em_andamento/; s/^concluido_em: .*$/concluido_em: null/' \
  "$O/ORQUESTRADOR.md" > "$G/ORQUESTRADOR.md"
for n in $(seq -w 1 40); do
  mkdir -p "$G/sprint-$n"
  sed "s/OC-2026-0042/OC-2026-0044/; s/sprint-01/sprint-$n/" "$O/sprint-01/tasks.md" > "$G/sprint-$n/tasks.md"
done
antes_estado=$(hash_arquivo "$W/.expx/estado.json")
antes_handoff=$(hash_arquivo "$W/.expx/handoff.md")
(cd "$W" && python3 "$HELPER" reconstruir --ocorrencia "$G" --agora 2026-10-21T12:04:00Z >/dev/null 2>&1); grande=$?
depois_estado=$(hash_arquivo "$W/.expx/estado.json")
depois_handoff=$(hash_arquivo "$W/.expx/handoff.md")
afirma handoff-grande-nao-meio-grava "handoff acima de 2 KB falha sem gravar estado nem handoff" \
  bash -c '[ "$1" -ne 0 ] && [ "$2" = "$4" ] && [ "$3" = "$5" ] && \
    ! find "$6/.expx" -name "*.tmp" -print -quit | grep -q .' \
  _ "$grande" "$antes_estado" "$antes_handoff" "$depois_estado" "$depois_handoff" "$W"

# O marco grava o ORQUESTRADOR.md e deriva estado e handoff: recusado pelo limite,
# nem o orquestrador avança (etapa nova com estado e handoff velhos).
# (dia diferente do `atualizado_em` atual: um marco aceito mudaria o arquivo)
antes_orq=$(hash_arquivo "$G/ORQUESTRADOR.md")
(cd "$W" && python3 "$HELPER" marco --ocorrencia "$G" --tipo decisao --id D-01 --resultado ok \
  --agora 2026-10-25T12:05:00Z >/dev/null 2>&1); grande_marco=$?
depois_orq=$(hash_arquivo "$G/ORQUESTRADOR.md")
marco_estado=$(hash_arquivo "$W/.expx/estado.json")
marco_handoff=$(hash_arquivo "$W/.expx/handoff.md")
afirma handoff-grande-marco-nao-avanca "marco recusado pelo handoff não grava o ORQUESTRADOR.md" \
  bash -c '[ "$1" -ne 0 ] && [ "$2" = "$3" ] && [ "$4" = "$5" ] && [ "$6" = "$7" ]' \
  _ "$grande_marco" "$antes_orq" "$depois_orq" "$depois_estado" "$marco_estado" "$depois_handoff" "$marco_handoff"

# --ocorrencia que nao existe, ou sem trabalho_id valido, nao inventa trabalho:
# antes, o id saia de basename.split("-")[0] ("OC") e o estado.json era regravado
# com zero tasks (katosmv/conselhos-municipais#208, M8). Recusa antes de escrever.
recusa_sem_escrita() { # recusa_sem_escrita <nome> <descricao> <comando...>
  local nome="$1" desc="$2"; shift 2
  local ae ah depois_e depois_h erro codigo
  ae=$(hash_arquivo "$W/.expx/estado.json"); ah=$(hash_arquivo "$W/.expx/handoff.md")
  (cd "$W" && "$@" >"$T/recusa.out" 2>"$T/recusa.err"); codigo=$?
  erro="$(cat "$T/recusa.err")"
  depois_e=$(hash_arquivo "$W/.expx/estado.json"); depois_h=$(hash_arquivo "$W/.expx/handoff.md")
  # recusa: codigo != 0, nada gravado, stdout vazio e o motivo em stderr com o prefixo do helper
  afirma "$nome" "$desc" bash -c '[ "$1" -ne 0 ] && [ "$2" = "$3" ] && [ "$4" = "$5" ] && \
      [ ! -s "$7" ] && case "$6" in "estado.py: "*) true ;; *) false ;; esac' \
    _ "$codigo" "$ae" "$depois_e" "$ah" "$depois_h" "$erro" "$T/recusa.out"
}
FANTASMA="$W/docs/manutencao/OC-2026-0099-fantasma"
recusa_sem_escrita reconstruir-inexistente "reconstruir com --ocorrencia inexistente recusa sem gravar" \
  python3 "$HELPER" reconstruir --ocorrencia "$FANTASMA" --agora 2026-10-26T10:00:00Z
recusa_sem_escrita e1e2-inexistente "transicao e1→e2 com --ocorrencia inexistente recusa sem gravar" \
  python3 "$HELPER" marco --ocorrencia "$FANTASMA" --tipo transicao --id E1-E2 --resultado e2 --agora 2026-10-26T10:00:00Z
for caso in sem-id:"" truncado:"OC" outro-oc:"OC-2026-0098"; do
  nome="${caso%%:*}"; id="${caso#*:}"
  X="$W/docs/manutencao/OC-2026-0097-$nome"; mkdir -p "$X"
  { printf -- '---\nexpx_schema: 1\nexpx_tool: runx\nkind: ocorrencia\n'
    [ -n "$id" ] && printf 'trabalho_id: %s\n' "$id"
    printf 'titulo: Caso %s\n---\n' "$nome"; } > "$X/00-OCORRENCIA.md"
  recusa_sem_escrita "id-$nome" "00-OCORRENCIA com trabalho_id $nome recusa sem gravar" \
    python3 "$HELPER" reconstruir --ocorrencia "$X" --agora 2026-10-26T10:00:00Z
done

# ORQUESTRADOR presente e sem trabalho_id: ele e a fonte, e o 00-OCORRENCIA valido
# ao lado nao o substitui.
X="$W/docs/manutencao/OC-2026-0096-orq-sem-id"; mkdir -p "$X"
printf -- '---\nexpx_tool: runx\nkind: ocorrencia\ntrabalho_id: OC-2026-0096\n---\n' > "$X/00-OCORRENCIA.md"
printf -- '---\nexpx_tool: runx\nkind: orquestrador\nestagio: e3\nstatus: em_andamento\nconcluido_em: null\n---\n' > "$X/ORQUESTRADOR.md"
recusa_sem_escrita orquestrador-sem-id "ORQUESTRADOR sem trabalho_id recusa, mesmo com 00-OCORRENCIA válido" \
  python3 "$HELPER" reconstruir --ocorrencia "$X" --agora 2026-10-26T10:00:00Z
# Pasta fora de docs/manutencao/, ainda que com nome e id certos.
F="$W/docs/outra/OC-2026-0042-cache"; mkdir -p "$F"; cp "$O/ORQUESTRADOR.md" "$F/"
recusa_sem_escrita fora-de-manutencao "ocorrência fora de docs/manutencao/ recusa sem gravar" \
  python3 "$HELPER" reconstruir --ocorrencia "$F" --agora 2026-10-26T10:00:00Z

# termino so vale no E5, o ultimo estagio (05-relatorio.md). Antes, era aceito em
# qualquer estagio e gravava status: concluido (M9).
TE="$W/docs/manutencao/OC-2026-0045-termino"
mkdir -p "$TE"
sed 's/OC-2026-0042/OC-2026-0045/; s/^estagio: .*$/estagio: e3/; s/^status: .*$/status: em_andamento/; s/^concluido_em: .*$/concluido_em: null/' \
  "$O/ORQUESTRADOR.md" > "$TE/ORQUESTRADOR.md"
antes_orq=$(hash_arquivo "$TE/ORQUESTRADOR.md")
recusa_sem_escrita termino-fora-do-e5 "termino no e3 recusa sem gravar estado nem handoff" \
  python3 "$HELPER" marco --ocorrencia "$TE" --tipo termino --id FIM --resultado ok --agora 2026-10-26T10:00:00Z
afirma termino-fora-nao-conclui "termino no e3 não toca o ORQUESTRADOR.md" \
  bash -c '[ "$1" = "$2" ] && ! grep -q "^status: concluido$" "$3"' \
  _ "$antes_orq" "$(hash_arquivo "$TE/ORQUESTRADOR.md")" "$TE/ORQUESTRADOR.md"
sed 's/^estagio: e3$/estagio: e5/' "$TE/ORQUESTRADOR.md" > "$TE/ORQUESTRADOR.md.edicao" && mv "$TE/ORQUESTRADOR.md.edicao" "$TE/ORQUESTRADOR.md"
(cd "$W" && python3 "$HELPER" marco --ocorrencia "$TE" --tipo termino --id FIM --resultado ok \
  --agora 2026-10-26T10:01:00Z >/dev/null 2>&1); termino_e5=$?
afirma termino-no-e5 "termino no e5 conclui a ocorrência" \
  bash -c '[ "$1" -eq 0 ] && grep -q "^status: concluido$" "$2" && grep -q "^concluido_em: 2026-10-26$" "$2"' \
  _ "$termino_e5" "$TE/ORQUESTRADOR.md"

# SessionStart acha a ocorrencia pelos artefatos versionados, nunca pelo
# `trabalho` do estado.json (contrato expx-estado: so exibicao).
S="$T/sessao"; mkdir -p "$S/.expx" "$S/docs/manutencao"; touch "$S/.git"
mkdir -p "$S/docs/manutencao/OC-2026-0200-real"
sed 's/OC-2026-0042/OC-2026-0200/' "$O/sprint-01/../ORQUESTRADOR.md" \
  | sed 's/^status: .*$/status: em_andamento/; s/^concluido_em: .*$/concluido_em: null/; s/^estagio: .*$/estagio: e3/' \
  > "$S/docs/manutencao/OC-2026-0200-real/ORQUESTRADOR.md"
printf '%s\n' '{"expx_estado":1,"trabalho":"OC-2026-0999","fase":"e2","tasks_concluidas":0}' > "$S/.expx/estado.json"
saida_s=$(printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$S" | (cd "$S" && python3 "$HELPER" session-start) 2>/dev/null); cod_s=$?
afirma session-start-pelos-artefatos "SessionStart reconstrói a ocorrência versionada, não a do cache" \
  bash -c '[ "$1" -eq 0 ] && [ -z "$2" ] && python3 -c "import json,sys; e=json.load(open(sys.argv[1])); assert e[\"trabalho\"]==\"OC-2026-0200\" and e[\"fase\"]==\"e3\"" "$3/.expx/estado.json"' \
  _ "$cod_s" "$saida_s" "$S"

# Ocorrencia aberta mas invalida: a sessao segue (exit 0) e nada e gravado.
I="$T/sessao-invalida"; mkdir -p "$I/.expx" "$I/docs/manutencao/OC-2026-0300-x"; touch "$I/.git"
printf -- '---\nexpx_tool: runx\nkind: ocorrencia\ntrabalho_id: OC\n---\n' > "$I/docs/manutencao/OC-2026-0300-x/00-OCORRENCIA.md"
printf '%s\n' '{"expx_estado":1,"trabalho":null}' > "$I/.expx/estado.json"
antes_i=$(hash_arquivo "$I/.expx/estado.json")
saida_i=$(printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$I" | (cd "$I" && python3 "$HELPER" session-start) 2>/dev/null); cod_i=$?
afirma session-start-recusa-fail-open "SessionStart com ocorrência inválida sai 0, sem stdout e sem gravar" \
  bash -c '[ "$1" -eq 0 ] && [ -z "$2" ] && [ "$3" = "$4" ] && [ ! -e "$5/.expx/handoff.md" ]' \
  _ "$cod_i" "$saida_i" "$antes_i" "$(hash_arquivo "$I/.expx/estado.json")" "$I"

printf '\n  %s ok, %s falhas\n' "$ok" "$falhou"
[ "$falhou" -eq 0 ]
