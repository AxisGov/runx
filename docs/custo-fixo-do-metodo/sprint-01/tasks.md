---
expx_schema: 1
expx_tool: sprintx
kind: tasks
trabalho_id: custo-fixo-do-metodo
sprint_id: sprint-01
atualizado_em: 2026-09-02
tasks:
  - id: T-01.01
    titulo: Verificador de conteudo das skills
    fase: F-01.1
    status: concluida
    objetivo: Criar o script que valida os markdown da runx contra as regras do metodo
    arquivos:
      cria: [.claude/hooks/testes/testar-conteudo.sh]
      altera: []
    teste_integracao: Roda o script contra o repositorio real e confere que ele sai com codigo diferente de zero enquanto o formato condensado nao esta documentado
    teste_funcional: Dado um SKILL.md sem a mencao ao formato condensado, o script reporta a asercao falhando pelo nome; dado um com a mencao, a asercao passa
    criterio_aceite: bash .claude/hooks/testes/testar-conteudo.sh sai com codigo 1 no estado atual e nomeia cada asercao que falhou
    depende_de: []
    paralelizavel: true
    concluida_em: 2026-09-02
    suite: verde
  - id: T-01.02
    titulo: Teste de espelhamento entre as duas arvores
    fase: F-01.1
    status: concluida
    objetivo: Garantir que .claude/skills/runx e .opencode/skills/runx nunca divirjam
    arquivos:
      cria: [.claude/hooks/testes/testar-espelho.sh]
      altera: []
    teste_integracao: Roda o script contra as duas arvores reais e confere que sai zero quando sao identicas
    teste_funcional: Dada uma divergencia introduzida em um arquivo de uma arvore, o script sai com codigo 1 e nomeia o arquivo divergente
    criterio_aceite: bash .claude/hooks/testes/testar-espelho.sh sai 0 com as arvores identicas e sai 1 nomeando o arquivo quando ha divergencia
    depende_de: []
    paralelizavel: true
    concluida_em: 2026-09-02
    suite: verde
---

# Tasks — Sprint 01

---

```yaml
id: T-01.01
titulo: Verificador de conteúdo das skills
objetivo: Criar o script que valida os markdown da runx contra as regras do método
arquivos:
  cria: [.claude/hooks/testes/testar-conteudo.sh]
  altera: []
teste_integracao: Roda o script contra o repositório real e confere que ele sai com código diferente de zero enquanto o formato condensado não está documentado
teste_funcional: Dado um SKILL.md sem a menção ao formato condensado, o script reporta a asserção falhando pelo nome; dado um com a menção, a asserção passa
criterio_aceite: bash .claude/hooks/testes/testar-conteudo.sh sai com código 1 no estado atual e nomeia cada asserção que falhou
depende_de: []
paralelizavel: true
status: concluida   # 2026-09-02 · testar-conteudo.sh: 5 ok, 15 falhas (vermelho esperado)
```

O script cobre, em asserções nomeadas:

- o `SKILL.md` documenta o formato condensado e diz quando ele se aplica;
- o `00-schema.md` declara o kind `plano` com todas as chaves;
- o enum `suite` inclui `parcial` no `00-schema.md`;
- o `03-fix.md` manda rodar o subconjunto por task e não a suíte inteira;
- o `04-qa.md` exige a execução completa antes do veredito;
- o `01-investigacao.md` traz o corte de 3 arquivos para delegar ao runx-investigador;
- nenhum arquivo de instrução contém marcador `{{...}}` vazado (DR-14);
- as 15 regras invioláveis continuam sendo 15 (D-13).

---

```yaml
id: T-01.02
titulo: Teste de espelhamento entre as duas árvores
objetivo: Garantir que .claude/skills/runx e .opencode/skills/runx nunca divirjam
arquivos:
  cria: [.claude/hooks/testes/testar-espelho.sh]
  altera: []
teste_integracao: Roda o script contra as duas árvores reais e confere que sai zero quando são idênticas
teste_funcional: Dada uma divergência introduzida em um arquivo de uma árvore, o script sai com código 1 e nomeia o arquivo divergente
criterio_aceite: bash .claude/hooks/testes/testar-espelho.sh sai 0 com as árvores idênticas e sai 1 nomeando o arquivo quando há divergência
depende_de: []
paralelizavel: true
status: concluida   # 2026-09-02 · testar-espelho.sh: 2 ok, 0 falhas
```

Cobre `.claude/skills/runx` ↔ `.opencode/skills/runx` e `.claude/commands` ↔ `.opencode/command`.
