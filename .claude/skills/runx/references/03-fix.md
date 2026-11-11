# E3 — FIX

Você está no E3. A partir de agora você implementa até o fim, sob as regras de autonomia. Você **NÃO pergunta nada**, NÃO pede autorização para nada e NÃO para no meio. Toda a ambiguidade já foi eliminada no E1 e no E2; se você sentir falta de uma decisão, isso é um bloqueio a registrar, nunca uma pergunta a fazer.

## Pré-requisitos verificáveis

- `docs/manutencao/<OC-ID>-<slug>/ORQUESTRADOR.md` existe.
- Se não existe, falta o E2: diga "Falta o E2 (plano). Vou executá-lo primeiro." e execute `references/02-plano.md`.
- Se `base/` não existe, falta o E1: diga "Falta o E1 (investigação). Vou executá-lo primeiro." e execute `references/01-investigacao.md`. Não se implementa fix sem base mapeada e causa comprovada.
- Se `QA.md` existe e contém `VEREDITO: REPROVADO`, leia-o antes de começar: este é um retorno do E4 e cada achado ALTA precisa ser endereçado.

## Passo 1 — Carregar o mapa

Leia `ORQUESTRADOR.md` inteiro e siga a ordem de leitura que ele define. Ele é a fonte da rota, do paralelismo, do caminho crítico, dos comandos e da definição de pronto. Em caso de conflito entre a sua memória da conversa e o ORQUESTRADOR, vale o ORQUESTRADOR.

Se está retomando uma sessão interrompida, siga a seção "Como retomar" do ORQUESTRADOR: o `status` de cada task em `tasks.md` mais `BLOQUEIOS.md` dizem onde você parou.

Se esta ocorrência nasceu em worktree (regra 16), a mergex — ao ser acionada no início deste estágio — encontra a branch já criada pelo E1 e **retoma** nela em vez de criar outra, porque o nome e a base já batem com a regra dela.

## Frontmatter: o YAML e a prosa andam juntos

Leia `references/00-schema.md` antes da primeira gravação. Neste estágio a skill escreve em arquivos que já têm frontmatter, e **toda atualização de status acontece nos dois lugares: no frontmatter E na prosa**. Nunca atualize um sem o outro — prosa e YAML divergentes quebram o painel e a retomada de sessão.

Ao mexer no `status` de uma task em `tasks.md`, reescreva no frontmatter:

- `status` da task — `pendente` → `em_andamento` → `concluida` (ou `bloqueada`);
- `concluida_em` — a data (`date +%Y-%m-%d`) ao concluir; `null` enquanto não estiver `concluida`;
- `suite` — `nao_executada` → `parcial`, `verde` ou `vermelha`, conforme a última execução para aquela task: `parcial` quando rodou o subconjunto afetado, `verde` quando rodou a suíte inteira, `vermelha` quando houve falha;
- `atualizado_em` do arquivo, a cada gravação.

Ao registrar um bloqueio, acrescente o item à lista `bloqueios:` de `BLOQUEIOS.md` (`kind: bloqueios`) além da linha `B-NN` na prosa, com `resolvido_em: null`.

Ao fechar uma fase ou uma sprint, atualize o `status` correspondente no frontmatter de `fases.md` e de `sprint.md` (`concluido`, vocabulário masculino).

**O `estagio` do `ORQUESTRADOR.md` é atualizado a cada transição de estágio da máquina de estados** — ao entrar no E3, `estagio: e3`; ao entregar para o E4, `estagio: e4`. Reescreva também `atualizado_em`. O campo `concluido_em` do orquestrador só é preenchido no E5.

Na mesma transição, grave `fase` em `.expx/estado.json` pelo procedimento de `references/06-estado.md` — `fase: e3` ao entrar, `fase: e4` ao entregar. É um arquivo derivado: sem `.expx/` no projeto, siga sem gravar, sem erro e sem aviso; se a gravação falhar, registre no rastro e siga.

