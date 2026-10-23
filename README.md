<div align="center">

<img alt="runx — a metade Run do método Expx: cinco estágios, da investigação ao relatório" src=".github/assets/anim/hero.svg" width="100%">

<p>
  <img alt="harness: Claude Code" src="https://raw.githubusercontent.com/AxisGov/runx/main/.github/assets/badge-claude.svg">
  <img alt="harness: OpenCode" src="https://raw.githubusercontent.com/AxisGov/runx/main/.github/assets/badge-opencode.svg">
  <img alt="TDD obrigatorio" src="https://raw.githubusercontent.com/AxisGov/runx/main/.github/assets/badge-tdd.svg">
  <img alt="schema expx v1" src="https://raw.githubusercontent.com/AxisGov/runx/main/.github/assets/badge-schema.svg">
  <img alt="docs pt-BR" src="https://raw.githubusercontent.com/AxisGov/runx/main/.github/assets/badge-lang.svg">
  <img alt="licenca MIT" src="https://raw.githubusercontent.com/AxisGov/runx/main/.github/assets/badge-license.svg">
</p>

<p>
  <a href="https://github.com/AxisGov/runx#readme"><strong>📘 Documentação do método</strong></a>
  &nbsp;·&nbsp;
  <a href="#os-cinco-estágios">Estágios E1–E5</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/AxisGov/expxdev#o-ecossistema">O ecossistema</a>
  &nbsp;·&nbsp;
  <a href="https://github.com/AxisGov/expxdev#os-dois-contratos-compartilhados">Contratos</a>
</p>

<strong>A metade Run do método Expx</strong> — a skill de sustentação e manutenção<br>
de sistemas em produção para <a href="https://claude.com/claude-code">Claude Code</a> e <a href="https://opencode.ai">OpenCode</a>.

</div>

`runx` pega um chamado que chegou na mão do desenvolvedor e o leva até o fechamento com relatórios gravados, passando por cinco estágios obrigatórios: investigação com base de conhecimento, plano em sprints/fases/tasks, implementação sob TDD, QA independente e relatórios de encerramento.

> **Não se corrige o que não se entendeu, e não se planeja o que não se mapeou.**
> Primeiro a base do que será tocado, depois a causa, depois o plano, depois o código. O escopo fica travado no que a investigação provou: o que não está lá não é tocado.

<picture>
  <img alt="Demonstração: o relato do cliente entra e a runx o leva pelos cinco estágios até os dois relatórios" src=".github/assets/anim/demo-terminal.svg" width="100%">
</picture>

---

## O ecossistema Expx

