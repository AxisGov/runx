---
expx_schema: 1
expx_tool: sprintx
kind: tasks
trabalho_id: custo-fixo-do-metodo
sprint_id: sprint-02
atualizado_em: 2026-09-02
tasks:
  - id: T-02.01
    titulo: Declarar o kind plano no schema da runx
    fase: F-02.1
    status: concluida
    objetivo: Acrescentar o kind plano ao 00-schema.md, exclusivo da runx, com todas as chaves
    arquivos:
      cria: []
      altera: [.claude/skills/runx/references/00-schema.md]
    teste_integracao: Roda testar-conteudo.sh e confere que a asercao kind-plano-declarado passa
    teste_funcional: Dado o 00-schema.md com o kind plano, a asercao encontra as chaves sprint, fases e tasks no mesmo bloco e a nota de exclusividade da runx
    criterio_aceite: A asercao kind-plano-declarado do testar-conteudo.sh passa e a asercao kind-compartilhado-intacto tambem passa
    depende_de: []
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.02
    titulo: Criar o template do plano condensado
    fase: F-02.1
    status: concluida
    objetivo: Criar o asset TEMPLATE-plano-condensado.md com os tres contratos em um arquivo
    arquivos:
      cria: [.claude/skills/runx/assets/TEMPLATE-plano-condensado.md]
      altera: []
    teste_integracao: Roda testar-conteudo.sh e confere que a asercao template-condensado-existe passa
    teste_funcional: Dado o template criado, a asercao confere que ele tem um unico bloco YAML e que nenhum campo do contrato da task esta ausente
    criterio_aceite: O template tem exatamente um bloco YAML delimitado e contem os 11 campos do contrato da task da runx
    depende_de: [T-02.01]
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.03
    titulo: E2 escolhe entre formato condensado e tres arquivos
    fase: F-02.1
    status: concluida
    objetivo: Ensinar o 02-plano.md a usar o condensado com 1 sprint e 1 fase e os tres arquivos nos demais casos
    arquivos:
      cria: []
      altera: [.claude/skills/runx/references/02-plano.md, .claude/skills/runx/SKILL.md]
    teste_integracao: Roda testar-conteudo.sh e confere que a asercao e2-escolhe-formato passa
    teste_funcional: Dado o 02-plano.md alterado, a asercao encontra a condicao 1 sprint e 1 fase e o caminho sprint-NN/tasks.md para o condensado
    criterio_aceite: As asercoes e2-escolhe-formato e skill-documenta-condensado passam, e a asercao regras-continuam-15 continua passando
    depende_de: [T-02.02]
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.04
    titulo: Acrescentar parcial ao enum suite
    fase: F-02.2
    status: concluida
    objetivo: Declarar o valor parcial no enum suite do 00-schema.md da runx
    arquivos:
      cria: []
      altera: [.claude/skills/runx/references/00-schema.md]
    teste_integracao: Roda testar-conteudo.sh e confere que a asercao enum-suite-tem-parcial passa
    teste_funcional: Dado o enum alterado, a asercao encontra parcial listado junto de verde, vermelha e nao_executada
    criterio_aceite: A asercao enum-suite-tem-parcial passa e o enum lista os quatro valores
    depende_de: [T-02.01]
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.05
    titulo: E3 roda subconjunto e E4 exige a completa
    fase: F-02.2
    status: concluida
    objetivo: Mover a exigencia de suite inteira do fim de cada task para o portao do E4
    arquivos:
      cria: []
      altera: [.claude/skills/runx/references/03-fix.md, .claude/skills/runx/references/04-qa.md, .claude/skills/runx/SKILL.md]
    teste_integracao: Roda testar-conteudo.sh e confere que as asercoes e3-suite-parcial e e4-exige-completa passam
    teste_funcional: Dado o 03-fix.md alterado, a asercao encontra a instrucao de rodar o subconjunto afetado; dado o 04-qa.md, encontra a exigencia de execucao completa antes do veredito
    criterio_aceite: As asercoes e3-suite-parcial e e4-exige-completa passam e a asercao regras-continuam-15 continua passando
    depende_de: [T-02.04]
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.06
    titulo: Hook task-so-fecha-verde aceita suite parcial
    fase: F-02.2
    status: concluida
    objetivo: Impedir que o hook barre status concluida quando a suite da task e parcial
    arquivos:
      cria: []
      altera: [.claude/hooks/runx/task-so-fecha-verde.py, .claude/hooks/testes/testar.sh]
    teste_integracao: Roda testar.sh e confere que o caso novo task fecha com suite parcial sai com codigo 0
    teste_funcional: Dado um tasks.md propondo status concluida com suite parcial e os dois testes preenchidos, o hook sai 0; com suite vermelha, continua avisando
    criterio_aceite: testar.sh sai com 0 falhas incluindo o caso novo de suite parcial, e o caso de suite vermelha continua sendo barrado
    depende_de: [T-02.04]
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.07
    titulo: Corte de tres arquivos para delegar ao runx-investigador
    fase: F-02.3
    status: concluida
    objetivo: Condicionar a delegacao ao runx-investigador ao numero de arquivos candidatos do grep
    arquivos:
      cria: []
      altera: [.claude/skills/runx/references/01-investigacao.md]
    teste_integracao: Roda testar-conteudo.sh e confere que a asercao runx-investigador-corte-tres passa
    teste_funcional: Dado o 01-investigacao.md alterado, a asercao encontra o corte de 3 arquivos e a instrucao de ler direto abaixo dele
    criterio_aceite: A asercao runx-investigador-corte-tres passa e o texto preserva qa e runx-revisor-testes como sempre acionados
    depende_de: []
    paralelizavel: true
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.08
    titulo: Espelhar todas as mudancas em .opencode
    fase: F-02.4
    status: concluida
    objetivo: Copiar a skill alterada para a arvore do OpenCode conforme DR-44
    arquivos:
      cria: [.opencode/skills/runx/assets/TEMPLATE-plano-condensado.md]
      altera: [.opencode/skills/runx/references/00-schema.md, .opencode/skills/runx/references/01-investigacao.md, .opencode/skills/runx/references/02-plano.md, .opencode/skills/runx/references/03-fix.md, .opencode/skills/runx/references/04-qa.md, .opencode/skills/runx/SKILL.md]
    teste_integracao: Roda testar-espelho.sh e confere que sai com codigo 0
    teste_funcional: Dadas as duas arvores apos a copia, diff -rq nao reporta diferenca em skills nem em commands
    criterio_aceite: testar-espelho.sh sai 0 e testar-conteudo.sh continua saindo 0
    depende_de: [T-02.03, T-02.05, T-02.06, T-02.07]
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: parcial
  - id: T-02.09
    titulo: Registrar as decisoes no DECISOES-DA-SKILL
    fase: F-02.4
    status: concluida
    objetivo: Acrescentar as linhas DR do ajuste de custo fixo nas duas arvores
    arquivos:
      cria: []
      altera: [.claude/skills/runx/DECISOES-DA-SKILL.md, .opencode/skills/runx/DECISOES-DA-SKILL.md]
    teste_integracao: Roda testar-espelho.sh e confere que sai 0 apos a edicao nas duas arvores
    teste_funcional: Dado o DECISOES-DA-SKILL.md alterado, a asercao decisoes-registradas encontra a secao do ajuste de custo fixo
    criterio_aceite: A asercao decisoes-registradas passa e testar-espelho.sh sai 0
    depende_de: [T-02.08]
    paralelizavel: false
    concluida_em: 2026-09-02
    suite: verde
