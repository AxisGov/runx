---
expx_schema: 1
expx_tool: sprintx
kind: sprint
trabalho_id: custo-fixo-do-metodo
sprint_id: sprint-02
titulo: As tres melhorias de custo fixo
status: concluido
criterio_saida: testar-conteudo.sh sai 0, testar-espelho.sh sai 0 e testar.sh continua em 0 falhas
fases: [F-02.1, F-02.2, F-02.3, F-02.4]
riscos: [Renomear ou mover o arquivo de tasks desligaria 4 hooks em silencio, todos falham abertos]
atualizado_em: 2026-09-02
---

# Sprint 02 — As três melhorias de custo fixo

## Objetivo

Implementar as três melhorias na skill runx: o andaime condensado (D-01 a D-05), a suíte
parcial por task (D-06 a D-08) e o acionamento do runx-investigador por evidência (D-09, D-10).
Cada uma é uma fase independente; a fase de fechamento espelha tudo para `.opencode/`.

## Fases

| Fase | Título | Roda em paralelo com |
|---|---|---|
| F-02.1 | Andaime condensado | F-02.2, F-02.3 |
| F-02.2 | Suíte parcial por task | F-02.1, F-02.3 |
| F-02.3 | Investigador por evidência | F-02.1, F-02.2 |
| F-02.4 | Espelhamento e fechamento | nenhuma |

Detalhe de cada fase em `fases.md`; tasks em `tasks.md`.

## Critério de saída

`bash .claude/hooks/testes/testar-conteudo.sh` sai 0; `bash .claude/hooks/testes/testar-espelho.sh`
sai 0; `bash .claude/hooks/testes/testar.sh` continua com 0 falhas (era 56 ok antes da mudança,
e ganha casos novos nesta sprint).

## Riscos conhecidos

- **Renomear ou mover o arquivo de tasks desligaria 4 hooks em silêncio** — todos falham
  abertos (`base/acoplamento-hooks.md` §9). Mitigado por D-02: o condensado é gravado
  exatamente em `sprint-NN/tasks.md`.
- **Múltiplos blocos YAML seriam invisíveis ao parser** — mitigado por D-04: bloco único.
- **`task-so-fecha-verde` barraria toda conclusão sob a regra nova** — mitigado por D-08.

## Fora de escopo

- A skill `sprintx` — D-15.
- O formato de três arquivos para planos multi-sprint: continua válido e não é removido (D-05).
- Correção do caminho `.claude/runx-hooks/` nos references: é correto por desenho (lacuna L-04).
- Criação de CI (lacuna L-02): não pedido nesta entrega.
