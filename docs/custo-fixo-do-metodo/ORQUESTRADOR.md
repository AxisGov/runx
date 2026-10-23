---
expx_schema: 1
expx_tool: sprintx
kind: orquestrador
trabalho_id: custo-fixo-do-metodo
titulo: Reducao do custo fixo do metodo runx
tipo_trabalho: feature
tipo_ocorrencia: null
estagio: f6
status: concluido
criado_em: 2026-09-02
atualizado_em: 2026-09-02
concluido_em: 2026-09-02
sprints: [sprint-01, sprint-02]
caminho_critico: [T-01.01, T-02.01, T-02.02, T-02.03, T-02.08, T-02.09]
---

# ORQUESTRADOR — custo-fixo-do-metodo

## 1. Objetivo

Reduzir o custo fixo do método runx em três frentes: um plano condensado em arquivo único
quando há 1 sprint e 1 fase, a suíte parcial por task com a completa no portão do E4, e a
delegação ao runx-investigador só quando o grep devolve 3 ou mais arquivos. Nenhuma regra
inviolável muda; continuam 15.

## 2. Mapa e ordem de leitura

1. `ORQUESTRADOR.md` — este arquivo
2. `00-DECISOES.md` — as 15 decisões que fecham o desenho
3. `base/00-INDICE.md` — e os 4 arquivos de área que ele lista
4. `base/00-LACUNAS.md` — 5 lacunas, nenhuma bloqueante
5. `sprint-01/sprint.md` → `fases.md` → `tasks.md`
6. `sprint-02/sprint.md` → `fases.md` → `tasks.md`
7. `00-BLOQUEIOS.md` — vazio no início

## 3. Rota de execução

```
sprint-01  capacidade de testar
  F-01.1   T-01.01 ∥ T-01.02        (paralelas: arquivos disjuntos)

  ── portão real: sem os verificadores não há TDD nas tasks de markdown ──

sprint-02  as três melhorias
  F-02.1 ∥ F-02.2 ∥ F-02.3          (fases paralelas)
    F-02.1  T-02.01 → T-02.02 → T-02.03
    F-02.2  T-02.04 → T-02.05
            T-02.04 → T-02.06
    F-02.3  T-02.07                  (única task realmente paralelizável)
  F-02.4   T-02.08 → T-02.09         (depende de todas as anteriores)
```

**Caminho crítico:** `T-01.01 → T-02.01 → T-02.02 → T-02.03 → T-02.08 → T-02.09`

**Atenção ao paralelismo declarado:** as fases F-02.1, F-02.2 e F-02.3 são paralelas, mas
dentro delas quase toda task é `paralelizavel: false`, porque T-02.01 e T-02.04 tocam ambas
o `00-schema.md`, e T-02.03 e T-02.05 tocam ambas o `SKILL.md`. A única task com
`paralelizavel: true` na sprint-02 é a T-02.07.

## 4. Ferramentas

| Ferramenta | Comando |
|---|---|
| Suíte de hooks (existente) | `bash .claude/hooks/testes/testar.sh` |
| Falsos positivos (existente) | `bash .claude/hooks/testes/testar-falsos-positivos.sh` |
| Verificador de conteúdo (criado na T-01.01) | `bash .claude/hooks/testes/testar-conteudo.sh` |
| Espelhamento (criado na T-01.02) | `bash .claude/hooks/testes/testar-espelho.sh` |
| Lint | NÃO EXISTE NO PROJETO |
| Type check | NÃO EXISTE NO PROJETO |
| Diagnóstico dos hooks | `python3 .claude/hooks/comum/doctor.py` |

**Segredos:** nenhum. A feature altera markdown de skill e scripts shell/Python locais.
Nenhuma variável de ambiente nova.

**Nota de caminho:** os references da runx documentam `.claude/runx-hooks/comum/rastro.py`,
que é o caminho no ambiente **instalado**. Neste repositório os scripts vivem em
`.claude/hooks/comum/`. É correto por desenho (`base/arvores-espelhadas.md` §4, lacuna
L-04) — não "corrija".

## 5. Agentes

Três papéis, assumidos em sequência pelo mesmo agente quando não houver outros:

- **Implementador** — escreve o teste da task e depois o conteúdo (markdown ou script).
- **Revisor de testes** — responde: essa asserção passaria com o markdown errado? Uma
  asserção que só faz `grep` de uma palavra comum não discrimina; ela precisa casar a
  estrutura que a task exige.
- **Auditor de aceite** — confere o `criterio_aceite` da task de fato, rodando o comando,
  antes de marcar `concluida`.

## 6. Regras de autonomia

1. Não perguntar nada durante a execução; não pedir autorização.
2. Teste antes do conteúdo: a asserção é escrita e tem que **falhar** antes da edição.
3. Dúvida nova → registrar em `00-BLOQUEIOS.md`, pular a task, seguir para a próxima
   cujas dependências estão satisfeitas. Nunca parar para esperar.
4. Critério de aceite não atendido = task não avança. Não existe "concluído com ressalva".
5. Escopo travado: não tocar arquivo fora do `arquivos` das tasks.
6. Atualizar `status` em `tasks.md` — frontmatter **e** prosa — a cada transição.
7. Espelhar em `.opencode/` é a T-02.08, não um passo avulso a fazer no meio.

## 7. Definição de pronto global

- [ ] `bash .claude/hooks/testes/testar.sh` sai com **0 falhas** (56 casos + os novos).
- [ ] `bash .claude/hooks/testes/testar-falsos-positivos.sh` continua passando.
- [ ] `bash .claude/hooks/testes/testar-conteudo.sh` sai **0**.
- [ ] `bash .claude/hooks/testes/testar-espelho.sh` sai **0**.
- [ ] `diff -rq .claude/skills/runx .opencode/skills/runx` não reporta diferença.
- [ ] As 15 regras invioláveis continuam sendo 15 (D-13).
- [ ] Nenhum `{{marcador}}` vazado em arquivo de instrução (DR-14).
- [ ] Commit e push no `main`.

## 8. Como retomar uma sessão interrompida

1. Leia este arquivo inteiro.
2. Leia o `status` de cada task em `sprint-01/tasks.md` e `sprint-02/tasks.md`.
3. Leia `00-BLOQUEIOS.md`.
4. Continue da primeira task `pendente` ou `em_andamento` cujas dependências estão todas
   `concluida`, seguindo a rota da seção 3.