---

# Tasks — Sprint 02

> Nota de paralelismo: as fases F-02.1, F-02.2 e F-02.3 são paralelas entre si, mas
> T-02.01 e T-02.04 tocam ambas o `00-schema.md` e por isso são `paralelizavel: false`.
> T-02.05 e T-02.03 tocam ambas o `SKILL.md`, mesma razão. A única task realmente
> paralelizável é a T-02.07, que toca um arquivo que ninguém mais toca.

---

```yaml
id: T-02.01
titulo: Declarar o kind plano no schema da runx
objetivo: Acrescentar o kind plano ao 00-schema.md, exclusivo da runx, com todas as chaves
arquivos:
  cria: []
  altera: [.claude/skills/runx/references/00-schema.md]
teste_integracao: Roda testar-conteudo.sh e confere que a asserção kind-plano-declarado passa
teste_funcional: Dado o 00-schema.md com o kind plano, a asserção encontra as chaves sprint, fases e tasks no mesmo bloco e a nota de exclusividade da runx
criterio_aceite: A asserção kind-plano-declarado do testar-conteudo.sh passa e a asserção kind-compartilhado-intacto também passa
depende_de: []
paralelizavel: false
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.02
titulo: Criar o template do plano condensado
objetivo: Criar o asset TEMPLATE-plano-condensado.md com os três contratos em um arquivo
arquivos:
  cria: [.claude/skills/runx/assets/TEMPLATE-plano-condensado.md]
  altera: []
teste_integracao: Roda testar-conteudo.sh e confere que a asserção template-condensado-existe passa
teste_funcional: Dado o template criado, a asserção confere que ele tem um único bloco YAML e que nenhum campo do contrato da task está ausente
criterio_aceite: O template tem exatamente um bloco YAML delimitado e contém os 11 campos do contrato da task da runx
depende_de: [T-02.01]
paralelizavel: false
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.03
titulo: E2 escolhe entre formato condensado e três arquivos
objetivo: Ensinar o 02-plano.md a usar o condensado com 1 sprint e 1 fase e os três arquivos nos demais casos
arquivos:
  cria: []
  altera: [.claude/skills/runx/references/02-plano.md, .claude/skills/runx/SKILL.md]
teste_integracao: Roda testar-conteudo.sh e confere que a asserção e2-escolhe-formato passa
teste_funcional: Dado o 02-plano.md alterado, a asserção encontra a condição 1 sprint e 1 fase e o caminho sprint-NN/tasks.md para o condensado
criterio_aceite: As asserções e2-escolhe-formato e skill-documenta-condensado passam, e a asserção regras-continuam-15 continua passando
depende_de: [T-02.02]
paralelizavel: false
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.04
titulo: Acrescentar parcial ao enum suite
objetivo: Declarar o valor parcial no enum suite do 00-schema.md da runx
arquivos:
  cria: []
  altera: [.claude/skills/runx/references/00-schema.md]
teste_integracao: Roda testar-conteudo.sh e confere que a asserção enum-suite-tem-parcial passa
teste_funcional: Dado o enum alterado, a asserção encontra parcial listado junto de verde, vermelha e nao_executada
criterio_aceite: A asserção enum-suite-tem-parcial passa e o enum lista os quatro valores
depende_de: [T-02.01]
paralelizavel: false
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.05
titulo: E3 roda subconjunto e E4 exige a completa
objetivo: Mover a exigência de suíte inteira do fim de cada task para o portão do E4
arquivos:
  cria: []
  altera: [.claude/skills/runx/references/03-fix.md, .claude/skills/runx/references/04-qa.md, .claude/skills/runx/SKILL.md]
teste_integracao: Roda testar-conteudo.sh e confere que as asserções e3-suite-parcial e e4-exige-completa passam
teste_funcional: Dado o 03-fix.md alterado, a asserção encontra a instrução de rodar o subconjunto afetado; dado o 04-qa.md, encontra a exigência de execução completa antes do veredito
criterio_aceite: As asserções e3-suite-parcial e e4-exige-completa passam e a asserção regras-continuam-15 continua passando
depende_de: [T-02.04]
paralelizavel: false
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.06
titulo: Hook task-so-fecha-verde aceita suíte parcial
objetivo: Impedir que o hook barre status concluida quando a suíte da task é parcial
arquivos:
  cria: []
  altera: [.claude/hooks/runx/task-so-fecha-verde.py, .claude/hooks/testes/testar.sh]
teste_integracao: Roda testar.sh e confere que o caso novo task fecha com suíte parcial sai com código 0
teste_funcional: Dado um tasks.md propondo status concluida com suite parcial e os dois testes preenchidos, o hook sai 0; com suite vermelha, continua avisando
criterio_aceite: testar.sh sai com 0 falhas incluindo o caso novo de suíte parcial, e o caso de suíte vermelha continua sendo barrado
depende_de: [T-02.04]
paralelizavel: false
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.07
titulo: Corte de três arquivos para delegar ao runx-investigador
objetivo: Condicionar a delegação ao runx-investigador ao número de arquivos candidatos do grep
arquivos:
  cria: []
  altera: [.claude/skills/runx/references/01-investigacao.md]
teste_integracao: Roda testar-conteudo.sh e confere que a asserção runx-investigador-corte-tres passa
teste_funcional: Dado o 01-investigacao.md alterado, a asserção encontra o corte de 3 arquivos e a instrução de ler direto abaixo dele
criterio_aceite: A asserção runx-investigador-corte-tres passa e o texto preserva qa e runx-revisor-testes como sempre acionados
depende_de: []
paralelizavel: true
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.08
titulo: Espelhar todas as mudanças em .opencode
objetivo: Copiar a skill alterada para a árvore do OpenCode conforme DR-44
arquivos:
  cria: [.opencode/skills/runx/assets/TEMPLATE-plano-condensado.md]
  altera: [.opencode/skills/runx/references/00-schema.md, .opencode/skills/runx/references/01-investigacao.md, .opencode/skills/runx/references/02-plano.md, .opencode/skills/runx/references/03-fix.md, .opencode/skills/runx/references/04-qa.md, .opencode/skills/runx/SKILL.md]
teste_integracao: Roda testar-espelho.sh e confere que sai com código 0
teste_funcional: Dadas as duas árvores após a cópia, diff -rq não reporta diferença em skills nem em commands
criterio_aceite: testar-espelho.sh sai 0 e testar-conteudo.sh continua saindo 0
depende_de: [T-02.03, T-02.05, T-02.06, T-02.07]
paralelizavel: false
status: concluida   # 2026-09-02
```

---

```yaml
id: T-02.09
titulo: Registrar as decisões no DECISOES-DA-SKILL
objetivo: Acrescentar as linhas DR do ajuste de custo fixo nas duas árvores
arquivos:
  cria: []
  altera: [.claude/skills/runx/DECISOES-DA-SKILL.md, .opencode/skills/runx/DECISOES-DA-SKILL.md]
teste_integracao: Roda testar-espelho.sh e confere que sai 0 após a edição nas duas árvores
teste_funcional: Dado o DECISOES-DA-SKILL.md alterado, a asserção decisoes-registradas encontra a seção do ajuste de custo fixo
criterio_aceite: A asserção decisoes-registradas passa e testar-espelho.sh sai 0
depende_de: [T-02.08]
paralelizavel: false
status: concluida   # 2026-09-02
```