## Passo 2 — A ordem do TDD, task a task

Ordem de execução: sprints em ordem numérica estrita; dentro da sprint, a rota do ORQUESTRADOR. Só execute em paralelo o que o plano declarou `paralelizavel: true`. Uma task só começa quando todas em `depende_de` estão `concluida`.

### Task reivindicada por outra sessão

Antes do passo 1, quando houver mais de uma sessão trabalhando na mesma ocorrência (regra 16, "Sessões paralelas" do `SKILL.md`): leia `docs/eventos/<trabalho_id>.jsonl` e procure, para a task que você está prestes a abrir, o `task_iniciada` mais recente. Se ele foi gravado por outra `sessao` e não há `task_concluida` nem `task_bloqueada` dela depois, a task está reivindicada — não a abra. Pule para a próxima task paralelizável cujas dependências estão satisfeitas; se não houver nenhuma, registre em `BLOQUEIOS.md` (`B-NN | task | reivindicada pela sessão S | aguardar liberação`) e siga a "Regra de bloqueio" abaixo. Rastro sem `sessao` (linha antiga) conta como a mesma sessão: nunca avisa por falta de dado.

Para CADA task, exatamente nesta ordem, sem inverter nenhum passo:

1. Marque `status: em_andamento` em `tasks.md`, e grave `task` com o id dela em `.expx/estado.json` (`references/06-estado.md`). Registre no rastro:

   ```
   RX="$(git rev-parse --show-toplevel)" || RX=.; H="$RX/.claude/runx-hooks"; [ -f "$H/comum/expx_rastro.py" ] || H="$RX/.claude/hooks"; python3 "$H/comum/rastro.py" --evento task_iniciada --fase e3 --task <T-NN.MM>
   ```
2. **Escreva o teste. Rode. Ele TEM que falhar.** Nenhuma linha de implementação antes de ver o vermelho. Na primeira task da primeira fase, este é o `teste_regressao`: o teste que reproduz o problema.
3. **Implemente o mínimo para o teste passar.** Mínimo é literal: só o que faz o vermelho virar verde. Nada de refactor de brinde, nada de "já que estou aqui" — aplique o invariante 5 do `SKILL.md`.
4. **Escreva os dois testes da task** — `teste_integracao` e `teste_funcional` — exatamente como a task os descreve, e faça-os passar.
5. **Rode o subconjunto afetado pela task.** Os testes que ela criou ou alterou, mais os que cobrem os arquivos em `arquivos.cria` e `arquivos.altera` — não a suíte inteira. Com o subconjunto verde, a task grava `suite: parcial`.

   A suíte inteira roda **uma vez, no E4**, antes do veredito (regra 9). Rodá-la ao fim de cada task custa uma execução completa por task e não descobre nada que a execução do E4 não descubra — só descobre mais cedo, ao preço de repetir tudo N vezes. Se o subconjunto ficar difícil de delimitar, rode a suíte inteira e grave `suite: verde`: o valor mais forte nunca é violação.

   Um ponto que não muda: **task com teste vermelho não fecha**, seja o subconjunto ou a suíte inteira. `parcial` significa "o que era desta task passou", nunca "passou mais ou menos".
