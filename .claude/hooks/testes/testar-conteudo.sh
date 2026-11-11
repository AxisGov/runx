#!/usr/bin/env bash
# Verificador do CONTEUDO das skills. Diferente do testar.sh, que roda os hooks
# Python, este confere que os markdown da runx dizem o que o metodo exige que
# digam. Markdown nao tem compilador: sem isso, uma regra pode sumir de um
# reference e ninguem percebe ate a proxima ocorrencia rodar errado.
#
# Cada asercao tem NOME. Uma asercao que so faz grep de palavra comum nao
# discrimina: as daqui casam estrutura (kind declarado, enum com os quatro
# valores, o caminho literal que os hooks buscam).
set -uo pipefail

# A mesma suíte também roda pela cópia no marketplace do EXpXDev.
# Encontre o checkout que contém a skill, não dependa da profundidade do script.
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
while [ "$R" != "/" ] && [ ! -d "$R/.claude/skills/runx" ]; do
  R="$(dirname "$R")"
done
[ -d "$R/.claude/skills/runx" ] || { echo "testar-conteudo: raiz do projeto não encontrada" >&2; exit 1; }
S="$R/.claude/skills/runx"

ok=0; falhou=0
FILTRO="${EXPX_TESTE_FILTRO:-}"
afirma() { # afirma <nome> <descricao> ; le o predicado do stdin (exit 0 = passa)
  local nome="$1" desc="$2"
  if [ -n "$FILTRO" ] && ! [[ "$nome" =~ $FILTRO ]]; then return; fi
  if "${@:3}"; then
    ok=$((ok+1)); printf '  ok    %-32s %s\n' "$nome" "$desc"
  else
    falhou=$((falhou+1)); printf '  FALHA %-32s %s\n' "$nome" "$desc"
  fi
}

# --- predicados -------------------------------------------------------------
# Todos recebem o texto ja lido; usam grep -q com padroes estruturais.

tem() { grep -qE "$2" "$1" 2>/dev/null; }
conta_ge() { [ "$(grep -cE "$2" "$1" 2>/dev/null)" -ge "$3" ]; }

echo "== andaime condensado =="

afirma kind-plano-declarado \
  "00-schema.md declara o kind plano" \
  tem "$S/references/00-schema.md" '^### .*`kind: plano`|kind: plano'

afirma kind-plano-tem-as-tres-chaves \
  "o kind plano traz sprint, fases e tasks no mesmo bloco" \
  bash -c 'awk "/kind: plano/,/^###|^## /" "'"$S"'/references/00-schema.md" \
    | grep -q "^sprint:" && awk "/kind: plano/,/^###|^## /" "'"$S"'/references/00-schema.md" \
    | grep -q "^fases:" && awk "/kind: plano/,/^###|^## /" "'"$S"'/references/00-schema.md" \
    | grep -q "^tasks:"'

afirma kind-compartilhado-intacto \
  "os kinds sprint, fases e tasks continuam declarados" \
  bash -c 'grep -q "### .sprint-NN/sprint.md. → .kind: sprint." "'"$S"'/references/00-schema.md" \
    && grep -q "### .sprint-NN/fases.md. → .kind: fases." "'"$S"'/references/00-schema.md" \
    && grep -q "### .sprint-NN/tasks.md. → .kind: tasks." "'"$S"'/references/00-schema.md"'

afirma template-condensado-existe \
  "TEMPLATE-plano-condensado.md existe" \
  test -f "$S/assets/TEMPLATE-plano-condensado.md"

# O template usa "---" tambem como separador de prosa entre os blocos de task, igual ao
# TEMPLATE-tasks.md. O que importa e que o FRONTMATTER seja um so: abre na linha 1 e
# fecha antes de qualquer prosa. Discrimina o caso real de erro — dois frontmatters em
# sequencia, que o parser dos hooks leria pela metade.
afirma template-condensado-frontmatter-unico \
  "o frontmatter do template abre na linha 1 e fecha antes da prosa" \
  bash -c 'f="'"$S"'/assets/TEMPLATE-plano-condensado.md"; \
    [ "$(head -1 "$f")" = "---" ] || exit 1; \
    fim=$(awk "NR>1 && /^---$/ {print NR; exit}" "$f"); \
    [ -n "$fim" ] || exit 1; \
    depois=$(awk -v f="$fim" "NR>f && NF {print; exit}" "$f"); \
    case "$depois" in ---*) exit 1 ;; esac; \
    awk -v f="$fim" "NR<f" "$f" | grep -q "^tasks:"'

afirma template-condensado-campos-da-task \
  "o template traz os 11 campos do contrato da task" \
  bash -c 'f="'"$S"'/assets/TEMPLATE-plano-condensado.md"; for c in id titulo objetivo arquivos \
    teste_integracao teste_funcional criterio_aceite depende_de paralelizavel status teste_regressao; do \
    grep -q "$c" "$f" || exit 1; done'

afirma template-condensado-regressao-por-task \
  "cada task tem uma unica chave de regressao, obrigatoria no bug e nula no exemplo comum" \
  bash -c 'awk '"'"'
    /^tasks:/ { em_tasks = 1; next }
    em_tasks && /^---$/ { exit }
    em_tasks && /^  - id:/ { task++; next }
    em_tasks && /^    teste_regressao:/ {
      quantidade[task]++
      valor = $0
      sub(/^[^:]*:[[:space:]]*/, "", valor)
      sub(/[[:space:]]*$/, "", valor)
      regressao[task] = valor
    }
    END { exit !(task == 2 && quantidade[1] == 1 && regressao[1] != "" &&
                 regressao[1] != "null" && quantidade[2] == 1 && regressao[2] == "null") }
  '"'"' "'"$S"'/assets/TEMPLATE-plano-condensado.md"'

afirma e2-escolhe-formato \
  "02-plano.md diz quando usar cada formato" \
  bash -c 'grep -q "condensado" "'"$S"'/references/02-plano.md" \
    && grep -qE "1 sprint e 1 fase|uma sprint e uma fase" "'"$S"'/references/02-plano.md"'

afirma e2-condensado-no-caminho-dos-hooks \
  "o condensado e gravado em sprint-NN/tasks.md" \
  bash -c 'awk "/[Cc]ondensado/,0" "'"$S"'/references/02-plano.md" | grep -q "sprint-NN/tasks.md"'

afirma skill-documenta-condensado \
  "SKILL.md menciona o formato condensado" \
  tem "$S/SKILL.md" 'condensad'

echo "== suite parcial =="

afirma enum-suite-tem-parcial \
  "o enum suite lista parcial" \
  bash -c 'grep -E "^\| .suite." "'"$S"'/references/00-schema.md" | grep -q "parcial"'

afirma enum-suite-mantem-os-tres \
  "o enum suite mantem verde, vermelha e nao_executada" \
  bash -c 'l=$(grep -E "^\| .suite." "'"$S"'/references/00-schema.md"); \
    echo "$l" | grep -q "verde" && echo "$l" | grep -q "vermelha" && echo "$l" | grep -q "nao_executada"'

# Discrimina: a frase ANTIGA do 03-fix diz "Verde na suite inteira, NAO em um
# subconjunto" — um grep por "subconjunto" passaria com o texto errado. Exigimos a
# instrucao nova (rodar o subconjunto afetado) E a ausencia da proibicao antiga.
afirma e3-suite-parcial \
  "03-fix.md manda rodar o subconjunto afetado pela task" \
  bash -c 'f="'"$S"'/references/03-fix.md"; \
    grep -qE "subconjunto afetado|testes afetados pela task" "$f" \
    && ! grep -q "Verde na suíte inteira, não em um subconjunto" "$f"'

