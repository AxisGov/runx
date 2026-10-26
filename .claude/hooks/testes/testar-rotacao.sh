#!/usr/bin/env bash
# Rotacao do rastro sob concorrencia (katosmv/conselhos-municipais#208, M3).
#
# Sem trava, dois gravadores que viam o arquivo acima do limite escolhiam o mesmo
# `.<n>.jsonl`; o segundo rename movia o arquivo NOVO por cima do segmento e os
# eventos antigos sumiam. A corrida e reproduzida de forma deterministica: durante o
# rename do gravador A, um gravador B rotaciona e outro acrescenta um evento.
set -uo pipefail

HK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

python3 - "$HK/comum" "$T" <<'PY'
import os, sys
sys.path.insert(0, sys.argv[1])
import expx_rastro as R

base = sys.argv[2]
R.MAX_RASTRO_BYTES = 100  # o limite real e 5 MB; o comportamento e o mesmo
ok = falhou = 0

def afirma(nome, cond, diag=""):
    global ok, falhou
    if cond:
        ok += 1; print("  ok    %-32s" % nome)
    else:
        falhou += 1; print("  FALHA %-32s %s" % (nome, diag))

def pasta(nome):
    p = os.path.join(base, nome)
    os.makedirs(p)
    caminho = os.path.join(p, "OC-2026-0001.jsonl")
    with open(caminho, "w") as f:
        f.write("ANTIGO " * 40 + "\n")
    return p, caminho

def ler(caminho):
    try:
        with open(caminho) as f:
            return f.read()
    except OSError:
        return ""

print("== rotacao do rastro ==")

# (a) Trava presente: ninguem rotaciona, o arquivo so cresce.
p, caminho = pasta("travada")
os.mkdir(os.path.join(p, ".OC-2026-0001.rotacao"))
R._rotaciona(caminho)
afirma("trava-presente-nao-rotaciona",
       "ANTIGO" in ler(caminho) and not os.path.exists(caminho[:-6] + ".1.jsonl"))

# (b) Corrida: B rotaciona e um evento novo chega no meio do rename de A.
p, caminho = pasta("corrida")
rename_original = os.rename
estado = {"dentro": False}

def rename_de_a(origem, destino):
    if not estado["dentro"]:
        estado["dentro"] = True
        R._rotaciona(caminho)            # gravador B, que tambem viu o arquivo grande
        with open(caminho, "a") as f:    # gravador C acrescenta um evento
            f.write("NOVO\n")
    return rename_original(origem, destino)

os.rename = rename_de_a
try:
    R._rotaciona(caminho)                # gravador A
finally:
    os.rename = rename_original
segmentos = [os.path.join(p, n) for n in sorted(os.listdir(p)) if n.endswith(".jsonl")]
tudo = "".join(ler(s) for s in segmentos)
afirma("corrida-nao-perde-o-antigo", "ANTIGO" in tudo, "segmentos: %s" % [os.path.basename(s) for s in segmentos])
afirma("corrida-nao-perde-o-novo", "NOVO" in tudo)
afirma("corrida-libera-a-trava", not os.path.exists(os.path.join(p, ".OC-2026-0001.rotacao")))

# (c) Sem disputa: rotaciona para .1 e, na proxima vez, para .2.
p, caminho = pasta("sequencia")
R._rotaciona(caminho)
with open(caminho, "w") as f:
    f.write("SEGUNDO " * 40 + "\n")
R._rotaciona(caminho)
afirma("rotaciona-1-depois-2",
       "ANTIGO" in ler(caminho[:-6] + ".1.jsonl") and "SEGUNDO" in ler(caminho[:-6] + ".2.jsonl")
       and not os.path.exists(caminho))

# (d) Abaixo do limite, nada acontece e nenhuma trava e criada.
p, caminho = pasta("pequeno")
with open(caminho, "w") as f:
    f.write("x\n")
R._rotaciona(caminho)
afirma("abaixo-do-limite-intacto",
       ler(caminho) == "x\n" and not os.path.exists(os.path.join(p, ".OC-2026-0001.rotacao")))

print("\n  %d ok, %d falhas" % (ok, falhou))
sys.exit(1 if falhou else 0)
PY
