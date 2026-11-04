# 06 — Jornada dos atendimentos até a entrega

Validação local em 26/10/2026. Nenhum deploy, commit, push, operação de produção, migração ou mensagem externa foi realizado. Foram usados dados sintéticos e projetos `demo-*` no Firestore Emulator.

## Inspeção e diagnóstico reconfirmado

Git e os arquivos da jornada foram examinados antes das edições. Não foram encontrados AGENTS.md aplicáveis no repositório e ancestrais. A árvore já continha alterações extensas, inclusive mediação, comissão, repasses, caixa e reputação; elas foram preservadas. A lista de solicitações agrupava encerramentos comerciais e não distinguia contratação de entrega. A resposta/aceite antigos não fixavam uma versão imutável e revisada da proposta. O fake de CotacaoRepository já retornava o Map exigido pelo contrato real; foram preservadas suas verificações e acrescentada cobertura explícita dos argumentos de responderCotacao, sem trocar o contrato do método.

## Comportamento implementado

A lista agora separa aguardando, propostas respondidas, negociação, contratadas, entregas aceitas e encerradas sem contrato. Cada atendimento possui detalhe navegável com cliente autorizado, evento/data/local, escopo, itens, condições, preço, descontos, validade, versões, histórico, próxima ação, responsável, prazo disponível, conversa existente e acompanhamento financeiro restrito ao próprio orçamento. Ganhar a negociação não registra entrega ou recebimento.

| Legado comercial | Leitura da jornada | Execução |
| --- | --- | --- |
| pendente/sem resultado | nova solicitação | sem compromisso presumido |
| respondido/respondida/parcial | proposta enviada | sem entrega presumida |
| fechado/fechada/concluida/concluido na participação | ganho | lida do orçamento vinculado |
| perdeuCotacao | perdido | não contratado |
| recusado/recusada | recusado | não contratado |
| cancelado/cancelada | cancelado | não contratado |

O estado explícito `estado_comercial` prevalece. `concluida` no documento da cotação continua significando encerramento comercial compatível com os consumidores existentes; somente `estado_execucao=aceito` permite tratar o serviço como entrega aceita.

A preparação usa o mecanismo existente de execução: `nao_iniciado → agendado → em_execucao → entrega_informada → aceito/contestado`. Fornecedor agenda, inicia e informa entrega; cliente autorizado aceita/contesta. A compatibilidade anterior permite informar entrega diretamente de nao_iniciado/agendado. Contestação não pode ser sobrescrita por nova informação unilateral do fornecedor; segue a mediação existente. Os comandos registram revisão, autor, estado anterior/novo e data do servidor. Nenhum desses comandos aceita repasse ou altera o dinheiro recebido. O comando financeiro legado também recusa substituir o preço da proposta aceita; repetição com o mesmo preço preserva o contrato sem reabrir execução. Regras impedem alterar diretamente os valores/escopo/condições/status dessa contratação ou apagar seu documento.

## Identidade, versões e concorrência

- Cada versão de proposta é imutável em `cotacao/{cotacao}/fornecedores/{fornecedor}/propostas/{versao}`. Inclui itens, escopo, bruto/desconto/líquido em centavos, condições, validade, previsão opcional, autor e assinatura. Os novos cálculos usam inteiros; a entrada antiga em reais usa `Math.round(valor * 100)` apenas na fronteira de compatibilidade.
- Aceite exige versão e assinatura efetivamente apresentadas ao cliente. Revisão concorrente, validade vencida, autoria de fornecedor ou aceite em nome de terceiro são recusados. A confirmação captura a versão exibida; não aceita silenciosamente uma revisão que chegou durante o diálogo.
- Contratação cria atomicamente o orçamento existente, obrigação/parcela e gasto contratual, vínculo da cotação, vencedor/perdedores, histórico e mensagens de sistema. ID determinístico `cot_` + prefixo SHA-256 da cotação. A identidade financeira é o mesmo orçamento; não foi criado outro livro, contrato, chat ou sistema de mediação.
- Repetir o mesmo aceite devolve o mesmo contrato. Duas escolhas concorrentes não geram duas vendas. Aceite e cancelamento disputam o mesmo documento transacional.
- Propostas e transições têm chave estável e payload assinado: repetição idempotente; mesma chave com dados diferentes é recusada. Execução usa controle de revisão e histórico transacional no serviço financeiro existente.
- Antes da contratação, perda/recusa/cancelamento exigem motivo estruturado e descrição. Após contratar, proposta não pode ser reescrita ou cancelada pela antiga ação comercial. A opção explícita de solicitar alteração/cancelamento abre o caso existente de mediação, com autor, motivo e histórico. O preço aceito permanece congelado; a solicitação não é um aditivo aprovado nem dispara recálculo, estorno ou repasse automático.
- Legado ganho busca orçamento existente pela cotação e fornecedor. Espelhos com a mesma identidade canônica são deduplicados; vínculo ausente, ambíguo ou divergente é sinalizado/recusado, sem fabricar contrato. Propostas antigas sem versão/validade precisam ser revisadas e emitidas pelo fornecedor antes de novo aceite; contratos antigos já firmados continuam consultáveis. Nenhuma migração foi executada.