afirma e3-registra-suite-parcial \
  "03-fix.md manda gravar suite: parcial na task" \
  bash -c 'grep -q "suite: parcial\|suite. parcial" "'"$S"'/references/03-fix.md"'

# Discrimina: o 04-qa ja dizia "A suite inteira passa" no Passo 2. Exigimos que a
# exigencia esteja ligada ao VEREDITO e a task com suite parcial.
afirma e4-exige-completa \
  "04-qa.md liga a suite completa ao veredito" \
  bash -c 'f="'"$S"'/references/04-qa.md"; grep -qE "parcial" "$f" \
    && grep -qiE "antes de emitir o veredito|antes do veredito" "$f"'

echo "== runx-investigador por evidencia =="

afirma runx-investigador-sem-corte-arbitrario \
  "01-investigacao.md decide por evidencia, nao por quantidade" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; grep -qi "evidência local" "$f" \
    && grep -qi "quantidade de arquivos não é critério" "$f"'

afirma e1-caminhos-deterministicos \
  "E1 define raiz Git, OC-ID e slug normalizado de no maximo seis palavras" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; grep -qi "raiz Git" "$f" \
    && grep -q "OC-<AAAA>-<NNNN>" "$f" && grep -qi "slug" "$f" && grep -qi "seis" "$f" \
    && grep -qiE "minúscul|minuscul" "$f" && grep -qi "hífen\|hifen" "$f"'

afirma agentes-apontam-politica-comum \
  "referencias dos tres agentes apontam para a politica comum" \
  bash -c 'for f in 01-investigacao.md 03-fix.md 04-qa.md; do \
    grep -q "references/06-estado.md" "'"$S"'/references/$f" || exit 1; done'

echo "== sessoes paralelas =="

afirma regras-continuam-16 \
  "as regras inviolaveis agora sao 16" \
  bash -c '[ "$(awk "/^## Invariantes/,/^## Máquina/" "'"$S"'/SKILL.md" | grep -cE "^[0-9]+\. ")" -eq 16 ]'

afirma regra-16-cita-worktree \
  "o nucleo liga ocorrencia, worktree e sessao" \
  bash -c 'awk "/^## Invariantes/,/^## Máquina/" "'"$S"'/SKILL.md" | grep -qiE "ocorrência.*worktree.*sessão"'

afirma skill-secao-sessoes-paralelas \
  "01-investigacao.md concentra as instrucoes de worktree" \
  tem "$S/references/01-investigacao.md" '^## Passo 0.b .*worktree'

afirma skill-tabela-hooks-novos \
  "06-estado.md lista os tres eventos operacionais" \
  bash -c 'f="'"$S"'/references/06-estado.md"; grep -q "uma-ocorrencia-por-arvore" "$f" \
    && grep -q "task-reivindicada" "$f" && grep -q "arvore-limpa-antes-da-suite" "$f"'

afirma skill-rastro-sessao-harness \
  "06-estado.md cita sessao e harness no rastro" \
  bash -c 'f="'"$S"'/references/06-estado.md"; grep -q "sessao" "$f" && grep -q "harness" "$f"'

afirma schema-ocorrencia-worktree \
  "o kind ocorrencia tem a chave worktree" \
  bash -c 'awk "/kind: ocorrencia/,/^### /" "'"$S"'/references/00-schema.md" | grep -q "^worktree:"'

afirma template-ocorrencia-worktree \
  "TEMPLATE-ocorrencia.md tem a chave worktree" \
  tem "$S/assets/TEMPLATE-ocorrencia.md" '^worktree:'

afirma e1-passo-worktree \
  "01-investigacao.md manda abrir worktree com git worktree add -b" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; grep -q "git worktree add -b" "$f" \
    && grep -q "package-lock.json" "$f" && grep -q "pnpm-lock.yaml" "$f" && grep -q "requirements.txt" "$f"'

afirma e1-uma-por-arvore \
  "01-investigacao.md declara uma ocorrencia aberta por arvore, com opt-out" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; grep -qi "uma ocorrência aberta por árvore" "$f" \
    && grep -qi "sem worktree" "$f"'

afirma e1-sem-git-tambem-verifica-arvore \
  "o caminho sem Git executa o Passo 0.a antes de criar o scaffold" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; \
    awk "/^## Passo 0 —/,/^## Passo 0.a/" "$f" \
      | tr "\n" " " | grep -q "execute sempre o Passo 0.a .*antes.*criar o scaffold"'

afirma e1-entra-antes-de-gravar \
  "a ocorrencia so e criada e registrada depois da entrada no worktree" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; \
    entrar=$(grep -n "^5\\. \\*\\*Entrar" "$f" | cut -d: -f1); \
    criar=$(grep -n "^6\\. \\*\\*Criar e registrar" "$f" | cut -d: -f1); \
    [ -n "$entrar" ] && [ -n "$criar" ] && [ "$entrar" -lt "$criar" ] \
      && awk "/^6\\. \\*\\*Criar e registrar/,/^Toda a pasta/" "$f" \
        | grep -q "Depois de criar .*00-OCORRENCIA.md"'

afirma e1-ambiguidade-preserva-bug \
  "uma hipotese plausivel de bug preserva os portoes de reproducao e prova" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; \
    awk "/\\*\\*Registre o tipo já classificado/,/\\*\\*Portão único/" "$f" \
      | tr "\n" " " | grep -q "inclui .*bug.*opção plausível.*registre .*bug.*forma conservadora"'

afirma e1-contrato-independe-do-harness \
  "a transicao pode variar, mas a maquina de estados e o resultado nao" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; \
    awk "/^5\\. \\*\\*Entrar/,/^6\\. \\*\\*Criar e registrar/" "$f" \
      | tr "\n" " " | grep -q "mecanismo muda por harness; a máquina de estados e o resultado são os mesmos"'

afirma e1-optout-nao-colide   "sem worktree explicito nao cria segunda ocorrencia na arvore ocupada"   bash -c 'f="'"$S"'/references/01-investigacao.md";     awk "/^## Passo 0.a/,/^## Passo 0.b/" "$f" | tr "\n" " "       | grep -qi "pedido explícito de não usar worktree.*Não crie o scaffold"'

afirma e1-handoff-leva-contexto   "handoff sem transicao leva ID, tipo e relato literal para a nova sessao"   bash -c 'f="'"$S"'/references/01-investigacao.md";     trecho=$(awk "/^5\. \*\*Entrar/,/^6\. \*\*Criar e registrar/" "$f" | tr "\n" " ");     printf "%s" "$trecho" | grep -q "OC-ID"       && printf "%s" "$trecho" | grep -q "tipo classificado"       && printf "%s" "$trecho" | grep -q "relato literal completo"       && printf "%s" "$trecho" | grep -q "reenvie este bloco inteiro"'

afirma e3-task-iniciada \
  "03-fix.md grava task_iniciada, task_concluida e task_bloqueada com --task" \
  bash -c 'f="'"$S"'/references/03-fix.md"; grep -q -- "--evento task_iniciada" "$f" \
    && grep -q -- "--evento task_concluida" "$f" && grep -q -- "--evento task_bloqueada" "$f" \
    && grep -q -- "--task" "$f"'

