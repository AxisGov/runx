#!/usr/bin/env bash
# Prova que a instalacao nasce da fonte Claude canonica (ou de espelho acabado
# de validar), sem restaurar uma copia historica. Tudo acontece em temporarios.
set -uo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
F="$T/fonte"
D="$T/destino"
mkdir -p "$F" "$D"
cp "$R/install.sh" "$F/install.sh"
cp -R "$R/.claude" "$F/.claude"
cp -R "$R/.opencode" "$F/.opencode"

# Simula exatamente o risco: uma copia historica existe, mas a fonte canonica
# ja mudou. O instalador novo nao pode distribuir estes bytes adulterados.
printf '\nCOPIA-HISTORICA-NAO-DISTRIBUIR\n' >> "$F/.opencode/skills/runx/SKILL.md"

ok=0; falhou=0
afirma() {
  local nome="$1" desc="$2"; shift 2
  if "$@"; then
    ok=$((ok+1)); printf '  ok    %-28s %s\n' "$nome" "$desc"
  else
    falhou=$((falhou+1)); printf '  FALHA %-28s %s\n' "$nome" "$desc"
  fi
}

echo "== instalacao temporaria da assinatura nova =="
saida=$(cd "$D" && bash "$F/install.sh" --claude --opencode --force 2>&1); codigo=$?
afirma instalador-sai-zero "install.sh conclui no destino temporario" test "$codigo" -eq 0

afirma claude-byte-a-byte \
  "Claude recebe nucleo, references e assets da fonte canonica" \
  diff -rq "$F/.claude/skills/runx" "$D/.claude/skills/runx"

afirma opencode-byte-a-byte \
  "OpenCode recebe a mesma arvore canonica, nao a copia historica" \
  diff -rq "$F/.claude/skills/runx" "$D/.opencode/skills/runx"

afirma agentes-byte-a-byte \
  "os tres agentes instalados conservam os bytes da fonte" \
  diff -rq "$F/.claude/agents" "$D/.claude/agents"

afirma assinatura-nucleo-nova \
  "o nucleo instalado traz usage_limit_reached e cabe em 8000 bytes" \
  bash -c 'grep -q usage_limit_reached "$1" && [ "$(wc -c < "$1")" -le 8000 ]' _ "$D/.claude/skills/runx/SKILL.md"

afirma assinatura-politica-nova \
  "a instalacao traz classes canonicas e remove model inherit" \
  bash -c 'grep -rq mecanico_triagem "$1/references" && ! grep -rq "model: inherit" "$2"' \
    _ "$D/.claude/skills/runx" "$D/.claude/agents"

afirma session-start-recuperacao \
  "instalação registra estado.py session-start no Claude Code" \
  bash -c 'python3 - "$1/.claude/settings.json" <<"PY"
import json, sys
d=json.load(open(sys.argv[1]))
grupos=d.get("hooks",{}).get("SessionStart",[])
assert any("estado.py\" session-start" in h.get("command", "") for g in grupos for h in g.get("hooks", []))
PY' _ "$D"

if [ "$codigo" -ne 0 ]; then printf '%s\n' "$saida" | sed 's/^/          /' | head -20; fi
printf '\n  %s ok, %s falhas\n' "$ok" "$falhou"
[ "$falhou" -eq 0 ]
