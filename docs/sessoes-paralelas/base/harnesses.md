# Área — Os três harnesses: Claude Code, OpenCode e MimoCode

Esta área existe porque a feature precisa funcionar nos três, e cada um liga a skill ao
trabalho por um mecanismo diferente. O que vale nos três é o texto da skill; o que só vale
em um é rede de proteção daquele um.

Fontes: binários instalados nesta máquina (Claude Code 2.1.261 via VS Code, OpenCode 1.18.29,
`@mimo-ai/cli` 0.1.14), o código-fonte dos dois últimos (`anomalyco/opencode` commit
`337fd144`; `XiaomiMiMo/MiMo-Code` commit `6203ea2`, ambos 2026-09-05) e as docs oficiais
(`opencode.ai/docs`, `mimo.mi.com/docs`). Levantado em 2026-09-06.

## 1. O que cada um lê do projeto

| | Claude Code | OpenCode | MimoCode |
|---|---|---|---|
| Skill (`SKILL.md`) | `.claude/skills/<n>/` | `.opencode/skills/<n>/` **e `.claude/skills/<n>/`** (`skill/index.ts:21-24`, `CLAUDE_EXTERNAL_DIR`) | `.mimocode/skills/<n>/` **e `.claude/skills/`, `.opencode/skills/`** (`EXTERNAL_DIRS`) |
| Comandos | `.claude/commands/*.md` | `.opencode/command(s)/*.md` | `.mimocode/commands/` **e `.claude/commands/`** (`claudeCommandDirectories`) |
| Agentes | `.claude/agents/*.md` | `.opencode/agent(s)/*.md` | `.mimocode/agent(s)/` **e `.claude/agent(s)/`** |
| Instruções | `CLAUDE.md` | `AGENTS.md`, senão `CLAUDE.md` | `AGENTS.md`, senão `CLAUDE.md` (`instruction.ts`) |
| `$ARGUMENTS` nos comandos | sim | sim | sim (fork do OpenCode) |

**MimoCode é fork do OpenCode** (README oficial, "Relationship to OpenCode"); o pacote
interno ainda se chama `packages/opencode/`. Tudo que vale para o formato de configuração do
OpenCode vale para o MimoCode com o prefixo `.mimocode/` no lugar de `.opencode/`.

Consequência para esta feature: **nada precisa ser copiado para `.mimocode/`** além da ponte
de hooks. Skill, comandos e agentes do `.claude/` já são lidos.

## 2. Como cada um deixa interceptar ferramentas

| | Claude Code | OpenCode | MimoCode |
|---|---|---|---|
| Mecanismo | `settings.json` → comando shell, JSON no stdin | plugin JS/TS em `.opencode/plugin(s)/*.{js,ts}` ou `~/.config/opencode/plugins/` | idem em `.mimocode/{plugin,plugins}/` **ou file hook em `.mimocode/{hook,hooks}/*.{js,ts}`** (hot-reload) |
| Antes da ferramenta | `PreToolUse` | `"tool.execute.before"(input:{tool, sessionID, callID}, output:{args})` | igual, mais `output.cancel` / `cancelReason` |
| Depois | `PostToolUse` | `"tool.execute.after"(input:{tool, sessionID, callID, args}, output:{title, output, metadata})` | igual |
| Bloquear | exit 2 | `throw new Error(msg)` — vira `status: "error"` e o texto volta ao modelo (`session/processor.ts:190-199`) | `output.cancel = true` (documentado); `throw` também, por herança |
| Avisar sem bloquear | stderr + exit 0 | **não existe no `before`**; no `after`, mutar `output.output` (é o que o modelo lê) | idem |
| Nome dos argumentos | `file_path`, `content`, `old_string`, `new_string`, `command` | `filePath`, `content`, `oldString`, `newString`, `command` (camelCase) | idem |
| Antes de `bash` | `PreToolUse` com matcher `Bash` | `tool.execute.before` com `input.tool === "bash"` | idem |
| Dir do projeto | `cwd` no payload | `directory` e `worktree` no `PluginInput` | idem |
| Ambiente do shell | herda; exporta `CLAUDECODE`, `CLAUDE_CODE_SESSION_ID`, `CLAUDE_PID` | hook `shell.env(input:{cwd}, output:{env})` injeta variáveis | hook `shell.env(input:{cwd, sessionID?}, output:{env})` |
| Assinatura | — | `export const Plugin = async ({project, client, $, directory, worktree}) => ({ ...hooks })` | igual |