afirma e3-reivindicacao \
  "03-fix.md trata task reivindicada por outra sessao" \
  bash -c 'grep -qi "reivindicad" "'"$S"'/references/03-fix.md" && grep -qi "outra sessão" "'"$S"'/references/03-fix.md"'

afirma e4-portao-arvore \
  "04-qa.md tem um passo que exige arvore limpa antes da suite completa" \
  bash -c 'f="'"$S"'/references/04-qa.md"; grep -q "git status --porcelain" "$f" && grep -qi "não grave" "$f"'

afirma e2-orq-area-de-trabalho \
  "TEMPLATE-ORQUESTRADOR.md tem a linha Area de trabalho" \
  tem "$S/assets/TEMPLATE-ORQUESTRADOR.md" 'Área de trabalho:'

afirma readme-mimocode \
  "README documenta a coluna MimoCode e a flag --mimocode" \
  bash -c 'f="'"$R"'/README.md"; grep -q "MimoCode" "$f" && grep -q -- "--mimocode" "$f"'

echo "== invariantes do metodo =="

# DR-53: o 07-diagrama.md cita {{ }} como sintaxe de no hexagonal do Mermaid, dentro de
# aspas. E legitimo e esta documentado; os demais arquivos de instrucao nao podem ter.
afirma sem-marcador-vazado \
  "nenhum arquivo de instrucao tem marcador {{...}} vazado (DR-14)" \
  bash -c 'achou=$(grep -rlE "\{\{[a-zA-Z]" "'"$S"'/SKILL.md" "'"$S"'/references/" 2>/dev/null \
    | grep -v "07-diagrama.md"); [ -z "$achou" ]'

afirma decisoes-registradas \
  "DECISOES-DA-SKILL.md registra o ajuste de custo fixo" \
  tem "$S/DECISOES-DA-SKILL.md" '[Cc]usto fixo'

echo "== nucleo minimo e politica operacional =="

afirma nucleo-maximo-8000-bytes \
  "SKILL.md tem no maximo 8000 bytes" \
  bash -c '[ "$(wc -c < "'"$S"'/SKILL.md")" -le 8000 ]'

afirma nucleo-cinco-responsabilidades \
  "o nucleo tem somente gatilho, invariantes, maquina, roteamento e termino" \
  bash -c 'python3 - "'"$S"'/SKILL.md" <<"PY"
import pathlib, sys
titulos = [linha[3:].strip() for linha in pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines() if linha.startswith("## ")]
esperados = ["Gatilho", "Invariantes", "Máquina de estados", "Roteamento por estágio", "Condição de término"]
raise SystemExit(0 if titulos == esperados else 1)
PY'

afirma invariante-freios-globais \
  "o nucleo preserva invariantes e os tres freios operacionais" \
  bash -c 'f="'"$S"'/SKILL.md"; for p in \
    "evidência antes de hipótese" "bug não avança" "plano antes do fix" "regressão primeiro" \
    "escopo travado" "task só fecha verde" "suíte completa em E4" "implementador não aprova" \
    "QA não corrige" "bloqueios são registrados" "usage_limit_reached" \
    "uma sessão por ocorrência" "segunda leitura"; do grep -Fqi "$p" "$f" || exit 1; done'

afirma roteamento-lazy-por-estagio \
  "o roteador carrega uma referencia do estagio e condiciona schema, estado e template" \
  bash -c 'f="'"$S"'/SKILL.md"; for r in 01-investigacao 02-plano 03-fix 04-qa 05-relatorio; do \
    grep -q "$r.md" "$f" || exit 1; done; grep -qi "somente.*estágio atual\|apenas.*estágio atual" "$f" \
    && grep -qi "00-schema.*quando\|quando.*00-schema" "$f" \
    && grep -qi "06-estado.*quando\|quando.*06-estado" "$f" \
    && grep -qi "template.*somente\|template.*apenas" "$f"'

echo "== duplicacao e agentes opcionais =="

afirma duplicacao-blocos-normativos \
  "blocos normativos catalogados aparecem em uma unica fonte" \
  bash -c 'python3 - "'"$S"'" <<"PY"
import pathlib, sys
raiz = pathlib.Path(sys.argv[1])
arquivos = [raiz / "SKILL.md", *sorted((raiz / "references").glob("*.md")), *sorted((raiz / "assets").glob("*.md"))]
textos = [p.read_text(encoding="utf-8").casefold() for p in arquivos]
for trecho in ("nunca omita uma chave", "substitua os marcadores", "toda transição de estágio atualiza", "diagrama é derivado", "escopo travado", "quem implementa não aprova"):
    if sum(t.count(trecho) for t in textos) > 1:
        raise SystemExit(1)
PY'

# A prova 1 manda escrever um teste temporario, e a regra do Bash proibia toda escrita: o
# agente nao conseguia seguir o proprio metodo (CodeAnt no expxdev#130, DR-98).
afirma agente-runx-investigador-teste-temporario \
  "a regra do Bash do runx-investigador abre a escrita so para o teste temporario fora da arvore" \
  bash -c 'f="'"$R"'/.claude/agents/runx-investigador.md"; \
    grep -qF "mktemp -d /tmp/" "$f" \
    && grep -qiE "fora da arvore do projeto" "$f" \
    && grep -qiE "apagada no fim|apague a pasta" "$f" \
    && grep -qF "rev-parse --show-toplevel" "$f" \
    && grep -qF "Nenhum \`>\`, \`>>\`, \`tee\`, \`sed -i\`, \`patch\`" "$f"'

afirma agente-runx-investigador-por-evidencia \
  "runx-investigador abre so quando a causa nao esta demonstrada por evidencia local" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; \
    grep -qiE "evidência local.*causa|causa.*evidência local" "$f" \
    && ! grep -qE "3 \(tr[eê]s\)|tr[eê]s ou mais|>= ?3|3 ou mais" "$f"'

afirma agente-revisor-por-digest \
  "revisor roda uma vez no vermelho estavel e repete so com digest novo" \
  bash -c 'f="'"$S"'/references/03-fix.md"; grep -qi "vermelh.*estabiliz" "$f" \
    && grep -qi "uma vez" "$f" && grep -qi "digest" "$f"'

afirma agente-qa-por-lote-digest \
  "qa roda uma vez por lote E4 e repete somente apos correcao" \
  bash -c 'f="'"$S"'/references/04-qa.md"; grep -qi "uma vez.*lote\|lote.*uma vez" "$f" \
    && grep -qi "digest" "$f" && grep -qi "depois de.*correção\|após.*correção" "$f"'

afirma agente-exclusao-mutua \
  "runx-investigador, revisor e qa nunca ficam ativos simultaneamente" \
  bash -c 'grep -qiE "mutuamente exclusivos|nunca.*runx-investigador.*revisor.*qa" "'"$S"'/references/06-estado.md"'

afirma agente-sem-segunda-leitura \
  "digest inalterado suprime segunda leitura" \
  bash -c 'f="'"$S"'/references/06-estado.md"; grep -qi "digest" "$f" \
    && grep -qiE "segunda leitura.*suprim|sem mudança.*não.*revisor|inalterado.*não" "$f"'

echo "== classes de capacidade e marcos =="

afirma modelo-classes-canonicas \
  "politica declara as tres classes independentes de fornecedor" \
  bash -c 'f="'"$S"'/references/06-estado.md"; for c in mecanico_triagem raciocinio_normal profundo_excepcional; do \
    grep -q "$c" "$f" || exit 1; done'

