---
expx_schema: 1
expx_tool: sprintx
kind: decisoes
trabalho_id: custo-fixo-do-metodo
atualizado_em: 2026-09-02
decisoes:
  - id: D-01
    decisao: Plano condensado em um arquivo unico quando ha 1 sprint e 1 fase
    alternativa_descartada: Fundir apenas sprint.md e fases.md, mantendo tasks.md separado
    motivo: Escolha do usuario; ataca o intercepto inteiro e nao so parte dele
    status: fechada
    bloqueante: false
  - id: D-02
    decisao: O arquivo condensado e gravado em sprint-NN/tasks.md, preservando o caminho que os 4 hooks buscam
    alternativa_descartada: Nome novo PLANO.md
    motivo: task-so-fecha-verde casa por regex sobre sprint-[^/]+/tasks.md; nome novo desligaria 4 hooks em silencio
    status: fechada
    bloqueante: false
  - id: D-03
    decisao: O condensado usa kind novo `plano`, exclusivo da runx, com tasks no primeiro bloco YAML
    alternativa_descartada: Redefinir os kinds sprint, fases e tasks para o formato condensado
    motivo: 00-schema.md proibe mudar kind compartilhado com a sprintx; kind exclusivo pode evoluir sozinho
    status: fechada
    bloqueante: false
  - id: D-04
    decisao: Um unico bloco YAML no arquivo condensado, com sprint, fases e tasks como chaves irmas
    alternativa_descartada: Tres blocos YAML em sequencia no mesmo arquivo
    motivo: expx_rastro.frontmatter le apenas o PRIMEIRO bloco; blocos seguintes seriam invisiveis aos hooks
    status: fechada
    bloqueante: false
  - id: D-05
    decisao: O formato de tres arquivos continua valido e e obrigatorio quando ha mais de uma sprint ou mais de uma fase
    alternativa_descartada: Migrar todo plano para o formato condensado
    motivo: Ocorrencias grandes ganham legibilidade com arquivos separados; e a regra 12 proibe apagar ou reescrever o que ja existe
    status: fechada
    bloqueante: false
  - id: D-06
    decisao: O enum suite ganha o valor `parcial`
    alternativa_descartada: Campo irmao suite_escopo, ou apenas mudar a prosa sem registrar
    motivo: Escolha do usuario; mantem o registro auditavel em um campo so
    status: fechada
    bloqueante: false
  - id: D-07
    decisao: O E3 roda o subconjunto afetado por task; o E4 exige uma execucao completa verde antes do veredito
    alternativa_descartada: Manter suite inteira a cada task
    motivo: Preserva a garantia movendo-a para o portao final, cortando o custo linearmente
    status: fechada
    bloqueante: false
  - id: D-08
    decisao: task-so-fecha-verde passa a aceitar suite parcial ou verde para status concluida
    alternativa_descartada: Manter o hook exigindo verde
    motivo: Sem isso o hook barraria toda conclusao de task sob a regra nova
    status: fechada
    bloqueante: false
  - id: D-09
    decisao: O runx-investigador so e delegado quando o grep do E1 devolver 3 ou mais arquivos candidatos
    alternativa_descartada: Corte em 5 arquivos, ou corte por bytes somados da base
    motivo: Escolha do usuario; contagem de arquivos e derivavel do grep sem custo extra de medicao
    status: fechada
    bloqueante: false
  - id: D-10
    decisao: qa e runx-revisor-testes continuam sempre acionados quando disponiveis
    alternativa_descartada: Aplicar corte por tamanho tambem a eles
    motivo: qa e a unica verificacao independente do metodo; runx-revisor-testes responde uma pergunta so e e barato
    status: fechada
    bloqueante: false
  - id: D-11
    decisao: A entrega cria um verificador executavel do conteudo das skills, em .claude/hooks/testes/
    alternativa_descartada: Alterar os markdown sem teste automatizado
    motivo: Regra 3 do sprintx exige TDD; sem verificador executavel nao ha teste que falhe antes
    status: fechada
    bloqueante: false
  - id: D-12
    decisao: A entrega cria um teste de espelhamento .claude/ vs .opencode/
    alternativa_descartada: Continuar conferindo por diff -rq manual
    motivo: DR-44 obriga espelhar; L-03 registrou que nao ha verificacao automatica
    status: fechada
    bloqueante: false
  - id: D-13
    decisao: Nenhuma regra inviolavel e acrescentada, removida ou renumerada; continuam 15
    alternativa_descartada: Criar regra nova para o formato condensado
    motivo: As tres melhorias sao otimizacao de custo, nao mudanca de metodo; a regra 9 tem seu texto ajustado, nao sua natureza
    status: fechada
    bloqueante: false
  - id: D-14
    decisao: Toda mudanca e espelhada em .opencode/skills/runx/ e conferida por diff -rq
    alternativa_descartada: Aplicar so em .claude/
    motivo: DR-44; install.sh distribui as duas arvores
    status: fechada
    bloqueante: false
  - id: D-15
    decisao: A sprintx nao e alterada por esta entrega
    alternativa_descartada: Aplicar o andaime condensado tambem na sprintx
    motivo: Escopo declarado e a runx; mexer na skill irma estouraria o escopo (mesmo criterio do DR-58)
    status: fechada
    bloqueante: false