## Autorização, privacidade e sessão

As callables restringem o detalhe aos participantes reais; não oferecem bypass administrativo para a conversa. O DTO não contém orçamento global do evento, custos privados ou propostas de outros fornecedores. As páginas financeiras aceitam o ID do orçamento e filtram a apresentação do contrato solicitado. Campos de contrato aceito, revisão e agendamento ficam protegidos nas regras; concessões genéricas das subcoleções excluem propostas, histórico, mensagens e serviços. Mensagens de sistema continuam usando o esquema/caminho existente e agora podem integrar a mesma transação.

A conversa continua disponível para o vencedor nas etapas operacionais autorizadas. Perdido/recusado/cancelado não é reaberto. Marcação de leitura só marca a mensagem: não aceita proposta, entrega nem repasse. Assistência de IA permanece com revisão humana; não foi introduzido envio automático.

Consultas e formulários descartam resultados da sessão antiga. Comando com resultado desconhecido mantém payload/chave local, inclusive após reabrir, até retomada explícita; outra jornada não executa o comando pendente da anterior. O transporte usa o gateway autenticado já existente, inclusive HTTPS no Windows. A extração desse adaptador comum mantém a API do datasource de reputação.

Prazos inexistentes são exibidos como não informados. Validade comercial não vira prazo operacional após contratar; o agendamento explícito é usado apenas nas etapas pertinentes.

## Arquivos da entrega

Backend: `functions/src/services/cotacao/jornadaAtendimentoService.ts`; wrappers responder/fechar/cancelarCotacao; `mensagensSistemaCotacao.ts`; `acompanhamentoPartesService.ts`; `acompanhamentoPersistenciaService.ts`; `comandosAcompanhamentoPartes.ts` (vínculo canônico do caso); `functions/src/index.ts`; `contratoFinanceiroService.ts` (proteção do aceite contra comando legado); `shared/transacaoIdempotente.ts`; `firestore.rules`.

Flutter: entidade/modelo Cotacao e nova entidade jornada; datasource/controller/lista de solicitações; nova página/controller/remote da jornada; adaptador do antigo bottom sheet; CotacaoController e rotas; páginas de acompanhamento fornecedor/organizador; gateway de sessão compartilhado e alias compatível do datasource de reputação.

Validação: `functions/scripts/testJornadaAtendimentosEmulator.js`; fixture versionada de `testRepasseOperacionalEmulator.js`; `testTransacaoIdempotente.js`; `test/features/cotacoes/jornada_atendimento_test.dart`, `cotacao_repository_test.dart`, `solicitacoes_controller_test.dart`; script `test:jornada:atendimentos` em package.json; este documento.

## Comandos e resultados reais

PowerShell; JDK 21 disponível em `$env:TEMP/codex-chat-jdk/jdk-21.0.12.1+1`. JAVA_HOME/PATH foram ajustados somente no processo de teste. Firebase CLI executou emuladores locais sem produção.

