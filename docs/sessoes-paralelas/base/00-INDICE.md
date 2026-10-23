---
expx_schema: 1
expx_tool: sprintx
kind: base_indice
trabalho_id: sessoes-paralelas
atualizado_em: 2026-09-06
areas:
  - arquivo: deteccao-e-raiz.md
    titulo: Deteccao da ocorrencia atual e ancoragem da raiz
    lacunas: 1
  - arquivo: hooks-e-rastro.md
    titulo: Hooks, despachante e rastro
    lacunas: 2
  - arquivo: suite-e-qa.md
    titulo: A suite no E3 e no E4
    lacunas: 1
  - arquivo: harnesses.md
    titulo: Os tres harnesses - Claude Code, OpenCode e MimoCode
    lacunas: 3
  - arquivo: git-worktree-e-mergex.md
    titulo: git worktree e a abertura de branch da mergex
    lacunas: 1
  - arquivo: testes-existentes.md
    titulo: Suites de teste do repositorio
    lacunas: 1
---

# Índice da base

Base de conhecimento da feature `sessoes-paralelas`: fazer o runx funcionar quando várias
sessões, de harnesses diferentes (Claude Code, OpenCode, MimoCode), trabalham ao mesmo tempo
no mesmo projeto — sem stash de uma levar o trabalho da outra, sem versão antiga voltando,
sem suíte inteira reprovando por trabalho alheio.

| Arquivo | Resumo |
|---|---|
| [deteccao-e-raiz.md](deteccao-e-raiz.md) | Como o runx decide qual é "a ocorrência atual" (mtime do ORQUESTRADOR) e onde ancora a raiz (`.git` **diretório**). Prova de bancada de que `raiz_repo` falha em worktree. O que o ambiente oferece de identidade de sessão. |
| [hooks-e-rastro.md](hooks-e-rastro.md) | O contrato stdin/exit code que a ponte JS precisa reproduzir; o registro em `hooks.json` (não há `PreToolUse` em `Bash`); as doze chaves do rastro; o parser do expxdev é `passthrough` e o doctor só avisa; ninguém emite `task_iniciada` hoje. |
| [suite-e-qa.md](suite-e-qa.md) | O E4 roda a suíte inteira sem olhar o estado da árvore; um arquivo sujo de outra ocorrência vira "escopo estourado" e REPROVADO falso, poluindo a contagem de voltas ao E3. |
| [harnesses.md](harnesses.md) | Matriz dos três harnesses: o que leem de `.claude/`, como interceptam ferramentas, identidade de sessão, worktree nativo. MimoCode é fork do OpenCode e lê `.claude/skills`, `.claude/commands` e `.claude/agents`. |
| [git-worktree-e-mergex.md](git-worktree-e-mergex.md) | Bancada: stash e não rastreados não atravessam worktrees; `.expx/` e `.env` não nascem lá. Regra de nome e base de branch da mergex, que o worktree precisa copiar. `EnterWorktree` aceita `path`. |
| [testes-existentes.md](testes-existentes.md) | Linha de base 2026-09-06: 59 / 38 / 20 / 2 casos verdes. A fixture de `testar.sh` não é um repositório git. |

## O que o histórico já sabia

Não há `memox` instalada neste repositório. Pelo versionador: `git log --oneline -1` devolve
`f2f7916 Reduz o custo fixo do metodo: andaime condensado, suite parcial e runx-investigador por
evidencia`, árvore limpa. O plano anterior (`docs/custo-fixo-do-metodo/`) tocou `03-fix.md`,
`04-qa.md`, `00-schema.md` e `task-so-fecha-verde.py` — os mesmos arquivos que este plano
volta a tocar. Nenhum trabalho anterior tratou sessões paralelas, worktree ou identidade de
sessão.

## Nota sobre o alcance da mudança

Os kinds `orquestrador`, `sprint`, `fases`, `tasks` e `bloqueios` são **compartilhados com a
sprintx** e não ganham campo nesta feature. Tudo que precisa de campo novo vai para kinds
exclusivos da runx (`ocorrencia`) ou para o rastro (extras depois das doze chaves). O
`ORQUESTRADOR.md` recebe a área de trabalho **na prosa**, como a mergex já faz com a branch.