afirma modelo-adaptadores-runtime \
  "Claude e Codex mapeiam classes sem model inherit" \
  bash -c 'f="'"$S"'/references/06-estado.md"; grep -q "Haiku" "$f" && grep -q "Sonnet" "$f" \
    && grep -q "Opus" "$f" && grep -q "Codex" "$f" && grep -q "low" "$f" && grep -q "medium" "$f" \
    && grep -q "high" "$f" && ! grep -q "model: inherit" "'"$R"'/.claude/agents/"*.md'

afirma modelo-profundo-com-justificativa \
  "classe profunda exige justificativa registrada" \
  bash -c 'grep -qiE "profundo_excepcional.*justific|justific.*profundo_excepcional" "'"$S"'/references/06-estado.md"'

afirma modelo-agentes-economicos \
  "agentes read-only fixam haiku ou sonnet conforme o papel" \
  bash -c 'grep -q "^model: sonnet$" "'"$R"'/.claude/agents/runx-investigador.md" \
    && grep -q "^model: haiku$" "'"$R"'/.claude/agents/runx-revisor-testes.md" \
    && grep -q "^model: sonnet$" "'"$R"'/.claude/agents/qa.md"'

afirma uso-limite-interrompe-agentes \
  "usage_limit_reached interrompe execucao e qualquer tentativa automatica" \
  bash -c 'grep -q "usage_limit_reached" "'"$S"'/SKILL.md" \
    && grep -qiE "tentativa automática|tentativa automatica" "'"$S"'/references/06-estado.md"'

afirma marco-quatro-classes \
  "estado, orquestrador e handoff mudam so em quatro classes de marco" \
  bash -c 'f="'"$S"'/references/06-estado.md"; grep -qi "quatro.*marco\|4.*marco" "$f" \
    && for p in "transição de estágio" bloqueio decisão término; do grep -Fqi "$p" "$f" || exit 1; done'

afirma marco-evento-mecanico-deterministico \
  "evento mecanico vai ao JSONL por script sem chamada de LLM" \
  bash -c 'f="'"$S"'/references/06-estado.md"; grep -qi "evento mecânico\|eventos mecânicos" "$f" \
    && grep -qi "JSONL" "$f" && grep -qi "sem chamada.*LLM" "$f"'