O OpenCode aceita tanto `plugin/` quanto `plugins/` (`config/plugin.ts:21`); as docs só
documentam `plugins/`. O MimoCode aceita `hook/`, `hooks/`, `plugin/`, `plugins/`.

**Um único arquivo JS pode servir aos dois**: mesma assinatura, mesmos nomes de evento,
mesmos nomes de argumento. O que muda é a pasta de instalação e o nome do harness.

## 3. Restrição de ferramentas nos agentes

| | Claude Code | OpenCode | MimoCode |
|---|---|---|---|
| Só leitura | `tools: Read, Glob, Grep, Bash` no frontmatter | `permission: { edit: deny, bash: deny }` (`tools:` está deprecated) | `tool_allowlist` ou `permission` |

Os três agentes do runx (`runx-investigador`, `runx-revisor-testes`, `qa`) já são lidos pelos três
harnesses a partir de `.claude/agents/`. A tradução do campo de restrição não é desta
feature: ela não muda os agentes.

## 4. Identidade de sessão

| | Claude Code | OpenCode | MimoCode |
|---|---|---|---|
| No payload do hook | `session_id` | `input.sessionID` em `tool.execute.*` | idem |
| No ambiente do shell | `CLAUDE_CODE_SESSION_ID` (medido) | **não exporta** (`bash.ts` monta o env sem id) | **não exporta** (`bash.ts:957-995`) |
| Como injetar | não precisa | hook `shell.env` | hook `shell.env` |
| Processo pai do shell | binário `claude` (medido: `CLAUDE_PID`) | binário `opencode` | binário `mimo` |

O caminho universal, sem cooperação de nenhum harness, é a **ancestralidade de processo**:
o shell da ferramenta é filho direto do processo do harness, cujo nome de executável
identifica a ferramenta e cujo pid identifica a sessão. Medido no Claude Code:
`zsh(pid 70979) → claude(pid 66506 = CLAUDE_PID) → Code Helper`.

## 5. Worktree por sessão, nativo

| | Claude Code | OpenCode | MimoCode |
|---|---|---|---|
| Existe | ferramenta `EnterWorktree` (cria em `.claude/worktrees/<nome>`; ou entra em caminho existente listado em `git worktree list`) e `ExitWorktree` | serviço experimental (`OPENCODE_EXPERIMENTAL_WORKSPACES`), rotas `/experimental/worktree`, usado pelo app desktop; sem flag de CLI | `/worktree` (`/wt`) na TUI; auto-worktree ao detectar conflito (outra sessão no mesmo dir, `index.lock`, processo de Claude Code/Codex/Cursor); `agent(..., {isolation: "worktree"})` em workflows |
| Onde cria | `.claude/worktrees/` dentro do repo | `~/.local/share/opencode/worktree/<projectID>/` | `<data>/worktree/<project-id>/<name>`, branch `mimocode/<slug>` |

Três lugares, três convenções de nome de branch, nenhuma delas a do mergex
(`fix/<OC-ID>-<slug>`). Um worktree que o runx crie **fora** dessas pastas é entrável pelos
três: o Claude Code aceita `EnterWorktree` com `path` de qualquer worktree registrado
("on first entry from the launch directory"); OpenCode e MimoCode são abertos apontando o
diretório (`opencode <dir>`, `mimo <dir>`).

Nota sobre worktree **dentro** do repositório (o padrão do Claude Code): o diretório aninhado
contém uma cópia inteira do projeto; runners que varrem a árvore (jest, vitest, pytest)
encontram cada teste duas vezes, e o `grep` do E1 encontra cada arquivo duas vezes. É por isso
que o runx escolhe o diretório irmão (D-02).

## 6. O que o `install.sh` faz hoje (evidência)

Linhas 15-16: "Hooks e agentes só vão para o Claude Code: o OpenCode tem sistema próprio".
Flags: `--claude`, `--opencode`, `--global`, `--force`, `--dry-run`, `--sem-hooks`. Não há
`--mimocode` e nada é instalado em `.opencode/plugins/` nem em `.mimocode/`.

## 7. Riscos desta área para o plano

| Risco | Severidade | Onde é tratado |
|---|---|---|
| A ponte JS ser carregada por um harness e não pelo outro por diferença de pasta | MÉDIA | D-15: instalador grava nas duas pastas documentadas; L-06 pede verificação manual |
| `tool.execute.after` não trazer o código de saída do bash em `metadata` | BAIXA | `rastro-suite` já tolera ausência (`nao_determinado`); L-03 |
| Aviso do `before` não ter canal no OpenCode/MimoCode | BAIXA | D-14: a ponte guarda o aviso por `callID` e o anexa em `output.output` no `after` |