6. Antes de aceitar o verde, responda: **este teste falharia com uma implementação errada?** Se a resposta é não, o teste não discrimina — reescreva-o e volte ao passo 2.

   Quando o vermelho do teste de regressão estiver estabilizado e antes do fix final,
   chame o `runx-revisor-testes` uma vez. Registre o digest do teste; só repita se esse digest
   mudar. Ele devolve a tabela de achados e `TESTES: DISCRIMINAM` ou
   `TESTES: NÃO DISCRIMINAM`, sem corrigir. Siga a política comum de
   `references/06-estado.md`.

   Na primeira task da primeira fase, peça a ele a checagem que mais falha em silêncio: **o `teste_regressao` realmente falhava antes do fix?** Ele confirma contra o código anterior (`git worktree`, `git show`) e devolve `REGRESSÃO PROVA` ou `REGRESSÃO NÃO PROVA`. `NÃO PROVA` cai na regra abaixo — para a execução e volta ao E1.

   Registre no rastro:

   ```
   RX="$(git rev-parse --show-toplevel)" || RX=.; H="$RX/.claude/runx-hooks"; [ -f "$H/comum/expx_rastro.py" ] || H="$RX/.claude/hooks"; python3 "$H/comum/rastro.py" --evento veredito_emitido --agente runx-revisor-testes \
     --fase e3 --task <T-NN.MM> --resultado <discriminam|nao_discriminam> --detalhe "N achados"
   ```