afirma e1-branch-nao-rastreia-a-base \
  "o comando do E1, como esta escrito, de uma subpasta, cria o worktree irmao e sem upstream (DR-90 e DR-92)" \
  bash -c '
    cmd="$(grep -o "git worktree add -b <branch>[^\`]*<base>" "'"$S"'/references/01-investigacao.md" | head -1)"
    [ -n "$cmd" ] || exit 1
    d="$(mktemp -d)"; trap "rm -rf \"\$d\"" EXIT
    git init -q --bare "$d/o.git"; git clone -q "$d/o.git" "$d/repo" 2>/dev/null; cd "$d/repo" || exit 1
    git -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m i || exit 1
    git -c push.gpgsign=false push -q origin HEAD:refs/heads/main || exit 1; git fetch -q || exit 1
    cmd="${cmd//<branch>/fix/x}"; cmd="${cmd//<repo>--<OC-ID>-<slug>/w}"; cmd="${cmd//<base>/origin/main}"
    mkdir -p sub/dir; ( cd sub/dir && eval "$cmd" >/dev/null 2>&1 ) || exit 1
    [ -d "$d/w" ] || exit 1
    git -C "$d/w" rev-parse --abbrev-ref "@{u}" >/dev/null 2>&1 && exit 1
    # De dentro de um worktree em outro lugar, a pasta nova nasce irma do checkout principal.
    mkdir "$d/longe"; git worktree add -q -b y --no-track "$d/longe/z" origin/main || exit 1
    cmd2="${cmd//fix\/x/fix/x2}"; cmd2="${cmd2//\/w\"//w2\"}"
    ( cd "$d/longe/z" && eval "$cmd2" >/dev/null 2>&1 ) || exit 1
    [ -d "$d/w2" ] && [ ! -e "$d/longe/w2" ]'

# DR-55 criou os dois eventos, e o rastro.py nunca os aceitou: o comando das referencias saia com rc 2.
for evento in diagrama_nao_gerado diagrama_nao_atualizado; do
  afirma "rastro-aceita-$evento" \
    "o rastro.py grava $evento, como as referencias mandam" \
    bash -c '
      d="$(mktemp -d)"; trap "rm -rf \"\$d\"" EXIT
      mkdir -p "$d/.claude" "$d/docs/manutencao/OC-2026-0001-sonda"
      cp -R "'"$R"'/.claude/hooks" "$d/.claude/hooks"
      printf -- "---\ntrabalho_id: OC-2026-0001\nstatus: em_andamento\n---\n" > "$d/docs/manutencao/OC-2026-0001-sonda/00-OCORRENCIA.md"
      cd "$d" && python3 .claude/hooks/comum/rastro.py --evento '"$evento"' --fase e3 --resultado falha --detalhe x \
        && grep -q "'"$evento"'" docs/eventos/*.jsonl'
done

afirma e1-registro-sem-pasta-antes-de-retomar \
  "no registro prunable, o E1 pergunta antes de remover: apagada sai, movida se repara (DR-92 e DR-93)" \
  bash -c 'f="'"$S"'/references/01-investigacao.md"; grep -q "\`git worktree remove \"<caminho>\"\` tira só esse registro" "$f" && grep -q "marca \`prunable\`" "$f" \
    && grep -q "pare e pergunte. Pasta movida: \`git worktree repair \"<novo caminho>\"\`, e retome lá, com esse caminho, relativo ao checkout principal, na chave \`worktree\`. Pasta apagada:" "$f"'

afirma e5-so-fecha-com-o-merge-provado \
  "o E5 prova o merge antes de gravar, para no rc 4, e commita sem tocar a ENTREGA (DR-94)" \
  bash -c 'f="'"$S"'/references/05-relatorio.md"
    p0="$(grep -n "^## Passo 0" "$f" | cut -d: -f1)"; p1="$(grep -n "^## Passo 1" "$f" | cut -d: -f1)"
    [ -n "$p0" ] && [ -n "$p1" ] && [ "$p0" -lt "$p1" ] || exit 1
    t="$(sed -n "${p0},${p1}p" "$f")"
    printf "%s\\n" "$t" | grep -qF "bash \"\$(git rev-parse --show-toplevel)/.claude/skills/mergex/scripts/fechamento-pos-merge.sh\" --trabalho <OC-ID>-<slug>" || exit 1
    printf "%s\\n" "$t" | grep -q "\\*\\*rc 4:\\*\\* o PR ainda não foi mesclado. PARE" || exit 1
    printf "%s\\n" "$t" | grep -q "nessa raiz, a instalação está incompleta: PARE" || exit 1
    grep -q "sem tocar \`ENTREGA.md\`" "$f" || exit 1
    grep -q "\`Fechamento-de: <pr>\` e \`Merge: <merge>\`" "$f" || exit 1
    grep -q "ou, sem prova e fora do rc 4, a pessoa decidiu fechar" "$f" || exit 1
    grep -q "nunca chame nem sugira o \`/mergex-revisar\`" "$f"'

afirma e1-worktree-movido-so-se-repara-antes-de-remover \
  "worktree movido volta com repair, e depois do remove ja nao volta (DR-93)" \
  bash -c '
    d="$(cd "$(mktemp -d)" && pwd -P)"; trap "rm -rf \"\$d\"" EXIT
    git init -q "$d/r"; git -C "$d/r" -c user.email=t@t -c user.name=t -c commit.gpgsign=false commit -q --allow-empty -m i || exit 1
    git -C "$d/r" worktree add -q -b a "$d/a" || exit 1
    mv "$d/a" "$d/a2"
    git -C "$d/r" worktree list --porcelain | grep -q "^prunable" || exit 1
    git -C "$d/r" worktree repair "$d/a2" >/dev/null 2>&1 || exit 1
    git -C "$d/r" worktree list --porcelain | grep -q "^prunable" && exit 1
    git -C "$d/r" worktree list --porcelain | grep -qx "worktree $d/a2" || exit 1
    git -C "$d/r" worktree add -q -b b "$d/b" || exit 1
    echo x > "$d/b/arquivo"; mv "$d/b" "$d/b2"
    git -C "$d/r" worktree remove "$d/b" || exit 1
    [ -f "$d/b2/arquivo" ] || exit 1
    ! git -C "$d/b2" status >/dev/null 2>&1'

afirma refs-sem-caminho-fixo-de-instalacao \
  "nenhuma referencia chama o rastro ou o estado so pelo caminho do install.sh" \
  bash -c '! grep -rn "python3 \.claude/runx-hooks/" "'"$S"'/references"'

afirma refs-todos-os-comandos-valem \
  "os 14 comandos, inclusive os de varias linhas, tem o prefixo inteiro, sintaxe valida e script existente" \
  python3 -c '
import re, subprocess, sys
from pathlib import Path
s = Path(sys.argv[1]); total = 0
PRE = "RX=\"$(git rev-parse --show-toplevel)\" || RX=.; H=\"$RX/.claude/runx-hooks\"; [ -f \"$H/comum/expx_rastro.py\" ] || H=\"$RX/.claude/hooks\"; python3 \"$H/comum/"
for ref in sorted((s / "references").glob("*.md")):
    linhas = ref.read_text(encoding="utf-8").split("\n")
    for i, l in enumerate(linhas):
        m = re.search(r"RX=\"\$\(git rev-parse --show-toplevel\)\".*", l)
        if not m: continue
        total += 1
        cmd = m.group(0).split("`")[0]
        j = i
        while cmd.rstrip().endswith("\\"):
            j += 1; cmd = cmd.rstrip()[:-1] + " " + linhas[j].strip()
        cmd = re.sub(r"<[^>]*>", "x", cmd)
        nome = re.search(r"\$H/comum/([a-z_]+\.py)", cmd)
        assert cmd.startswith(PRE) and nome, (ref.name, i + 1, cmd)
        assert (s.parent.parent / "hooks" / "comum" / nome.group(1)).is_file(), (ref.name, nome.group(1))
        r = subprocess.run(["bash", "-n", "-c", cmd], capture_output=True, text=True)
        assert r.returncode == 0, (ref.name, i + 1, r.stderr)
assert total == 14, total
' "$S"

# O comando escrito na referencia, executado como esta, nas duas formas de instalacao: o
# install.sh grava em .claude/runx-hooks, e o expx init, em .claude/hooks (DR-88).
afirma refs-pasta-incompleta-cai-no-outro-destino \
  "com .claude/runx-hooks sem a biblioteca, o comando usa .claude/hooks" \
  bash -c '
    cmd="$(grep -m1 -- "--evento task_iniciada" "'"$S"'/references/03-fix.md" | sed "s/^ *//; s/<T-NN.MM>/T-01.01/")"
    d="$(mktemp -d)"; trap "rm -rf \"\$d\"" EXIT
    mkdir -p "$d/.claude/runx-hooks" "$d/.claude/hooks" "$d/docs/manutencao/OC-2026-0001-sonda"
    cp -R "'"$R"'/.claude/hooks/comum" "$d/.claude/hooks/"
    printf -- "---\ntrabalho_id: OC-2026-0001\nstatus: em_andamento\n---\n" > "$d/docs/manutencao/OC-2026-0001-sonda/00-OCORRENCIA.md"
    cd "$d" && bash -c "$cmd" && grep -q "T-01.01" docs/eventos/*.jsonl'

for destino in runx-hooks hooks; do
  afirma "refs-comando-roda-em-$destino" \
    "o task_iniciada de 03-fix.md grava o rastro com os hooks em .claude/$destino" \
    bash -c '
      cmd="$(grep -m1 -- "--evento task_iniciada" "'"$S"'/references/03-fix.md" | sed "s/^ *//; s/<T-NN.MM>/T-01.01/")"
      d="$(mktemp -d)"; trap "rm -rf \"\$d\"" EXIT
      mkdir -p "$d/.claude/'"$destino"'" "$d/docs/manutencao/OC-2026-0001-sonda"
      cp -R "'"$R"'/.claude/hooks/comum" "$d/.claude/'"$destino"'/"
      printf -- "---\ntrabalho_id: OC-2026-0001\nstatus: em_andamento\n---\n" > "$d/docs/manutencao/OC-2026-0001-sonda/00-OCORRENCIA.md"
      cd "$d" && bash -c "$cmd" && grep -q "T-01.01" docs/eventos/*.jsonl'
done

# A sessao pode estar numa subpasta do projeto: o caminho dos hooks parte da raiz do Git, e
# fora de um repositorio cai na pasta atual, como antes (DR-97).
afirma refs-comando-roda-de-subpasta \
  "o task_iniciada de 03-fix.md grava o rastro chamado de uma subpasta do projeto" \
  bash -c '
    cmd="$(grep -m1 -- "--evento task_iniciada" "'"$S"'/references/03-fix.md" | sed "s/^ *//; s/<T-NN.MM>/T-01.01/")"
    d="$(cd "$(mktemp -d)" && pwd -P)"; trap "rm -rf \"\$d\"" EXIT
    git init -q "$d" || exit 1
    mkdir -p "$d/.claude/hooks" "$d/src/modulo" "$d/docs/manutencao/OC-2026-0001-sonda"
    cp -R "'"$R"'/.claude/hooks/comum" "$d/.claude/hooks/"
    printf -- "---\ntrabalho_id: OC-2026-0001\nstatus: em_andamento\n---\n" > "$d/docs/manutencao/OC-2026-0001-sonda/00-OCORRENCIA.md"
    cd "$d/src/modulo" && bash -c "$cmd" && grep -q "T-01.01" "$d"/docs/eventos/*.jsonl'

afirma refs-comando-roda-fora-de-git \
  "fora de um repositorio Git, o comando usa os hooks da pasta atual" \
  bash -c '
    cmd="$(grep -m1 -- "--evento task_iniciada" "'"$S"'/references/03-fix.md" | sed "s/^ *//; s/<T-NN.MM>/T-01.01/")"
    d="$(mktemp -d)"; trap "rm -rf \"\$d\"" EXIT
    mkdir -p "$d/.claude/hooks" "$d/docs/manutencao/OC-2026-0001-sonda"
    cp -R "'"$R"'/.claude/hooks/comum" "$d/.claude/hooks/"
    printf -- "---\ntrabalho_id: OC-2026-0001\nstatus: em_andamento\n---\n" > "$d/docs/manutencao/OC-2026-0001-sonda/00-OCORRENCIA.md"
    cd "$d" && GIT_CEILING_DIRECTORIES="$(dirname "$d")" bash -c "$cmd" && grep -q "T-01.01" docs/eventos/*.jsonl'

# O caminho da ocorrencia tambem parte da raiz: de uma subpasta, `docs/manutencao/...` relativo
# apontava para dentro dela, e o estado.py recusava (CodeAnt e CodeRabbit no runx#15).
afirma refs-estado-roda-de-subpasta \
  "o reconstruir de 06-estado.md acha a ocorrencia chamado de uma subpasta do projeto" \
  bash -c '
    cmd="$(grep -m1 -- "estado.py\" reconstruir" "'"$S"'/references/06-estado.md" | sed "s/^ *//; s/<OC-ID>-<slug>/OC-2026-0001-sonda/")"
    d="$(cd "$(mktemp -d)" && pwd -P)"; trap "rm -rf \"\$d\"" EXIT
    git init -q "$d" || exit 1
    mkdir -p "$d/.claude/hooks" "$d/src/modulo" "$d/docs/manutencao/OC-2026-0001-sonda"
    cp -R "'"$R"'/.claude/hooks/comum" "$d/.claude/hooks/"
    printf -- "---\ntrabalho_id: OC-2026-0001\nstatus: em_andamento\n---\n" > "$d/docs/manutencao/OC-2026-0001-sonda/00-OCORRENCIA.md"
    cd "$d/src/modulo" && bash -c "$cmd"'

# Instalada pelo expx init, a arvore e versionada no projeto, e um .pyc nela vira desvio no E1 (DR-89).
afirma hooks-nao-deixam-pyc \
  "o rastro, o estado e o despachante rodam sem criar __pycache__" \
  bash -c '
    d="$(mktemp -d)"; trap "rm -rf \"\$d\"" EXIT
    mkdir -p "$d/.claude" "$d/docs/manutencao/OC-2026-0001-sonda"
    cp -R "'"$R"'/.claude/hooks" "$d/.claude/hooks"; find "$d/.claude/hooks" -name __pycache__ -prune -exec rm -rf {} +
    printf -- "---\ntrabalho_id: OC-2026-0001\nstatus: em_andamento\n---\n" > "$d/docs/manutencao/OC-2026-0001-sonda/00-OCORRENCIA.md"
    cd "$d" || exit 1
    env -u PYTHONDONTWRITEBYTECODE python3 .claude/hooks/comum/rastro.py --evento task_iniciada --fase e3 --task T-01.01 || exit 1
    grep -q T-01.01 docs/eventos/*.jsonl || exit 1
    env -u PYTHONDONTWRITEBYTECODE python3 .claude/hooks/comum/estado.py reconstruir --ocorrencia docs/manutencao/OC-2026-0001-sonda >/dev/null 2>&1 || exit 1
    printf "{\"cwd\":\"%s\",\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"%s/x.py\"}}" "$d" "$d" \
      | env -u PYTHONDONTWRITEBYTECODE python3 .claude/hooks/comum/despachante.py runx/causa-antes-do-plano runx/escopo-da-ocorrencia runx/task-reivindicada >/dev/null 2>&1
    case $? in 0|2) ;; *) exit 1 ;; esac
    [ -z "$(find "$d/.claude/hooks" -name __pycache__ -o -name "*.pyc")" ]'

afirma hooks-todos-recusam-pyc \
  "todo ponto de entrada Python dos hooks liga dont_write_bytecode antes de importar a biblioteca" \
  python3 -c '
import sys
from pathlib import Path
raiz = Path(sys.argv[1]) / ".claude" / "hooks"
for f in list((raiz / "comum").glob("*.py")) + list((raiz / "runx").glob("*.py")):
    if f.name == "expx_rastro.py": continue
    t = f.read_text(encoding="utf-8"); i = t.find("sys.dont_write_bytecode = True")
    assert i >= 0, f.name
    j = t.find("import expx_rastro")
    assert j < 0 or i < j, f.name
' "$R"

echo "== classe da sessao principal (expx 0.13.22) =="
# A tripla que o `expx sessao <OC-ID>` le para imprimir o `claude --model ... --effort ...`: so o
# que quem chama a skill declarar, nunca inferida, nunca mudada depois (escopo (a) do desenho).
afirma classe-sessao-no-template "o template do 00-OCORRENCIA nasce com a tripla nula" \
  bash -c 'for k in classe_sessao classe_sessao_por classe_sessao_justificativa; do grep -qx "$k: null" "$1" || exit 1; done' _ "$S/assets/TEMPLATE-ocorrencia.md"
afirma classe-sessao-no-schema "o schema declara a tripla, o enum e quem declara" \
  bash -c 'f="$1"; grep -q "classe_sessao: null" "$f" && grep -q "mecanico_triagem.*raciocinio_normal.*profundo_excepcional" "$f" && grep -q "classe_sessao_por" "$f" && grep -qi "nunca é inferida" "$f"' _ "$S/references/00-schema.md"
afirma classe-sessao-so-declarada "o E1 grava a classe só quando quem chama a declara, e nunca a muda" \
  tem "$S/references/01-investigacao.md" "classe_sessao.*só quando quem chama a skill a declara"
afirma classe-sessao-no-handoff "o handoff do E1 leva a classe declarada (CodeRabbit no runx#20)" \
  tem "$S/references/01-investigacao.md" "relato literal completo\*\* e, quando foi declarada, a"

# Modo subagente (Conselhos, OC-2026-0011): os hooks seguem o `cwd` do payload, que `git -C`/`cd`
# no Bash nao mudam; os eventos caiam no checkout principal (bancada do ExpxDev 0.13.22).
afirma subagente-fora-da-worktree "o SKILL.md proíbe o subagente comum com a worktree diferente do cwd" \
  bash -c 'grep -q "subagente comum" "$1" && grep -q "git -C" "$1" && grep -q "expx sessao <OC-ID>" "$1"' _ "$S/SKILL.md"
# O subagente com isolation "worktree" do Claude Code adota a propria worktree (ExpxDev 0.13.26,
# CONTRATO-expx-orquestracao 15.1): criar outra a deixaria longe do cwd que os hooks recebem.
INV="$S/references/01-investigacao.md"
afirma subagente-isolado-consulta-o-nucleo "o E1 consulta o expx-worktree-isolada.sh antes de criar a worktree" \
  tem "$INV" 'S=\.expx/marketplace/plugins/expx/nucleo/scripts/expx-worktree-isolada\.sh; R=.*\[ -f "\$R/\$S" \] \|\| R=.*bash "\$R/\$S"` \(o script da árvore atual, senão o do checkout principal.*Sem ele nos dois lugares, com a raiz em `\.claude/worktrees/agent-<id>`, pare e diga.*Se ele imprime `isolada`, esta árvore é a worktree que o Claude Code criou para o subagente'
afirma subagente-isolado-troca-na-propria-arvore "isolada: troca de branch na própria worktree, com a árvore limpa, sem criar outra" \
  bash -c 'grep -qF "não crie outra, que ficaria longe do \`cwd\` que os hooks recebem" "$1" && grep -qF "\`git switch -c <branch> --no-track <base>\` se a branch não existe, \`git switch <branch>\` se ela existe e não está em worktree nenhuma" "$1" && grep -qF "Com a árvore limpa (\`git status --porcelain\` vazio; suja, pare e diga)" "$1"' _ "$INV"
afirma subagente-isolado-branch-ocupada-para "isolada com a branch em outro worktree vivo: para (a retomada é uma sessão lá)" \
  tem "$INV" 'num outro worktree vivo, pare e diga \(retome com uma sessão aberta lá, `expx sessao <OC-ID>`\)'
# o registro prunable (pasta movida ou apagada) segue a rota de sempre antes da troca (Codex, 2a rodada do item 3)
afirma subagente-isolado-prunable-antes-da-troca "isolada com a branch num worktree prunable: a rota de sempre, depois a troca" \
  tem "$INV" 'num worktree que o `git worktree list --porcelain` marca `prunable`, trate-o antes como diz o resto deste item \(pare e pergunte; pasta apagada: `git worktree remove "<caminho>"`, e troque aqui; pasta movida e reparada: ela está viva\)'
afirma subagente-isolado-grava-a-propria-worktree "o item 6 grava o caminho real do worktree da branch, inclusive na retomada na worktree do agente" \
  tem "$INV" 'grave em `worktree:` o caminho real do worktree em que a branch da ocorrência está, como o `git worktree list --porcelain` o lista, relativo ao checkout principal: .*`\.claude/worktrees/agent-<id>` na worktree de um subagente isolado, inclusive na retomada nela depois da troca de branch, quando o script já não imprime `isolada`'
# a retomada na worktree do agente, ja na branch da ocorrencia, gravava ../<repo>--<OC-ID>-<slug> (CodeAnt no katosmv/login#78)
afirma subagente-isolado-sem-lista-de-casos "o item 6 não enumera mais os caminhos sem a retomada" \
  bash -c '! grep -qF "ou, na adoção do subagente isolado, \`.claude/worktrees/agent-<id>\`)" "$1"' _ "$INV"
# a base informada (nivel 1 do passo 3 da mergex) nao e aceita, e nunca e trocada em silencio (CodeAnt no conselhos#312)
afirma e1-base-informada-para "a base que o pedido nomeia e não é a da ordem: a runx para e diz" \
  bash -c 'grep -qF "Se o pedido nomeia uma base" "$1" && grep -qF "a runx não abre ocorrência sobre base informada (o nível 1 do passo 3 do E0 da mergex)" "$1" && grep -qF "nunca troque a base pedida pela desta ordem em silêncio" "$1" && grep -qF "ou não existe (\`git rev-parse --verify --quiet <base>\`), pare e diga" "$1"' _ "$INV"
# a base da branch da ocorrencia nao pode ser a worktree-agent-<id> (CodeRabbit no runx#23)
afirma subagente-isolado-base-do-principal "na worktree do agente, a base vem da branch do checkout principal" \
  bash -c 'grep -qF "$2" "$1"' _ "$INV" 'Na worktree de um subagente isolado (item 2), a branch atual é a `worktree-agent-<id>`: no lugar dela vale a do checkout principal, `git -C "$(git worktree list --porcelain | sed -n '\''1s/^worktree //p'\'')" branch --show-current`, com o mesmo critério.'
afirma subagente-isolado-na-invariante "a invariante 14 nomeia a exceção do subagente isolado" \
  tem "$S/SKILL.md" 'O subagente com `isolation: "worktree"` do Claude Code é a exceção: ele adota a própria worktree no Passo 0\.b do E1'

echo "== revisao por task no E3 =="
# O lado da skill do contrato expx-revisao (desenho de 2026-10-18, 4.2): sem este
# passo, o E1 da mergex commitava a task sem a evidencia e, no modo obrigatoria,
# o commit seguinte so com ela era recusado (conselhos, OC-2026-0009).
FIX="$S/references/03-fix.md"
afirma revisao-chama-o-revisar "o 03-fix chama o revisar do núcleo com trabalho, task e arquivos" \
  tem "$FIX" 'expx-revisao\.mjs" revisar --trabalho "<OC-ID>" --task "<T-NN\.MM>"'
afirma revisao-entre-aceite-e-conclusao "a revisão vem depois do critério de aceite e antes de marcar concluída" \
  python3 -c '
import sys
t = open(sys.argv[1], encoding="utf-8").read()
a = t.find("Verifique **de fato** o `criterio_aceite`")
r = t.find("expx-revisao.mjs\" revisar")
c = t.find("Só então marque `status: concluida`")
assert 0 <= a < r < c, (a, r, c)
' "$FIX"
afirma revisao-modo-pelo-leitor "o modo vem do leitor do núcleo, e desligada pula o passo" \
  bash -c 'grep -q "expx-fatiamento.mjs\" --formato json" "$1" && grep -q "revisao_por_task.modo" "$1" && grep -qE "\`desligada\`.*pul" "$1"' _ "$FIX"
afirma revisao-quatro-saidas "as saídas 0, 1, 2 e 3 têm rota, e as classes de bloqueio do contrato aparecem" \
  bash -c 'for p in "Saída 0" "Saída 1" "Saída 2" "Saída 3" revisao_defeito revisao_contestada revisao_incompleta "Saída 64 ou 75"; do grep -q "$p" "$1" || exit 1; done' _ "$FIX"
afirma revisao-na-raiz "o revisar grava na raiz do repositório, de qualquer subpasta" \
  tem "$FIX" 'revisar --trabalho "<OC-ID>" --task "<T-NN\.MM>" --raiz "\$RAIZ" --arquivos "<arquivos'
# caminho com espaco sem aspas era dividido pelo shell e o revisar saia 64 (CodeAnt no katosmv/login#73)
# O leitor decide a presenca (lstat: pasta e link quebrado sao entrada invalida); o `[ -f ]`
# da skill era falso para os dois e pulava o leitor (CodeAnt no katosmv/login#73, r4518931484).
afirma revisao-leitor-roda-sempre "com o leitor instalado, ele roda sempre; sem ele, qualquer entrada é modo desconhecido" \
  tem "$FIX" 'if \[ -f "\$N/expx-fatiamento\.mjs" \]; then node "\$N/expx-fatiamento\.mjs" --formato json --raiz "\$RAIZ"$'
bloco_modo() { awk '/\*\*Primeiro, o modo\.\*\*/{p=1} p && /^ *```/{n++; if (n == 2) exit; next} p && n == 1 {sub(/^   /, ""); print}' "$1"; }
modo_em() { # modo_em <com-leitor|sem-leitor> <ausente|pasta|link|arquivo> -> stdout do bloco + "rc=<n>" + "leitor" se rodou
  local d; d="$(mktemp -d)"; git -C "$d" init -q
  local n="$d/.expx/marketplace/plugins/expx/nucleo/scripts"; mkdir -p "$n" "$d/.expx"
  [ "$1" = com-leitor ] && printf 'import { writeFileSync } from "node:fs"; writeFileSync(process.argv[1] + ".rodou", ""); process.exit(1);\n' > "$n/expx-fatiamento.mjs"
  case "$2" in pasta) mkdir "$d/.expx/fatiamento.json" ;; link) ln -s nao-existe "$d/.expx/fatiamento.json" ;; arquivo) echo '{}' > "$d/.expx/fatiamento.json" ;; esac
  (cd "$d" && bash -c "$(bloco_modo "$FIX")"; echo "rc=$?"; [ -e "$n/expx-fatiamento.mjs.rodou" ] && echo leitor)
  rm -rf "$d"
}
export -f bloco_modo modo_em; export FIX
afirma revisao-leitor-roda-com-pasta "pasta no lugar do fatiamento.json: o leitor roda (e falha)" \
  bash -c '[ "$(modo_em com-leitor pasta | tr "\n" " ")" = "rc=1 leitor " ]'
afirma revisao-leitor-roda-com-link-quebrado "link quebrado no lugar do fatiamento.json: o leitor roda" \
  bash -c '[ "$(modo_em com-leitor link | tr "\n" " ")" = "rc=1 leitor " ]'
afirma revisao-leitor-roda-sem-arquivo "sem fatiamento.json, o leitor roda e imprime o padrão" \
  bash -c '[ "$(modo_em com-leitor ausente | tr "\n" " ")" = "rc=1 leitor " ]'
afirma revisao-sem-leitor-com-pasta "sem o leitor, pasta no lugar do arquivo é modo desconhecido" \
  bash -c '[ "$(modo_em sem-leitor pasta | tr "\n" " ")" = "sem leitor rc=0 " ]'
afirma revisao-sem-leitor-com-link "sem o leitor, link quebrado é modo desconhecido" \
  bash -c '[ "$(modo_em sem-leitor link | tr "\n" " ")" = "sem leitor rc=0 " ]'
afirma revisao-sem-leitor-sem-arquivo "sem o leitor e sem entrada nenhuma, nada é impresso (vale o padrão)" \
  bash -c '[ "$(modo_em sem-leitor ausente | tr "\n" " ")" = "rc=0 " ]'
afirma passo-0b-derivados-ignorados "o Passo 0.b diz que os derivados ficam no exclude local" \
  tem "$S/references/01-investigacao.md" 'estado\.py.*info/exclude'
afirma revisao-evidencia-no-escopo "a evidência da revisão não é escopo estourado no E3 nem no E4" \
  bash -c 'grep -F "Nenhum arquivo fora da lista" "$1" | grep -qF "docs/entregas/<OC-ID>/revisao/" && \
    grep -F "Compare nos dois sentidos" -A3 "$2" | grep -qF "docs/entregas/<OC-ID>/revisao/"' _ "$FIX" "$S/references/04-qa.md"
# a CodeAnt fora escala para o Codex no proprio nucleo (0.14.0, decisao do Flavio: nao e parametro, e escala)
afirma revisao-saida-2-depois-da-escala "a saída 2 é a CodeAnt e o Codex fora; o agente nunca chama o Codex" \
  bash -c 'grep -qF "nem a CodeAnt nem o Codex revisaram" "$1" && grep -qF "o próprio núcleo já escalou para o Codex" "$1" && grep -qF "ou o que revisaram não vale porque um arquivo da task mudou durante a revisão" "$1" && grep -qF "você nunca chama o Codex" "$1" && grep -qF "Nunca rode \`codeant login\` nem \`codex login\`" "$1" && grep -qF "Com o núcleo 0.14.0 ou mais novo" "$1" && grep -qF "o resultado é o dele (saída 0 ou 1)" "$1" && grep -qF "com um núcleo anterior, a saída 2 é só a CodeAnt fora" "$1"' _ "$FIX"
afirma revisao-indisponivel-depois-de-achado-nao-fecha "a saída 2 numa nova tentativa, depois de um achado, não fecha a task" \
  tem "$FIX" 'Depois de uma saída 1, a saída 2 de uma nova tentativa não fecha a task'
afirma revisao-saida-sem-rota-e-indisponivel "127 e qualquer outra saída viram a saída 2" \
  tem "$FIX" 'Outra saída\*\* \(`127` sem o `node`, `70` erro interno do núcleo, ou a saída 1 sem a linha `<T-NN\.MM> achados`, por exemplo\): a revisão não rodou; trate como a saída 2\.'
# a excecao nao tratada saia 1, o codigo de achados (CodeAnt no katosmv/login#73): so a linha prova o achado
# o nucleo tambem deixa aberto o achado sem vinculo a uma linha da task (CodeAnt no conselhos#296)
afirma revisao-saida-1-sem-vinculo "a saída 1 cobre o achado sem vínculo a uma linha da task" \
  tem "$FIX" 'há achado aberto: em linha que a task alterou, ou sem vínculo a uma linha de um arquivo da task'
afirma revisao-saida-1-so-com-a-linha "a saída 1 só é achado com a última linha <T-NN.MM> achados" \
  tem "$FIX" '\*\*Saída 1\*\* com a última linha `<T-NN\.MM> achados`'
afirma revisao-nunca-rejeita "a skill nunca rejeita achado: só o desenvolvedor" \
  tem "$FIX" 'Só o desenvolvedor rejeita'
afirma revisao-no-detalhe-da-conclusao "o resultado vai no detalhe do task_concluida, sem evento novo" \
  tem "$FIX" 'evento task_concluida --fase e3 --task <T-NN\.MM> --detalhe "revisao: <resultado>"'
# revisar de novo depois do rejeitar reabriu o mesmo ponto com outra identidade (Login, ui-react-046, T-01.01)
afirma revisao-nao-repete-depois-do-rejeitar "depois de um rejeitar que sai ok, não se roda o revisar de novo" \
  tem "$FIX" 'Depois de um `rejeitar` do desenvolvedor que imprime `<T-NN\.MM> ok`, a revisão da task está feita: siga ao passo 9 sem rodar o `revisar` de novo'
# o arquivo que mudou entre o revisar e o rejeitar: o rejeitar gravava ok sobre o blob antigo (CodeAnt no katosmv/login#78)
afirma revisao-repete-so-com-arquivo-mudado "só revisa de novo quando um arquivo da task mudou depois do último revisar" \
  tem "$FIX" 'Só revise de novo se um arquivo da task mudou depois do último `revisar`\. Se ele mudou antes do `rejeitar`, o `rejeitar` recusa \(`evidencia desatualizada: <arquivo>`, saída 1, nada gravado\): rode o `revisar` de novo, não rejeite\.'
# o lock nao revisavel nao vai a CLI, que acusa "lock nao atualizado" (Login, ui-react-046)
afirma revisao-lock-falso-positivo "o lock não atualizado é falso positivo conhecido, contestado com o diff do lock" \
  bash -c 'grep -q "lock não foi atualizado" "$1" && grep -q "falso positivo conhecido" "$1" && grep -q "com o diff do lock" "$1"' _ "$FIX"
# o lock alterado noutra coisa nao prova nada (CodeRabbit no runx#22, CodeAnt no sprintx#75)
# e o diff sozinho tambem nao: o lock pode repetir a mudanca e manter a resolucao antiga (CodeAnt no expxdev#161)
afirma revisao-lock-com-a-mesma-mudanca "o diff do lock com a mudança do package.json e a instalação congelada passando; sem as duas, o achado é real" \
  tem "$FIX" 'mostrando nele a mesma mudança do `package\.json` \(a versão ou a dependência nova\), e com a instalação congelada do lockfile \(`npm ci` ou equivalente\) passando com ele\. Se o lock não traz a mudança, ou se a instalação congelada o recusa por não bater com o `package\.json`, o achado é real: corrija o lock na task\. Se ela falha por outro motivo \(rede, registro, script de instalação\), não há prova: registre a contestação com essa falha, e o desenvolvedor decide\.'
# a instalacao congelada troca as dependencias: os testes rodam de novo (CodeRabbit no runx#23)
afirma revisao-lock-roda-de-novo-os-testes "depois da instalação congelada, o subconjunto afetado roda de novo" \
  bash -c 'grep -qF "$2" "$1"' _ "$FIX" 'A instalação congelada troca as dependências instaladas pelas do lock: rode de novo o subconjunto afetado antes de concluir a task.'

printf '\n  %s ok, %s falhas\n' "$ok" "$falhou"
[ "$falhou" -eq 0 ]
