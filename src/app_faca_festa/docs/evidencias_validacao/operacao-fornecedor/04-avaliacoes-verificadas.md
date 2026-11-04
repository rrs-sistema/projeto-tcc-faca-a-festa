# Prompt 04 — Avaliações verificadas e protegidas

Validação local em 26/10/2026, Windows/PowerShell. Nenhum deploy, commit, push ou migração em produção. Todos os dados de integração são sintéticos, em projeto `demo-avaliacoes-verificadas` no emulador Firestore.

## Reconferência

Git foi examinado antes das edições. A árvore já continha trabalho amplo dos prompts anteriores e alterações de outras funcionalidades; esse trabalho foi preservado. Não foram encontrados AGENTS.md aplicáveis no repositório ou ancestrais.

Confirmados: escrita autenticada geral em `avaliacao_fornecedor`, `avaliacoes`, `fornecedor_avaliacoes` e nas avaliações de `fornecedor_servico`; regra genérica do fornecedor também alcançava avaliações aninhadas; criação aleatória em subcoleções e checagem de duplicidade em outra coleção; elegibilidade baseada em participação de cotação/contratação, sem entrega; ranking calculava notas diretamente e a recomendação juntava coleções/aliases, podendo repetir avaliações. O trigger antigo recalculava reputação usando legado e poderia sobrescrever uma atualização mais recente. Agregados do cadastro também eram graváveis pelo dono.

O serviço `avaliacao_autonomia_calculadora_service.dart` trata avaliação de sessões de calculadora e não implementa reputação. Foi criada implementação pertinente em Functions, reutilizando autenticação e identidade financeira da contratação existentes.

## Formato canônico e política

Canônico: `fornecedor/{idFornecedor}/avaliacoes/{sha256}`. A identidade é SHA-256 do array JSON `[uidDaSessao, idContratoCanonico, objeto]`. Objeto é `fornecedor` ou `servico:{idServico}`. Alias de orçamento com o mesmo `contrato_financeiro.id_contrato` não cria nova avaliação. Não se grava um espelho de serviço como outra avaliação do fornecedor.

Schema 2 inclui `tipo`, `verificada`, contratação, orçamento de origem, fornecedor, serviço quando aplicável, cliente da sessão, nome obtido do perfil, evento, nota, comentário, `data` do servidor e estado de publicação. Nenhum ID/nome de autor ou data enviado pelo cliente é aceito. O adapter Flutter mantém os argumentos antigos por compatibilidade de interface, mas não os transmite como autoria.

Uma avaliação por autor/contratação/objeto. Replay com nota/comentário normalizados iguais é idempotente; payload novo para a mesma identidade recebe `already-exists`. Nota/comentário são imutáveis, inclusive para fornecedor e autor. A interface explica essa política antes do envio. Não existe nova avaliação comercial: os caminhos anteriores agora exigem entrega aceita e não atribuem nota de entrega a uma cotação enviada.

Nota deve ser número inteiro finito de 1 a 5. Comentário é opcional; quando presente, tem 3 a 500 caracteres após trim, com limite também no texto recebido. Campos desconhecidos são rejeitados. Datas vêm de `serverTimestamp`.

## Elegibilidade e segurança

`registrarAvaliacaoVerificada` exige sessão com perfil ativo. Dentro da transação, relê orçamento, evento, vínculo e histórico. Exige contratação ativa, estado de execução `aceito`, cliente correspondente ao organizador ou solicitante autorizado da contratação e evento não cancelado. O estado sozinho não basta: deve existir registro da jornada `aceitar`, com papel cliente e autor entre esses contratantes autorizados, ou resolução administrativa `resolver_mediacao` para estado aceito. Contrato fechado, evento finalizado, entrega só informada, execução em andamento/contestada/cancelada e participação comercial não comprovam entrega.

Objeto de serviço deve corresponder ao serviço do orçamento e ao cadastro do fornecedor. Autoavaliação, outro cliente, outro fornecedor e usuário sem vínculo são negados. Regras também impedem relincar a identidade de uma contratação já canonicalizada/aceita para aproveitar sua prova de conclusão.

Avaliação, histórico inicial e agregados são escritos atomicamente. Flags `schema/verificada` isoladas não comprovam origem: a transação confere identidade e histórico inicial protegido, incluindo vínculo, nota e comentário. O datasource também confere esse histórico antes de atribuir o selo; o modelo recebe uma confirmação transitória, sem persistir uma nova autodeclaração. A transação lê a identidade determinística e o conjunto canônico; conflitos concorrentes são reavaliados pelo Firestore. Não há atualização assíncrona de nota média pelo trigger.

Regras dos cinco caminhos de avaliação e do histórico são somente leitura autenticada, com escrita direta negada. `avaliacoes` foi excluída da concessão genérica do fornecedor. Documentos de fornecedor e serviço protegem agregado verificado, aliases de média/quantidade, selos e posição. Cadastro inicial não pode introduzir reputação falsa. Serializadores de perfil/serviço deixaram de enviar os agregados nas edições comuns. Cadastro de serviço com reputação não pode ser apagado/revinculado para ocultar a nota; cadastro sem agregado ainda mantém a rotina existente de exclusão. Edição comum de nome e criação legítima de orçamento continuam permitidas e foram testadas.