7. Verifique **de fato** o `criterio_aceite` da task — não presuma que ele decorre do teste verde.
8. **Revisão por task.** Com o critério de aceite verificado, e antes de marcar a task concluída, rode a revisão por task do núcleo do expx (contrato `expx-revisao`). A evidência que ela grava, `docs/entregas/<OC-ID>/revisao/<T-NN.MM>.json`, entra no commit da task pelo E1 da mergex, que só a aceita junto do produto da task: rodar a revisão depois do commit não cria evidência para ele, e um commit só com ela é recusado.

   **Primeiro, o modo.** Com o leitor do núcleo instalado, ele roda sempre, e o modo é o `revisao_por_task.modo` que ele imprime: sem `.expx/fatiamento.json`, ele imprime o padrão, `se_disponivel`; uma pasta ou um link quebrado no lugar do arquivo o fazem falhar.

   ```
   RAIZ="$(git rev-parse --show-toplevel)"; N="$RAIZ/.expx/marketplace/plugins/expx/nucleo/scripts"
   if [ -f "$N/expx-fatiamento.mjs" ]; then node "$N/expx-fatiamento.mjs" --formato json --raiz "$RAIZ"
   elif [ -e "$RAIZ/.expx/fatiamento.json" ] || [ -L "$RAIZ/.expx/fatiamento.json" ]; then echo "sem leitor"; fi
   ```

   Com o leitor falhando, ou sem o leitor e com qualquer entrada `.expx/fatiamento.json` (arquivo, pasta ou link; o bloco imprime `sem leitor`), o modo não pode ser conhecido: não rode a revisão, a task não fecha, e o bloqueio é `prerequisito_ausente` ("atualize o expx"). Sem o leitor e sem entrada nenhuma, vale o padrão, `se_disponivel` (limite: sem o leitor, uma pasta sem permissão de leitura esconde o arquivo, e vale o padrão). Com `desligada`, pule o resto deste passo.

   **Depois, só com `se_disponivel` ou `obrigatoria`, a revisão.** Sem o `expx-revisao.mjs`, trate como a saída 2.

   ```
   RAIZ="$(git rev-parse --show-toplevel)"; N="$RAIZ/.expx/marketplace/plugins/expx/nucleo/scripts"
   node "$N/expx-revisao.mjs" revisar --trabalho "<OC-ID>" --task "<T-NN.MM>" --raiz "$RAIZ" --arquivos "<arquivos.cria e arquivos.altera da task, separados por vírgula>"
   ```

   - **Saída 0** (`ok`): siga.
   - **Saída 1** com a última linha `<T-NN.MM> achados` (`achados`): há achado aberto: em linha que a task alterou, ou sem vínculo a uma linha de um arquivo da task (arquivo fora da task, ou sem linha). Corrija na própria task, rode de novo o subconjunto afetado e a revisão, até duas tentativas. Se persistir, registre o bloqueio: `revisao_defeito` quando o achado é real e não cabe na task, `revisao_contestada` quando você argumenta falso positivo, com o argumento. **Só o desenvolvedor rejeita** um achado (`expx-revisao.mjs rejeitar`): você classifica e contesta, nunca rejeita nem aceita o risco. Achado em linha que a task não alterou não bloqueia. Depois de um `rejeitar` do desenvolvedor que imprime `<T-NN.MM> ok`, a revisão da task está feita: siga ao passo 9 sem rodar o `revisar` de novo. A CLI varia entre chamadas e redescreve o mesmo ponto com outra identidade, o que reabre o achado e troca a evidência que o desenvolvedor fechou. Só revise de novo se um arquivo da task mudou depois do último `revisar`. Se ele mudou antes do `rejeitar`, o `rejeitar` recusa (`evidencia desatualizada: <arquivo>`, saída 1, nada gravado): rode o `revisar` de novo, não rejeite. O achado "o lock não foi atualizado", sobre um `package-lock.json` da task alterado junto com o `package.json`, é falso positivo conhecido (o lock não vai à CLI; contrato `expx-revisao`, "Orientação ao consumidor"): `revisao_contestada`, com o diff do lock como argumento, mostrando nele a mesma mudança do `package.json` (a versão ou a dependência nova), e com a instalação congelada do lockfile (`npm ci` ou equivalente) passando com ele. Se o lock não traz a mudança, ou se a instalação congelada o recusa por não bater com o `package.json`, o achado é real: corrija o lock na task. Se ela falha por outro motivo (rede, registro, script de instalação), não há prova: registre a contestação com essa falha, e o desenvolvedor decide. A instalação congelada troca as dependências instaladas pelas do lock: rode de novo o subconjunto afetado antes de concluir a task.
   - **Saída 2** (`indisponivel`): nem a CodeAnt nem o Codex revisaram. Com o núcleo 0.14.0 ou mais novo, com a CodeAnt fora (ausente, sem acesso, com erro ou fora do prazo), o próprio núcleo já escalou para o Codex, e o resultado é o dele (saída 0, 1 ou 3); a saída 2 vem só quando ele também falhou (`<motivo da CodeAnt>+codex-<motivo>`) ou quando a falha não escala (`snapshot`, `arquivo-mudou-durante-revisao`, erro do pedido); com um núcleo anterior, a saída 2 é só a CodeAnt fora, sem a tentativa do Codex. A rota de cada motivo está na "Orientação ao consumidor" do contrato `expx-revisao`, e você nunca chama o Codex. Em `se_disponivel` é aviso, que vai no detalhe da conclusão, e a task segue. Em `obrigatoria`, a task não fecha: bloqueio `prerequisito_ausente`. Depois de uma saída 1, a saída 2 de uma nova tentativa não fecha a task, em nenhum modo: nada confirmou que o achado saiu, e a evidência nova apagaria o registro dele. O bloqueio é `prerequisito_ausente`, com o achado na descrição. Nunca rode `codeant login` nem `codex login`, nem defina credencial.
   - **Saída 3** (`incompleta:<motivo>`): bloqueio `revisao_incompleta`, com a rota do motivo na tabela "Orientação ao consumidor" do contrato `expx-revisao` (`L1`: dividir a task; `lote-falhou`: revisar de novo a task inteira).
   - **Saída 64 ou 75**: uso errado, ou evidência travada por outra execução. Com 75, espere e repita uma vez. Se persistir, ou com 64, bloqueio `prerequisito_ausente`, com a saída.
   - **Outra saída** (`127` sem o `node`, `70` erro interno do núcleo, ou a saída 1 sem a linha `<T-NN.MM> achados`, por exemplo): a revisão não rodou; trate como a saída 2.

   O bloqueio segue a "Regra de bloqueio" abaixo, com a classe no começo da descrição (`B-NN | T-NN.MM | revisao_incompleta: L1 | dividir a task`). A evidência fica na árvore para o E1, inclusive com `indisponivel`.
