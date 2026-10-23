# Área — Hooks, despachante e rastro

Esta área existe porque a rede de proteção do runx é um conjunto de scripts Python ligados
ao harness por um contrato de stdin/exit code. É esse contrato que uma ponte para outro
harness precisa reproduzir, e é o rastro que vai carregar a identidade da sessão.

## 1. O que é e onde vive

- `.claude/hooks/hooks.json` — registro: quais hooks rodam em qual evento, por matcher
- `.claude/hooks/comum/despachante.py` — roda N hooks em um processo, lendo o stdin uma vez
- `.claude/hooks/comum/expx_rastro.py` — biblioteca comum: raiz, frontmatter, rastro, modo
- `.claude/hooks/comum/rastro.py` — CLI para eventos que hook não vê (transições, vereditos)
- `.claude/hooks/comum/rastro-arquivo.py`, `rastro-suite.py` — `PostToolUse`
- `.claude/hooks/comum/doctor.py` — tabela `HOOKS` com o modo de nascimento de cada um
- `.claude/hooks/runx/*.py` — os cinco hooks de método
- `.claude/hooks/hooks.exemplo.json` — exemplo de `.expx/hooks.json` (modo por hook)

## 2. Contrato de entrada (o que a ponte precisa reproduzir)

Cada hook lê **um JSON no stdin**, no formato do harness Claude Code:

| Chave | Usada por |
|---|---|
| `tool_name` | não consultada pelos hooks de método (o matcher já filtrou) |
| `tool_input.file_path` | `caminho_da_ferramenta()`, todos os hooks de escrita |
| `tool_input.content` | `task-so-fecha-verde` (conteúdo proposto no `Write`) |
| `tool_input.old_string`, `new_string`, `replace_all` | `task-so-fecha-verde` (reconstrói o `Edit`) |
| `tool_input.command` | `rastro-suite` (regex `SUITE`) |
| `tool_response.exit_code` \| `exitCode` \| `returncode` \| `code` \| `interrupted` | `rastro-suite` — sem nenhum, grava `nao_determinado` |
| `session_id` | **ninguém, hoje** |

## 3. Contrato de saída

- exit 0 = permite; stderr não vazio = aviso, mostrado ao modelo e registrado como `regra_violada`;
- exit 2 = bloqueia; a mensagem no stderr volta ao modelo; registrado como `acao_bloqueada`;
- hook de método falha **aberta** (exceção → 0); `segredo-no-commit` falha fechada.

O despachante preserva isso: o primeiro hook que sair com 2 encerra com 2; avisos são
concatenados no stderr e o processo sai 0.

## 4. Registro em `hooks.json` (evidência)

| Evento | Matcher | Hooks, na ordem |
|---|---|---|
| `PreToolUse` | `Write\|Edit` | `comum/segredo-no-commit`, `runx/causa-antes-do-plano`, `runx/regressao-antes-do-fix`, `runx/task-so-fecha-verde`, `runx/escopo-da-ocorrencia` |
| `PostToolUse` | `Write\|Edit` | `comum/rastro-arquivo`, `runx/sem-jargao-no-uso` |
| `PostToolUse` | `Bash` | `comum/rastro-suite` |

**Não existe `PreToolUse` em `Bash`.** Nenhum hook roda antes de um comando; o portão de
árvore limpa antes da suíte precisa criar esse grupo.

O `install.sh` (linhas 119-160) reescreve os mesmos grupos no `settings.json` do destino,
com caminho absoluto, mesclando com o que já existe.

## 5. O rastro (evidência)

`grava()` escreve uma linha JSON com exatamente estas chaves, nesta ordem:
`ts, expx_eventos, trabalho_id, ferramenta, origem, evento, fase, task, agente, resultado, detalhe, arquivos`.

`rastro.py` aceita `--evento` (vocabulário fechado de 14 nomes, entre eles `task_iniciada`,
`task_concluida`, `task_bloqueada`, `suite_executada`), `--agente`, `--trabalho`, `--fase`,
`--task`, `--resultado`, `--detalhe`, `--arquivos`.

**Quem emite `task_iniciada` hoje: ninguém.** `grep -n task_iniciada` em
`.claude/skills/runx/references/03-fix.md` não devolve nada; o E3 grava `veredito_emitido`
(runx-revisor-testes) e `diagrama_nao_atualizado`. `rastro-arquivo.py` grava `arquivo_alterado`
com a task aberta lida do `tasks.md`, não do rastro. Uma reivindicação de task baseada no
rastro precisa, antes, que o E3 passe a emitir o evento.

## 6. O que o consumidor do rastro aceita (evidência — expxdev 0.5.2)

`dist/parser/esquema/evento.js` do pacote `expxdev` instalado em `~/.npm/_npx/`:

- `LinhaEvento` é `z.object({...}).passthrough()`: **chave extra não é rejeitada**;
- `EXTRAS_EVENTO = ["hook", "faixa"]` são as extras declaradas no contrato canônico;
- `chavesDesconhecidas()` reporta as demais como **aviso** do `doctor`
  (`rastro-chave-nao-declarada`: "chave extra é permitida, mas precisa ser declarada em
  CONTRATO-expx-eventos.md e vir depois das doze obrigatórias");
- `Agente` é enum fechado (9 valores); `EventoNome` é enum fechado (14 valores);
  `origem` ∈ {`hook`, `skill`, `agente`}.

Conclusão: gravar `sessao` e `harness` **depois das doze chaves** é aceito pelo painel e
gera um aviso do doctor até o contrato canônico (repositório do expxdev) as declarar. O
comentário do próprio parser justifica a escolha: "espremer a informação em `detalhe` perde
o dado para sempre".

## 7. `rastro-suite` — o que ele sabe da árvore (evidência)

Reage ao regex `SUITE` sobre `tool_input.command`; grava `suite_executada` com
`detalhe: "suite <verde|vermelha|nao_determinado>: <comando>"`. **Não registra o `HEAD` nem
arquivos sujos.** Uma suíte vermelha por contaminação de outra sessão fica indistinguível de
uma vermelha de verdade.

## 8. Suíte de testes dos hooks (evidência)

`testar.sh` monta `$W` com `mkdir -p "$W/.git"` — um **diretório vazio chamado `.git`**, não
um repositório. Serve para `raiz_repo()` e para nada mais: nenhum hook hoje chama `git`, e
por isso a fixture nunca precisou de um. Hook que consulte `git status` ou `git worktree`
precisa de repositório real na fixture (T-01.01).

## 9. Riscos desta área para o plano

| Risco | Severidade | Onde é tratado |
|---|---|---|
| A ponte JS traduzir o payload errado e os hooks falharem abertos sem ninguém ver | ALTA | T-01.03 testa a ponte contra um despachante falso, com o JSON exato conferido |
| Chaves extras no rastro gerarem aviso do doctor | BAIXA | D-10 (declarar no contrato canônico é lacuna L-01) |
| `task_iniciada` não emitido em algum harness → reivindicação cega | MÉDIA | D-08: o hook só avisa; ausência de evento nunca bloqueia |
