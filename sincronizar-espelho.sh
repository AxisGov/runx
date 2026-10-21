#!/usr/bin/env bash
# Gera o espelho OpenCode exclusivamente da fonte Claude canônica.
set -euo pipefail

R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIGEM="$R/.claude/skills/runx"
DESTINO="$R/.opencode/skills/runx"
MODO="${1:-sincronizar}"

[ -f "$ORIGEM/SKILL.md" ] || { echo "erro: fonte canonica ausente: $ORIGEM" >&2; exit 1; }
[ "$MODO" = "sincronizar" ] || [ "$MODO" = "--check" ] || {
  echo "uso: $0 [--check]" >&2
  exit 2
}

if [ "$MODO" = "--check" ]; then
  [ -d "$DESTINO" ] && diff -rq "$ORIGEM" "$DESTINO"
  exit $?
fi

PAI="$(dirname "$DESTINO")"
mkdir -p "$PAI"
TMP="$(mktemp -d "$PAI/.runx-sync.XXXXXX")"
ANTERIOR=""
limpar() {
  [ ! -e "$TMP" ] || rm -rf "$TMP"
  if [ -n "$ANTERIOR" ] && [ -e "$ANTERIOR" ] && [ ! -e "$DESTINO" ]; then
    mv "$ANTERIOR" "$DESTINO"
  fi
}
trap limpar EXIT

cp -R "$ORIGEM" "$TMP/runx"
diff -rq "$ORIGEM" "$TMP/runx" >/dev/null

if [ -e "$DESTINO" ]; then
  ANTERIOR="$PAI/.runx-anterior.$$"
  mv "$DESTINO" "$ANTERIOR"
fi
mv "$TMP/runx" "$DESTINO"
rmdir "$TMP"
TMP=""
if [ -n "$ANTERIOR" ]; then
  rm -rf "$ANTERIOR"
  ANTERIOR=""
fi

diff -rq "$ORIGEM" "$DESTINO" >/dev/null