9. Só então marque `status: concluida` em `tasks.md` — **no frontmatter e na prosa** — acrescentando na linha da task: data (obtenha com `date +%Y-%m-%d` do sistema, nunca de memória) e resultado da suíte. No YAML, isso significa `status: concluida`, `concluida_em` com a data e `suite: parcial` (ou `verde`, se você rodou a suíte inteira), mais `atualizado_em` reescrito. Em seguida grave em `.expx/estado.json` (`references/06-estado.md`) o novo `tasks_concluidas` e o `task` da próxima task a ser aberta — `null` quando não houver próxima. Registre no rastro:

   ```
   RX="$(git rev-parse --show-toplevel)" || RX=.; H="$RX/.claude/runx-hooks"; [ -f "$H/comum/expx_rastro.py" ] || H="$RX/.claude/hooks"; python3 "$H/comum/rastro.py" --evento task_concluida --fase e3 --task <T-NN.MM> --detalhe "revisao: <resultado>"
   ```

   O `<resultado>` é o que o `revisar` imprimiu depois do id da task (`ok`, `indisponivel:<motivo>`), ou `desligada` quando o passo 8 foi pulado.

Critério de aceite não atendido, ou qualquer teste não passando: a task **NÃO** é concluída. **Não existe "concluído com ressalva".**

### A cor do nó no grafo de tasks

O `fases.md` da sprint carrega um bloco Mermaid com o grafo de tasks, gerado no E2. Ao mudar o `status` de uma task, **atualize a cor do nó daquela task** — e só dela: reescreva apenas a linha `class` correspondente. Nós, arestas, `subgraph`, `classDef` e a linha do `critico` permanecem como o E2 os escreveu. Não recalcule o caminho crítico e não reescreva o bloco: a estrutura do grafo não muda durante a execução, só a cor muda. O mapa de status para classe está em `references/07-diagrama.md`.

Isso vale nas duas transições da task: ao marcá-la `em_andamento` no passo 1, e ao marcá-la `concluida` (ou `bloqueada`) no passo 9. A gravação vai junto da gravação do `tasks.md` que você já está fazendo — é a mesma passada no disco, não uma segunda.

**Falha na atualização é registrada e ignorada.** Se o bloco não estiver lá, se o nó não for encontrado, se o arquivo tiver outra forma: a task continua concluída, a suíte continua verde e o estágio continua avançando. A regra normativa do diagrama fica em `references/07-diagrama.md`:

```
RX="$(git rev-parse --show-toplevel)" || RX=.; H="$RX/.claude/runx-hooks"; [ -f "$H/comum/expx_rastro.py" ] || H="$RX/.claude/hooks"; python3 "$H/comum/rastro.py" --evento diagrama_nao_atualizado --fase e3 \
  --task <T-NN.MM> --resultado falha --detalhe "<o motivo, uma linha>"
```

Se este for um retorno do E4 e o E2 tiver replanejado, o bloco inteiro já foi regerado pelo E2 — o E3 nunca remenda um grafo cujo conjunto de tasks mudou. E se o `fases.md` não tiver bloco Mermaid nenhum (plano gerado por uma versão anterior da skill), o E3 **não o cria**: gerar diagrama é papel do E2. Siga sem avisar.

## Quando o teste de regressão passa antes do fix

Se o teste de regressão passa **antes** de qualquer implementação, ele não está reproduzindo o problema. Isso significa uma de duas coisas, e as duas invalidam o plano:

- o teste está errado — testa outra coisa, ou outra entrada, ou outro caminho; **ou**
- a causa raiz está errada — o problema não vive onde o `01-CAUSA-RAIZ.md` afirma.

Nos dois casos: **PARE a execução, volte ao E1** e registre isso. Escreva no `01-CAUSA-RAIZ.md` o que foi observado (o teste, a entrada usada, o resultado verde inesperado), reabra a investigação e refaça o E2 se a causa mudar. Nunca ajuste o teste até ele ficar vermelho para poder seguir: isso fabrica uma falha e esconde o defeito real.