## Moderação e histórico

Callable `moderarAvaliacaoVerificada`: exige perfil ativo e custom claim **`moderar_avaliacoes: true`** emitida por backend confiável. Tipo administrador `A` sozinho não concede moderação. Nenhuma claim foi atribuída neste trabalho. O próprio fornecedor e o autor não moderam a própria avaliação, mesmo com a claim.

A ação muda somente publicação (`oculta`/`publicada`), exige motivo de 10 a 500 caracteres e preserva nota/comentário original. Grava histórico com autor, motivo, estado e snapshot anterior na mesma transação que os agregados. Repetir o mesmo estado é idempotente. Ocultar retira da lista normal e do cálculo; o histórico autenticado permanece consultável. Não se trata de apagar conteúdo por requisito de sigilo: essa política preserva a rastreabilidade da crítica e não oferece exclusão física.

## Média, quantidade e consumidores

`reputacao_verificada = {schema: 2, soma, quantidade, media}` é a projeção canônica. Média é soma/quantidade, sem arredondamento intermediário; formatação ocorre na interface. Agregado do fornecedor conta apenas objeto `fornecedor`; o agregado do serviço conta apenas aquele serviço. Avaliar os dois objetos não duplica o denominador de nenhum deles.

Foram ajustados datasource/controller de avaliações, ranking de serviços, modelo do fornecedor, modelo do vínculo de serviço, estatísticas do painel do fornecedor, localização/mapa, resumo inteligente local, seção de reputação, detalhe de serviço, recomendação backend e estatística pública. Todos os valores de reputação passam pelo agregado verificado ou pelo mesmo filtro no conjunto canônico. Sem schema verificado, reputação histórica não é apresentada como nova nota comprovada. Selos derivados usam média/quantidade verificadas; posição de categoria não é aceita como autodeclaração de cadastro.

Recomendação deixa de juntar avaliações gerais e subcoleções; consulta a projeção do fornecedor, inclusive quantidade zero sem recuperar média antiga. Cache salvo exige `reputacao_schema: 2`, impedindo reaproveitar ranking legado. O trigger preserva a invalidação dos caches e o aviso existente de nova avaliação verificada, mas não escreve agregados. Nenhum aviso externo foi enviado nos testes (fixtures sem token e invocação do trigger sem criação notificável).

O formulário lista contratações elegíveis via backend. Com duas ou mais, a seleção é explícita; sem entrega aceita, envio permanece desabilitado. Listeners são encerrados quando a sessão muda usando a abstração existente `streamDaSessao`. Falha de stream é exposta como indisponibilidade. Listas preservam comentários legados com identificação de histórico sem verificação; somente notas verificadas compõem as médias.

## Legado, consultas e índices

Coleções antigas permanecem legíveis e bloqueadas para novas escritas. O datasource lê histórico das três coleções gerais, avaliações antigas do fornecedor e do vínculo de serviço, sem promover selo, copiar para o canônico ou somar à nova nota. Datas ausentes/inválidas usam marcador de época no modelo, não uma data de criação atual inventada. Dados originais persistidos não são alterados.

Não é necessária migração para continuar lendo o histórico. Para revisão offline, `functions/scripts/planejarLegadoAvaliacoes.js` consome JSON local `[{path,data}]` e produz plano dry-run com origem, dados originais e ação de preservação. Não importa Firebase, não usa credenciais e não escreve remotamente. Vínculo aparente não é convertido em prova de entrega; promoções automáticas são zero.

```powershell
node functions/scripts/planejarLegadoAvaliacoes.js export-local.json > plano-local.json
```

O exemplo acima descreve o uso; não foi usado export de produção. O dry-run foi exercitado com fixture sintética pelo teste listado abaixo.

Não há nova consulta collectionGroup na aplicação. A consulta geral a `collectionGroup('avaliacoes')` é negada e testada. Consultas novas usam caminho canônico completo, filtro simples por evento no orçamento ou por fornecedor no legado; ranking mantém filtro existente por subcategoria. Não foi necessário índice composto novo ou alteração em `firestore.indexes.json`. Nenhum índice foi publicado.

## Comandos e resultados reais

```powershell
$env:JAVA_HOME=Join-Path $env:TEMP 'codex-chat-jdk/jdk-21.0.12.1+1'
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
npm run test:avaliacoes:verificadas
node functions/scripts/testPlanoLegadoAvaliacoes.js
node functions/scripts/testEstatisticasPublicas.js
```

Resultados: código 0 para build TypeScript, integração/regras Firestore, plano offline e estatísticas públicas. Log da integração: `$env:TEMP/avaliacoes-emulador-final.log`. As negações `PERMISSION_DENIED` do log são asserções negativas esperadas.

Cobertura real no emulador:

- Jornada existente executada no emulador: fornecedor informa entrega, avaliação é negada até o cliente registrar aceite pelo callable da jornada. Cliente da entrega aceita cria; cliente B, fornecedor avaliado, fornecedor B, usuário sem vínculo, administrador genérico e anônimo são negados.
- Nota zero/negativa/acima de cinco, NaN/infinito, fracionária/string, comentário excedente, autoria e data forjadas são rejeitados.
- Oito criações simultâneas iguais resultam em um documento, um histórico e incremento único. Duas simultâneas divergentes produzem um vencedor e um conflito.
- Replay e alias do mesmo contrato não duplicam nota. Payload novo não altera o comentário original.
- Sem aceite comprovado, entrega informada ou contrato apenas fechado não permitem avaliação. Serviço de outro objeto é negado.
- Agregados de fornecedor/serviço ficam separados; legado, inclusive flags de verificação sem histórico protegido, não entra; recomendação e estatística pública coincidem com a projeção real.
- Trigger atrasado/repetido não sobrescreve agregados.
- Moderação autorizada reduz/restaura quantidade, registra histórico e mantém o comentário. Autor/fornecedor/admin genérico não burlam a autorização.
- SDK cliente testa criação/update/delete em caminhos antigos e novos, regra sobreposta do fornecedor, histórico, agregados/aliases, exclusão de serviço avaliado, relincagem do contrato e collectionGroup. Atualização comum de perfil e criação legítima de orçamento passam.

```powershell
flutter test test/features/avaliacoes test/features/ranking test/features/fornecedor/fornecedor_recomendacao_controller_test.dart test/features/fornecedor/fornecedor_model_test.dart test/features/fornecedor/fornecedor_localizacao_controller_test.dart --reporter expanded
```

Resultado: **22 testes aprovados**, código 0. Log: `$env:TEMP/avaliacoes-flutter.log`. Inclui modelos/compatibilidade, histórico fora da média, agregados por objeto, resumo inteligente, ranking, recomendação, localização e formulário com seleção obrigatória de contrato/entrega aceita. Doubles de interface complementam a integração real, sem substituí-la.

Análise estática executada com `dart analyze` em datasources de avaliação/ranking/localização/fornecedor/recomendação, serviço AI local, entidades/modelos de avaliação/fornecedor/serviço, repository/usecase, módulo de avaliação, seção de reputação, detalhe de serviço e testes de avaliações. Resultado: **No issues found**, código 0; log `$env:TEMP/avaliacoes-dart-analyze.log`. Build `npm --prefix functions run build` executado no script principal, com TypeScript estrito e `noUnusedLocals`. `git diff --check` no escopo passou.

### Regressão das regras anteriores

```powershell
npx firebase emulators:exec --project demo-avaliacoes-verificadas --only firestore "node functions/scripts/testAvaliacoesVerificadasEmulator.js && node test/firestore/atendimentos.rules.test.js && node test/firestore/financeiro_fornecedor.rules.test.js"
```

Resultado: código 0. Além da integração de avaliações, passaram **116 verificações de atendimentos** e a suíte de isolamento dos custos privados (dono permitido, organizador/admin negados). Log: `$env:TEMP/avaliacoes-regras-regressao.log`.

## Arquivos alterados neste prompt

Backend: serviço novo `functions/src/services/avaliacoes/avaliacaoVerificadaService.ts`; `functions/src/index.ts`; trigger `novaAvaliacaoProcessar.ts`; `fornecedorRecomendacaoService.ts`; `obterEstatisticasPublicas.ts`; `firestore.rules`.

Flutter: datasources `avaliacao_servico_remote_datasource.dart`, `ranking_remote_datasource.dart`, `fornecedor_localizacao_remote_datasource.dart`, `fornecedor_remote_datasource.dart`, `fornecedor_recomendacao_remote_datasource.dart`; modelos `avaliacao_model.dart`, `avaliacao_servico_model.dart`, `fornecedor_model.dart`, `fornecedor_produto_servico_model.dart`; entidades `avaliacao.dart` e `avaliacao_servico.dart`; repository/implementação/usecase de avaliação; controller e diálogo de avaliação; `fornecedor_ai_service.dart`; `avaliacoes_section.dart`; `servico_detalhe_screen.dart`.

Verificação: `testAvaliacoesVerificadasEmulator.js`, `planejarLegadoAvaliacoes.js`, `testPlanoLegadoAvaliacoes.js`, ajuste de `testEstatisticasPublicas.js`; testes Flutter de controller, modelos e diálogo; script npm e este documento.

## Limites da evidência

Os callables foram invocados por `onCall.run` com contexto autenticado sintético, sobre Firestore real emulado; regras foram exercitadas por SDK cliente com sessões sintéticas. Não foi realizado login HTTP no Auth emulator, teste em aplicativo instalado, teste bancário, deploy nem leitura de dados reais. A claim de moderação exige provisionamento operacional confiável; não foi criada permissão para o administrador genérico nem alterado usuário real. Contratos legados sem prova de aceite não recebem verificação automática.