---

# Decisões — custo-fixo-do-metodo

Decisões que fecham o desenho das três melhorias. As três perguntas do bloco único da F2
foram respondidas pelo usuário; as demais decisões derivam da evidência da F1 e estão
registradas com o arquivo da base que as sustenta.

## Decisões fechadas

```
D-01 | Plano condensado em um arquivo único quando há 1 sprint e 1 fase | Fundir apenas sprint.md e fases.md | Escolha do usuário; ataca o intercepto inteiro
D-02 | O condensado é gravado em sprint-NN/tasks.md | Nome novo PLANO.md | task-so-fecha-verde casa por regex sobre sprint-[^/]+/tasks.md (base/acoplamento-hooks.md §4)
D-03 | Kind novo `plano`, exclusivo da runx | Redefinir os kinds compartilhados | 00-schema.md proíbe mudar kind compartilhado; kind exclusivo pode evoluir sozinho
D-04 | Um único bloco YAML, com sprint/fases/tasks como chaves irmãs | Três blocos YAML em sequência | expx_rastro.frontmatter lê só o PRIMEIRO bloco (base/acoplamento-hooks.md §5)
D-05 | O formato de três arquivos continua válido e obrigatório com >1 sprint ou >1 fase | Migrar tudo | Legibilidade em ocorrência grande; regra 12 proíbe reescrever o que existe
D-06 | O enum `suite` ganha o valor `parcial` | Campo irmão, ou só prosa | Escolha do usuário; registro auditável em um campo só
D-07 | E3 roda subconjunto por task; E4 exige execução completa verde antes do veredito | Suíte inteira a cada task | Move a garantia para o portão final sem perdê-la
D-08 | task-so-fecha-verde aceita `parcial` ou `verde` | Manter exigindo verde | Sem isso o hook barraria toda conclusão sob a regra nova
D-09 | Investigador delegado só com 3+ arquivos candidatos no grep do E1 | Corte em 5; corte por bytes | Escolha do usuário; derivável do grep sem medição extra
D-10 | qa e runx-revisor-testes sempre acionados quando disponíveis | Aplicar corte a eles também | qa é a única verificação independente; runx-revisor-testes é barato
D-11 | Criar verificador executável do conteúdo das skills | Alterar markdown sem teste | Regra 3 (TDD) exige teste que falhe antes (lacuna L-01)
D-12 | Criar teste de espelhamento .claude/ vs .opencode/ | Continuar por diff manual | DR-44 obriga espelhar; lacuna L-03
D-13 | Nenhuma regra inviolável acrescentada, removida ou renumerada; continuam 15 | Criar regra nova | São otimizações de custo, não mudança de método
D-14 | Toda mudança espelhada em .opencode/ e conferida por diff -rq | Aplicar só em .claude/ | DR-44; install.sh distribui as duas árvores
D-15 | A sprintx não é alterada por esta entrega | Aplicar o condensado nela também | Escopo é a runx; mesmo critério do DR-58
```

## Contradição apontada ao usuário

A escolha "um arquivo só" contradizia `base/e2-plano.md` §9, que registra que `sprint`,
`fases` e `tasks` são kinds **compartilhados** com a sprintx e que `00-schema.md` proíbe
mudá-los unilateralmente.

**Resolvida por D-03 sem voltar ao usuário:** o condensado usa um kind novo (`plano`),
que o próprio schema autoriza a evoluir sozinho ("Kind exclusivo de uma delas pode evoluir
sozinho"), gravado no caminho que os hooks já buscam (D-02). A escolha do usuário é
atendida; o contrato compartilhado permanece intacto.

## Pendências

Nenhuma. Nenhum PENDENTE bloqueante — a F3 está liberada.

## Cobertura dos sete eixos

| Eixo | Onde foi coberto |
|---|---|
| 1. Escopo de negócio | D-01, D-05, D-15 — o que entra (runx), o que fica de fora (sprintx, planos multi-sprint) |
| 2. Arquitetura | D-02, D-03, D-04 — onde o arquivo vive, qual kind, quantos blocos YAML |
| 3. Contrato de dados | D-03, D-06 — kind `plano` novo, enum `suite` com `parcial` |
| 4. Estado e observabilidade | D-06, D-07 — `suite: parcial` é o que torna a distinção auditável no painel e no rastro |
| 5. Resiliência e política de erro | D-08 — o hook aceita o valor novo em vez de barrar; hooks continuam falhando abertos |
| 6. Ambiente e segredos | Não se aplica: a feature altera markdown de skill e scripts Python locais; nenhum segredo, nenhuma variável de ambiente nova (verificado na F1) |
| 7. Definição de pronto | D-11, D-12 — verificador de conteúdo verde e teste de espelhamento verde, mais os 56 casos existentes de `testar.sh` |