## Regra de bloqueio — nunca parar, nunca perguntar

Surgiu dúvida nova, decisão não coberta pelo plano, pré-requisito faltando (segredo inexistente, serviço fora do ar, dependência quebrada, dado de produção indisponível):

1. Registre em `docs/manutencao/<OC-ID>-<slug>/BLOQUEIOS.md`: `B-NN | task | descrição do bloqueio | o que destravaria`.
2. Marque a task como `status: bloqueada` em `tasks.md`. Registre no rastro: `RX="$(git rev-parse --show-toplevel)" || RX=.; H="$RX/.claude/runx-hooks"; [ -f "$H/comum/expx_rastro.py" ] || H="$RX/.claude/hooks"; python3 "$H/comum/rastro.py" --evento task_bloqueada --fase e3 --task <T-NN.MM> --detalhe "<motivo, uma linha>"`.
3. Grave `bloqueios` em `.expx/estado.json` (`references/06-estado.md`) com a contagem de bloqueios **em aberto**. Ao resolver um bloqueio depois, grave a contagem nova.
4. Pule para a próxima task paralelizável cujas dependências estão satisfeitas.
5. **NUNCA pare para esperar resposta humana.** Se não resta nenhuma task executável, encerre com o relatório final — os bloqueios são a pauta do usuário, não uma conversa sua.

## Portões de fase e de sprint

- Fase só é dada como concluída quando seu **critério de saída** em `fases.md` é verdade.
- Sprint só é dada como concluída quando seu **critério de saída** em `sprint.md` é verdade.
- Critério não atendido = **não avança** para a próxima fase/sprint; trate como bloqueio se não houver task que o resolva.
- Entre sprints a execução é sempre sequencial: o paralelismo declarado existe entre tasks e entre fases, nunca entre sprints.

## Passo 3 — Relatório de encerramento do estágio

Ao terminar (tudo concluído, ou nada mais executável), entregue ao usuário um relatório com exatamente estas seções:

1. **Concluído por sprint** — por sprint: tasks concluídas / total, e o que ficou funcionando.
2. **Bloqueios** — o conteúdo de `BLOQUEIOS.md` (ou "nenhum").
3. **Saída da suíte** — o resultado da última execução completa da suíte, colado, não resumido de memória.
4. **Divergências entre o plano e a realidade** — tudo que foi diferente do planejado, uma linha por divergência.

Este relatório é para o usuário na conversa; ele **não** substitui os relatórios do E5.

## Critério de saída do estágio

- [ ] Toda task está `concluida` ou `bloqueada` (nenhuma `pendente`/`em_andamento` executável restante).
- [ ] `tasks.md` atualizado com data e resultado da suíte em cada task concluída.
- [ ] Toda task concluída tem `suite: parcial` ou `suite: verde` — nenhuma com `vermelha` ou `nao_executada`. A suíte inteira é exigida no E4, não aqui.
- [ ] Nenhum arquivo fora da lista de impactados do `01-CAUSA-RAIZ.md` e de `tasks.md` foi alterado. A evidência da revisão por task (`docs/entregas/<OC-ID>/revisao/<T-NN.MM>.json`, passo 8) é artefato do método, não escopo.
- [ ] Toda task `concluida` tem `task_iniciada` e `task_concluida` gravados no rastro.
- [ ] Relatório de encerramento entregue com as 4 seções.
- [ ] Frontmatter e prosa consistentes em todo arquivo tocado: `tasks.md`, `fases.md`, `sprint.md`, `BLOQUEIOS.md` e o `estagio` do `ORQUESTRADOR.md`.

## Ao terminar

Anuncie: "E3 concluído. N tasks concluídas, M bloqueadas. Próximo estágio: E4 QA." Siga para o E4 lendo `references/04-qa.md`.

Ao fazer a transição, registre o marco E3→E4 pelo contrato de `references/06-estado.md`.