O método Expx é um conjunto de skills que se compõem, instaladas e mantidas pelo CLI [`expxdev`](https://github.com/AxisGov/expxdev).

<picture>
  <img alt="O ecossistema Expx: a prodx decide se há trabalho, a runx decide como, as camadas modificam o comportamento e a mergex entrega" src=".github/assets/anim/ecossistema.svg" width="100%">
</picture>

| Peça | Papel | Relação com a `runx` |
|---|---|---|
| **[expxdev](https://github.com/AxisGov/expxdev)** | o CLI: instala, atualiza e diagnostica o ecossistema, e sobe o painel de operação | é quem instala esta skill (`npx expxdev init`) |
| **[sprintx](https://github.com/AxisGov/sprintx)** | **Build** — feature nova, F1…F6 | skill irmã; mesmos contratos, gatilho diferente |
| **runx** *(este repositório)* | **Run** — ocorrência em produção, E1…E5 | — |
| **[legadox](https://github.com/bittencourtthulio/legadox)** | **camada** de segurança para código legado | endurece os estágios da `runx` quando existe `PERFIL.md` |
| **[stackx](https://github.com/bittencourtthulio/stackx)** | **camada** de convenções do repositório | a `runx` lê o `CONVENCOES.md` antes de planejar e de corrigir |
| **[mergex](https://github.com/AxisGov/mergex)** | entrega: branch, commit por task, PR e pacote de QA | abre a branch no início do E3 e entrega entre o E4 e o E5 |
| **[memox](https://github.com/bittencourtthulio/MemoX)** | **camada** de memória do projeto | consultada no E1 sobre os arquivos impactados; a `runx` dispara a reindexação no E5 |
| **[prodx](https://github.com/bittencourtthulio/prodx)** | **camada** de produto: decide **se** há trabalho | roda antes do E1: o `BRIEFING.md` assinado vira o `00-OCORRENCIA.md` |
| **[buildx](https://github.com/AxisGov/buildx)** | orquestra um projeto inteiro, da descrição ao sistema pronto | a `runx` não participa dela — a `buildx` constrói, não corrige; mas o projeto que ela entrega já vem com a `runx` instalada, para quem receber o sistema tratar defeito |

**Camadas** (`legadox`, `stackx`, `memox`, `prodx`) sozinhas não fazem nada — elas modificam o comportamento da `sprintx` e da `runx`. A `prodx` é a única que roda **antes** de tudo: ela decide *se* há trabalho, e só depois a `runx` decide *como* fazê-lo. A ausência de qualquer irmã nunca quebra o fluxo desta skill: insumo que não existe vira aviso do que falta, nunca invenção.

Detalhes do ecossistema inteiro no [README do expxdev](https://github.com/AxisGov/expxdev).

---

## Build e Run

O método Expx tem duas metades, irmãs e com a mesma disciplina de engenharia:

<picture>
  <img alt="Build e Run: runx e sprintx compartilham os mesmos contratos. Muda o gatilho e o tamanho, nunca o rigor." src=".github/assets/anim/build-run.svg" width="100%">
</picture>

| | **sprintx** (Build) | **runx** (Run) |
|---|---|---|
| **Gatilho** | feature nova, planejada do zero | ocorrência num sistema em produção |
| **Entrada** | uma ideia, um requisito | um chamado, ticket ou relato de cliente |
| **Estágios** | F1…F6 (ingestão → execução) | E1…E5 (investigação → relatório) |
| **Saída** | a feature entregue | a ocorrência encerrada, com dois relatórios |

As duas compartilham **exatamente** os mesmos contratos: base de conhecimento antes de qualquer plano, hierarquia sprint → fase → task, TDD obrigatório com no mínimo dois testes por task, critério de aceite verificável em toda transição, paralelismo declarado no plano e execução autônoma guiada por um arquivo orquestrador.

**Muda o gatilho e o tamanho. Nunca o rigor.**

---

## Compatibilidade

`runx` funciona em **Claude Code**, **OpenCode** e **MimoCode**, a partir da mesma fonte. Os arquivos da skill são idênticos nos três — o que muda é apenas onde eles ficam:

| | Claude Code | OpenCode | MimoCode |
|---|---|---|---|
| Skill (projeto) | `.claude/skills/runx/` | `.opencode/skills/runx/` | lê `.claude/skills/runx/` |
| Comandos (projeto) | `.claude/commands/` | `.opencode/command/` | lê `.claude/commands/` |
| Skill (global) | `~/.claude/skills/runx/` | `~/.config/opencode/skills/runx/` | lê `~/.claude/skills/runx/` |
| Comandos (global) | `~/.claude/commands/` | `~/.config/opencode/command/` | lê `~/.claude/commands/` |
| Agentes | `.claude/agents/` | lê `.claude/agents/` | lê `.claude/agents/` |
| Hooks | `.claude/runx-hooks/` + `settings.json` | ponte JS em `.opencode/plugins/runx-ponte.js` | ponte JS em `.mimocode/hooks/runx-ponte.js` |

**MimoCode é um fork do OpenCode** e lê `.claude/skills/`, `.claude/commands/` e `.claude/agents/` nativamente — por isso essas três colunas nunca precisam de cópia, só o Claude Code recebe a skill de fato instalada num diretório próprio, e OpenCode ganha a sua por espelhamento em `.opencode/`.

**Hooks** rodam nativamente no Claude Code via `settings.json`. No OpenCode e no MimoCode, uma única ponte JS (`.claude/hooks/ponte/runx-ponte.js`, instalada em cada um) traduz os eventos de plugin desses harnesses (`tool.execute.before`, `tool.execute.after`, `shell.env`) para o mesmo payload que os hooks Python já entendem, e despacha para os mesmos scripts — o motor é um só, escrito uma vez.

Os três harnesses descobrem a skill do mesmo jeito — pelo `name` e pela `description` do frontmatter, carregando o corpo sob demanda — e os três aceitam `$ARGUMENTS` nos comandos. Por isso um único conjunto de arquivos atende aos três sem fork e sem condicional.

### Sessões paralelas

Várias sessões — do mesmo harness ou de harnesses diferentes — podem trabalhar ao mesmo tempo no mesmo projeto. Sem isolamento, um `stash` de uma sessão levaria o trabalho não salvo de outra, e uma suíte de testes rodada por uma sessão reprovaria por causa do código que outra está no meio de mudar.

`runx` resolve isso com três mecanismos, todos descritos na seção "Sessões paralelas" do `SKILL.md`:

<picture>
  <img alt="Sessões paralelas: worktree por ocorrência, reivindicação de task pelo rastro e árvore limpa antes da suíte" src=".github/assets/anim/sessoes-paralelas.svg" width="100%">
</picture>

- **Worktree por ocorrência** (regra 16): com git, cada ocorrência nasce num `git worktree` próprio, isolado do checkout principal.
- **Reivindicação de task pelo rastro**: uma sessão não reabre uma task que o rastro mostra em andamento por outra sessão.
- **Árvore limpa antes da suíte**: a suíte completa e o veredito do QA só rodam depois de confirmar que a árvore não tem trabalho de outra sessão no meio.

---

## Instalação

O instalador monta a estrutura **dos dois harnesses de uma vez**:

```bash
git clone https://github.com/AxisGov/runx.git
cd runx
./install.sh
```

Isso cria `.claude/` **e** `.opencode/` no projeto atual. Para deixar disponível em todos os seus projetos:

```bash
./install.sh --global
```

### Opções

| Flag | Efeito |
|---|---|
| *(nenhuma)* | instala nos três harnesses, no projeto atual |
| `--global` | instala no diretório global do usuário, não no projeto |
| `--claude` | só Claude Code |
| `--opencode` | só OpenCode |
| `--mimocode` | só MimoCode |
| `--force` | sobrescreve instalação existente sem perguntar |
| `--dry-run` | mostra o que faria, sem escrever nada |
| `--sem-hooks` | instala só a skill, sem hooks nem agentes nem a ponte JS |

As flags combinam: `./install.sh --global --opencode` instala só o OpenCode, só no global.

Sem `--force`, o instalador **nunca sobrescreve calado**: pergunta no modo interativo e pula quando não há terminal (CI). Rodar duas vezes é seguro.

Ao registrar os hooks, o instalador **mescla** com o `settings.json` que já existe — nunca o substitui — e guarda uma cópia do anterior em `settings.json.runx-backup`. Registrar de novo não duplica nada.

### Instalação manual

Se preferir copiar à mão, a skill é a mesma pasta nos dois harnesses — só o destino muda:

```bash
# Claude Code
cp -r .claude/skills/runx  meu-projeto/.claude/skills/
cp .claude/commands/runx*.md  meu-projeto/.claude/commands/

# OpenCode
cp -r .opencode/skills/runx  meu-projeto/.opencode/skills/
cp .opencode/command/runx*.md  meu-projeto/.opencode/command/

# Hooks e agentes (só Claude Code) — depois registre os hooks no settings.json,
# como o `install.sh` faz, ou use o `.claude/hooks/hooks.json` como referência
cp -r .claude/agents  meu-projeto/.claude/
cp -r .claude/hooks   meu-projeto/.claude/runx-hooks
```

Os hooks e os agentes ficam em `.claude/hooks/` e `.claude/agents/` — copie também se quiser a camada determinística; o registro deles vai junto, em `.claude/hooks/hooks.json`.

Reinicie a sessão do seu harness para a skill ser carregada.

---

## Uso

### O jeito mais simples

Cole o relato do cliente. **Não é preciso dizer `runx`, "bug" nem "chamado"** — a skill dispara sozinha ao reconhecer a descrição de um problema num sistema que já existe:

```
O cliente reclamou que o cálculo do frete está trazendo valor
divergente para pedidos acima de 50kg.
```

### Comandos

| Comando | O que faz |
|---|---|
| `/runx` | detecta o estágio atual e continua de onde parou; sem argumento, lista as ocorrências abertas |
| `/runx-causa` | **E1** — mapeia a base e comprova a causa raiz (ou mapeia o impacto) |
| `/runx-plano` | **E2** — converte a investigação em sprints, fases e tasks + ORQUESTRADOR |
| `/runx-fix` | **E3** — implementa sob TDD estrito, de forma autônoma |
| `/runx-qa` | **E4** — valida a entrega, sem corrigir nada |
| `/runx-relatar` | **E5** — grava os relatórios, atualiza o índice e encerra |

Os comandos de estágio **recusam execução fora de ordem**: peça o fix sem base mapeada e a skill diz o que falta e executa o estágio pendente.

---

## Os cinco estágios

```
E1 INVESTIGAÇÃO → E2 PLANO → E3 FIX → E4 QA → E5 RELATÓRIO
```

Estritamente sequenciais. A skill descobre onde está **inspecionando o disco**, não perguntando.

<picture>
  <img alt="A skill descobre em que estágio está inspecionando o disco, nunca perguntando" src=".github/assets/anim/maquina-de-estados.svg" width="100%">
</picture>

### E1 — Investigação

Duas metades, nesta ordem.

**E1.a — Base de conhecimento.** Antes de opinar sobre a causa, mapeia o pedaço do sistema que a ocorrência toca, lendo o código de verdade. Um arquivo por área impactada, com template fixo de 10 seções: o que é e onde vive, contratos de entrada e saída, estrutura de dados, funções e trechos relevantes, quem chama e quem é chamado, testes existentes, limites e regras de negócio, riscos e fonte.

Regra dura: **nada de invenção**. Se o código não deixa claro, escreve `NÃO DETERMINADO`. Toda afirmação sobre comportamento aponta para arquivo e linha.

**E1.b — Causa raiz ou análise de impacto.** Comportamento adaptativo pelo tipo:

- **`bug`** → **causa raiz**, e é obrigatório *provar*, não supor. Prova aceita: um teste que reproduz e falha, um log/stack trace/query que evidencia o caminho do erro, ou o trecho de código com a linha e o porquê. **Hipótese sem prova não passa deste estágio.**
- **demais tipos** → **análise de impacto**: como o sistema se comporta hoje, o que muda, o que pode quebrar junto, e o comportamento esperado depois.

<picture>
  <img alt="E1: hipótese sem prova não passa. Bug exige causa raiz comprovada; os demais tipos entram em análise de impacto" src=".github/assets/anim/causa-raiz.svg" width="100%">
</picture>

### E2 — Plano

Converte base e investigação numa árvore de execução, com **proporcionalidade**: a estrutura é sempre a mesma, o tamanho é proporcional à ocorrência.

- Uma correção de uma linha gera **1 sprint, 1 fase e 2 tasks** — e ainda assim com todos os campos do contrato preenchidos.
- Uma ocorrência grande gera **mais fases**, e mais de uma sprint apenas quando existe um portão real entre blocos entregáveis (por exemplo, uma migração que precisa subir antes da mudança de tela).

*Proibido inflar o plano para parecer robusto. Proibido enxugar campos para parecer ágil.*

A primeira task da primeira fase é **sempre** o teste que reproduz o problema. Gera também o `ORQUESTRADOR.md`, escrito para quem abriu o repositório agora e não sabe nada.

### E3 — Fix

Percorre a árvore sob TDD estrito. Por task:

1. Escrever o teste. Rodar. **Ele tem que falhar.**
2. Implementar o mínimo para o teste passar.
3. Escrever os dois testes da task (integração e funcional).
4. Rodar a **suíte inteira**, não só os testes novos.
5. Marcar como concluída apenas com tudo verde.

<picture>
  <img alt="O ciclo de uma task no E3: o teste de regressão antes do código, o vermelho obrigatório, e a task só fecha com a suíte inteira verde" src=".github/assets/anim/tdd-ciclo.svg" width="100%">
</picture>

Se o teste de regressão **passar antes** do fix, o teste está errado ou a causa está errada: para e volta ao E1. Durante o E3 a skill **não pergunta nada** — dúvida nova vai para `BLOQUEIOS.md`, a task é pulada e a próxima paralelizável assume.

### E4 — QA

A IA troca de papel: **valida, não implementa, e não corrige nada** do que encontrar. Verifica se o teste de regressão realmente falhava antes, se cada task tem os dois testes e se eles testam o que dizem testar, se existe teste que passaria mesmo com a implementação errada, se a suíte inteira passa, e se **nada fora do escopo declarado foi alterado** — conferindo o diff contra a lista de arquivos autorizados.

Veredito de uma linha: `APROVADO` ou `REPROVADO`. Achado de severidade ALTA manda voltar para o E3. **Nunca cabe ao E4 corrigir.**

<picture>
  <img alt="E4: a IA troca de papel, valida e não corrige nada. Achado de severidade ALTA devolve ao E3" src=".github/assets/anim/qa-veredito.svg" width="100%">
</picture>

### E5 — Relatório e fechamento

Só executa com E4 aprovado. Gera **dois relatórios, para leitores diferentes**:

- **`tecnico.md`** — para o próximo desenvolvedor que abrir este código. Causa, solução, decisões, testes, risco residual, o que observar em produção, e sugestões de novas ocorrências percebidas e não feitas.
- **`uso.md`** — o suporte copia e devolve ao cliente. **Sem nome de arquivo, sem nome de função, sem nome de tabela, sem jargão técnico, sem stack trace.** Se um cliente não desenvolvedor não entenderia, está errado.

<picture>
  <img alt="E5: dois relatórios para leitores diferentes. tecnico.md para o próximo desenvolvedor, uso.md para o cliente, sem jargão" src=".github/assets/anim/dois-relatorios.svg" width="100%">
</picture>

---

## Tipos de ocorrência

| Tipo | Significado |
|---|---|
| `bug` | defeito em comportamento existente |
| `melhoria-ui` | mudança visual, layout, componente |
| `melhoria-ux` | mudança de fluxo, navegação, usabilidade |
| `novo-relatorio` | relatório novo dentro de estrutura existente |
| `regra-de-calculo` | alteração de fórmula ou regra de negócio |
| `campo-novo` | novo campo em tela, formulário ou entidade |
| `outro` | qualquer coisa que não caiba acima |

O tipo governa o E1: `bug` exige causa raiz comprovada, os demais entram em análise de impacto.

---

## Os contratos

### Task

Toda task declara, obrigatoriamente:

| Campo | Conteúdo |
|---|---|
| `id` | T-NN.MM |
| `titulo` | título curto |
| `objetivo` | uma frase |
| `arquivos` | criados e alterados |
| `teste_regressao` | só na primeira task da primeira fase; obrigatório quando o tipo é `bug` |
| `teste_integracao` | o que valida, contra o quê |
| `teste_funcional` | o que valida, com qual entrada e saída |
| `criterio_aceite` | verificável, binário, sem adjetivo |
| `depende_de` | [ids] ou [] |
| `paralelizavel` | true \| false |
| `status` | pendente \| em_andamento \| concluida \| bloqueada |

**Fase:** objetivo, tasks que a compõem, critério de saída, com qual outra fase pode rodar em paralelo.
**Sprint:** objetivo, fases, critério de saída, riscos conhecidos.

**Granularidade:** se os dois testes de uma task não cabem em uma frase cada, a task está grande demais — quebrar.

---

## Estrutura em disco

<picture>
  <img alt="As duas árvores em disco: trabalho em andamento e histórico permanente" src=".github/assets/anim/disco.svg" width="100%">
</picture>

Duas árvores, propósitos diferentes.

**Trabalho em andamento** — permanece no repositório após o fechamento; a limpeza é decisão do usuário:

```
docs/manutencao/<OC-ID>-<slug>/
  ORQUESTRADOR.md
  00-OCORRENCIA.md      o chamado como chegou, preservado
  01-CAUSA-RAIZ.md      ou análise de impacto, mesmo arquivo
  BLOQUEIOS.md
  QA.md
  base/
    00-INDICE.md
    00-LACUNAS.md
    <uma área impactada>.md
  sprint-01/
    sprint.md
    fases.md
    tasks.md
```

**Histórico permanente do sistema:**

```
docs/relatorios/
  INDICE.md
  <AAAA-MM-DD>-<OC-ID>-<slug>/
    tecnico.md
    uso.md
```

A data no nome da pasta é a de fechamento, para que uma listagem simples devolva a linha do tempo do sistema.

---

## expx-schema v1

Todo arquivo de estado carrega um **frontmatter YAML legível por máquina**, para que um painel de operação leia o andamento das ocorrências sem depender de prosa.

<picture>
  <img alt="expx-schema v1: a máquina lê o YAML do frontmatter, a pessoa lê a prosa. Só a skill escreve" src=".github/assets/anim/schema.svg" width="100%">
</picture>

```yaml
---
expx_schema: 1
expx_tool: runx
kind: tasks
trabalho_id: OC-2026-0142
sprint_id: sprint-01
atualizado_em: 2026-08-29
tasks:
  - id: T-01.01
    titulo: Teste que reproduz a divergencia acima de 50kg
    fase: F-01.1
    status: concluida
    objetivo: Fixar o comportamento esperado antes de corrigir
    arquivos:
      cria: [src/frete/calculo.test.ts]
      altera: []
    teste_regressao: Pedido de 51kg deve retornar 42.90 e hoje retorna 41.00
    teste_integracao: Checkout completo com 51kg fecha com o frete correto
    teste_funcional: calcularFrete(51) retorna 42.90
    criterio_aceite: O teste falha antes do fix e passa depois
    depende_de: []
    paralelizavel: false
    concluida_em: 2026-08-29
    suite: verde
---
```

O painel apenas **lê**; a skill continua sendo a única a escrever. A máquina lê o YAML, a pessoa lê a prosa abaixo dele.

**Kinds produzidos:** `orquestrador`, `ocorrencia`, `causa_raiz`, `sprint`, `fases`, `tasks`, `bloqueios`, `qa`, `base_indice`, `relatorio_tecnico`, `relatorio_uso`, `relatorios_indice`.

Os kinds compartilhados com a `sprintx` — `orquestrador`, `sprint`, `fases`, `tasks`, `bloqueios`, `base_indice` — são **idênticos campo por campo** nas duas skills. Contrato completo em [`references/00-schema.md`](.claude/skills/runx/references/00-schema.md).

---

## As 14 regras invioláveis

1. Nenhum plano nasce sem `base/` preenchida. Mapear antes de planejar.
2. Bug não avança de E1 sem causa raiz comprovada.
3. O plano segue sempre a hierarquia sprint → fase → task, com todos os campos do contrato, qualquer que seja o tamanho da ocorrência.
4. Toda task tem teste de integração e teste funcional. Sem exceção.
5. O teste de regressão é escrito antes do fix e tem que falhar antes.
6. Toda transição tem critério de aceite verificável, e nada avança sem ele atendido.
7. O paralelismo é declarado no plano, nunca decidido em execução.
8. Escopo travado: o que não está em `01-CAUSA-RAIZ.md` e em `tasks.md` não é tocado. Melhoria avulsa vira sugestão de nova ocorrência, e não é implementada.
9. A suíte inteira roda antes de qualquer task ser dada como concluída.
10. Quem implementa não aprova: E4 é papel distinto de E3, e E4 não corrige nada.
11. A ocorrência não fecha sem os dois relatórios gravados e o `INDICE.md` atualizado.
12. A skill nunca apaga nem move nada em `docs/manutencao/`.
13. Durante E3 a skill não pergunta nada. Dúvida nova vira registro em `BLOQUEIOS.md` e a task é pulada.
14. Todo arquivo de estado é gravado com o frontmatter do contrato expx-schema v1. Arquivo de estado sem frontmatter válido é considerado não entregue.

---

## Hooks: a regra que não depende de o modelo lembrar

Toda regra inviolável acima é, sozinha, uma instrução que o modelo pode esquecer numa execução longa. Hook é script determinístico: roda sempre, porque quem executa é o harness, não o modelo.

<picture>
  <img alt="Hooks: scripts determinísticos que o harness executa. Aviso deixa passar com marca; bloqueio barra. Todo hook de método nasce em aviso" src=".github/assets/anim/hooks.svg" width="100%">
</picture>

| Hook | Quando | O que faz |
|---|---|---|
| `comum/segredo-no-commit.py` | antes de escrever | barra credencial real indo para arquivo versionado |
| `runx/causa-antes-do-plano.py` | antes de escrever | impede plano sem `01-CAUSA-RAIZ.md`, ou com causa não comprovada em ocorrência `bug` |
| `runx/regressao-antes-do-fix.py` | antes de escrever | impede tocar código de produção antes do teste que reproduz (regra 5) |
| `runx/task-so-fecha-verde.py` | antes de escrever | barra `status: concluida` sem `suite: verde` e sem os dois testes |
| `runx/escopo-da-ocorrencia.py` | antes de escrever | avisa quando a escrita sai dos arquivos que a investigação autorizou (regra 8) |
| `runx/sem-jargao-no-uso.py` | depois de escrever | detecta jargão técnico no `uso.md`, que é o texto que vai ao cliente |
| `runx/uma-ocorrencia-por-arvore.py` | antes de escrever | avisa quando outra ocorrência já está aberta na mesma árvore de trabalho (regra 16) |
| `runx/task-reivindicada.py` | antes de escrever | avisa ao marcar `em_andamento` uma task que o rastro mostra aberta por outra sessão |
| `runx/arvore-limpa-antes-da-suite.py` | antes de rodar `Bash` | avisa, antes da suíte, se há arquivo sujo fora do escopo ou task de outra sessão em andamento |
| `comum/rastro-arquivo.py` | depois de escrever | registra `arquivo_alterado` no rastro |
| `comum/rastro-suite.py` | depois de rodar `Bash` | registra `suite_executada`, verde ou vermelha pelo código de saída, com HEAD e sujos fora do escopo |

**Todo hook nasce em modo `aviso`** — registra e deixa passar. A promoção para `bloqueio` é decisão sua, tomada depois de semanas sem falso positivo, e o modo de cada um vive em `.expx/hooks.json`. A exceção é a segurança: `segredo-no-commit` nasce em `bloqueio` e falha fechada, porque segredo commitado não tem volta.

Rode `python3 .claude/runx-hooks/comum/doctor.py` para ver em que modo cada hook está e quantas vezes cada regra foi violada — é o dado que diz qual já pode ser promovido.

Os oito hooks de escrita e o de `Bash` no grupo `PreToolUse` rodam por um **despachante único**, não como processos separados: cada `python3` custa cerca de 30 ms só para subir, e vários deles estourariam o orçamento de 200 ms por chamada de ferramenta. Um processo lê o evento uma vez e roda as verificações em sequência.

## Agentes

Três subagentes rodam em contexto próprio, para que o julgamento não seja contaminado por quem produziu o trabalho:

<picture>
  <img alt="Três agentes de veredito, somente leitura: runx-investigador, runx-revisor-testes e qa. Apontam, não corrigem" src=".github/assets/anim/agentes.svg" width="100%">
</picture>

| Agente | Estágio | Papel |
|---|---|---|
| `runx-investigador` | E1 | mapeia a base e comprova a causa raiz; só leitura, hipótese sem prova não passa |
| `runx-revisor-testes` | E3/E4 | responde a uma pergunta só: *esse teste passaria com a implementação errada?* |
| `qa` | E4 | valida a entrega contra plano, escopo e suíte, e emite o veredito; **não corrige nada** |

## O rastro de eventos

Hooks e skill gravam um arquivo append-only, uma linha JSON por evento, seguindo o contrato `expx-eventos` v1:

```
docs/eventos/<OC-ID>.jsonl
```

<picture>
  <img alt="O rastro de eventos: um arquivo append-only, uma linha JSON por evento, lido pelo painel de operação" src=".github/assets/anim/rastro.svg" width="100%">
</picture>

É o que o **painel de operação** (`npx expxdev panel`) lê para mostrar o que aconteceu e quando — fase iniciada e concluída, task concluída ou bloqueada, suíte executada, arquivo alterado, regra violada, veredito emitido. Ninguém edita à mão.

Duas coisas que só o rastro revela: **quantas voltas ao E3 o QA causou** em cada ocorrência — que é um indicador honesto de qualidade do plano, porque plano ruim gera volta — e a **duração real de cada task**, sem ninguém anotar nada.

O rastro é ignorado pelo versionador por padrão: é local da máquina de quem executou e cresce rápido. Acima de 5 MB ele rotaciona para `<OC-ID>.1.jsonl` e um novo começa.

---

## Estrutura do repositório

A skill é **neutra de harness**: o mesmo conteúdo serve aos dois, e só o registro difere.

```
.claude/
  skills/runx/
    SKILL.md                  identidade, contratos, máquina de estados, regras
    DECISOES-DA-SKILL.md      decisões de construção, com o porquê de cada uma
    references/
      00-schema.md            contrato expx-schema v1 (leitura obrigatória ao gravar)
      01-investigacao.md      E1 — base de conhecimento + causa raiz/impacto
      02-plano.md             E2 — sprints, fases, tasks e orquestrador
      03-fix.md               E3 — TDD estrito, portões e paralelismo
      04-qa.md                E4 — validação independente
      05-relatorio.md         E5 — relatórios e fechamento
    assets/
      TEMPLATE-*.md           12 templates preenchíveis
  commands/runx*.md           os 6 comandos do Claude Code
  agents/                     os 3 subagentes: runx-investigador, runx-revisor-testes, qa
  hooks/
    hooks.json                o registro dos hooks no harness
    hooks.exemplo.json        template do modo de cada hook, copiado para .expx/
    jargao.exemplo.json       a lista de jargão do hook do relatório de uso
    comum/                    segredo, rastro, despachante e a biblioteca de eventos
    runx/                     os cinco hooks de método
    testes/                   a suíte dos próprios hooks
.opencode/
  skills/runx/                a mesma skill, no formato do OpenCode
  command/runx*.md            os mesmos comandos, no formato do OpenCode
.github/assets/               banner e badges
  anim/                       as 15 animacoes deste README
install.sh                    instalador para Claude Code + OpenCode
```

O `SKILL.md` é a porta de entrada e fica abaixo de 200 linhas. O detalhe operacional de cada estágio mora no `reference` correspondente, lido **só quando o estágio chega** — mantendo o contexto enxuto.

---

## Licença

MIT

---

<div align="center">
<sub>Parte do método <strong>Expx</strong> ·
<a href="https://github.com/AxisGov/expxdev">expxdev</a> ·
<a href="https://github.com/AxisGov/buildx">buildx</a> ·
<a href="https://github.com/AxisGov/sprintx">sprintx</a> ·
runx ·
<a href="https://github.com/bittencourtthulio/legadox">legadox</a> ·
<a href="https://github.com/bittencourtthulio/stackx">stackx</a> ·
<a href="https://github.com/AxisGov/mergex">mergex</a></sub>
</div>