1. `npm --prefix functions run build`: TypeScript compilado com sucesso.
2. `npm --prefix functions run check:financeiro`: sucesso; inclui compilação estática e regressões de domínio financeiro, comissão, execução/mediação, conciliação e autorização. Repetido após a proteção do preço aceito, também com sucesso. Log final: `$env:TEMP/jornada-financeiro-check-final.log`.
3. `flutter test test/features/cotacoes test/features/cotacao test/features/financeiro/acompanhamento_partes_test.dart test/features/financeiro/resolucao_mediacao_widget_test.dart test/features/financeiro/financeiro_contratos_unificado_test.dart test/features/financeiro/mediacao_operacional_test.dart test/features/avaliacoes/gestao_reputacao_test.dart --reporter expanded`: **59 testes passaram**, incluindo domínio, controller, widgets e regressões. Log: `$env:TEMP/jornada-flutter-final.log`.
4. Após corrigir o nome público da callable existente de mediação, `flutter test test/features/cotacoes/jornada_atendimento_test.dart --reporter expanded`: **11 testes passaram**. Cobre formulário, confirmação da versão exibida, etapas operacionais, separação comercial, falha/retry, sessão invalidada, pedido pós-aceite e retomada idempotente. Log: `$env:TEMP/jornada-widget-final.log`.
5. `firebase emulators:exec --project demo-jornada-atendimentos --only firestore "node functions/scripts/testJornadaAtendimentosEmulator.js && node test/firestore/atendimentos.rules.test.js"`: **sucesso**, incluindo **116 verificações de regras**, isolamento, collectionGroup e sobreposições. Negações PERMISSION_DENIED no log são resultados esperados dos assertFails. Log: `$env:TEMP/jornada-emulador-final.log`.
6. `firebase emulators:exec --project demo-repasse-operacional --only firestore "node functions/scripts/testRepasseOperacionalEmulator.js"`: **sucesso** após adequar a fixture ao aceite versionado/idempotente. Comissão externa parcial/integral, pagador organizador, autorização, retenção, mediação, concorrência, idempotência e regras preservados. A primeira execução detectou a fixture antiga sem versão; a correção passou pelo fluxo real de proposta, sem relaxar a autorização. Log: `$env:TEMP/jornada-repasse-regressao.log`.

7. Rodada final após todas as proteções: build TypeScript, `node functions/scripts/testTransacaoIdempotente.js` e `firebase emulators:exec --project demo-jornada-atendimentos --only firestore "node functions/scripts/testJornadaAtendimentosEmulator.js && node test/firestore/atendimentos.rules.test.js"`: **sucesso, código 0**. Incluiu disputa entre ofertas de dois fornecedores (um vencedor/um orçamento), aceite versus cancelamento (um resultado válido), recusa de reprecificação pelo comando legado, edição direta de valores/escopo e exclusão do contrato aceito, além das **116 verificações de regras**. Log: `$env:TEMP/jornada-concorrencia-final.log`. O comando reproduzível `npm run test:jornada:atendimentos` reúne build, teste do reinício limitado e integração da jornada.

Os testes de integração chamam as implementações de callables com identidades sintéticas e Firestore real no emulador, além de clientes SDK autenticados do rules-unit-testing. Não usam somente mocks: concorrência, transações, persistência, chat, regras, vínculo financeiro e criação de avaliação após aceite foram exercitados no emulador. Widgets usam doubles para controlar respostas, timeout e troca de sessão de forma determinística.

A análise estática direcionada (`dart analyze` dos controllers/página/modelos/entidades/datasources/rotas/integrações alterados e `test/features/cotacoes`) terminou com **No issues found**. Log: `$env:TEMP/jornada-analyze.log`. `git diff --check` no escopo da entrega também passou.

Durante repetições com seis comandos concorrentes, o emulador retornou ocasionalmente gRPC 3, “Transaction is invalid or closed”, após timeout de lock. Foi implementado reinício limitado da transação idempotente para essa falha específica, sem repetir erros de autorização/validação nem efeitos externos. `node functions/scripts/testTransacaoIdempotente.js` passou: recuperação, limite de tentativas e preservação de erros de negócio. A interface mantém o pedido original se o resultado continuar desconhecido.

## Índices e limites de validação

Não foi necessário índice composto novo. As consultas novas usam documentos/subcoleções e igualdade simples por id_cotacao, id_orcamento ou chave_idempotencia; não foi ampliado o acesso para contornar consultas. Índices automáticos existentes foram suficientes no emulador.

Não foram executados deploy, migração, teste manual no aplicativo Windows instalado, nem ciclo HTTP com Firebase Auth hospedado. Os testes validam a lógica das callables, persistência real emulada e interface Flutter separadamente; não afirmam prova ponta a ponta em produção. A solicitação de alteração pós-aceite segue a decisão humana no mecanismo de mediação existente e mantém os valores congelados, sem inventar aprovação contratual ou financeira.
