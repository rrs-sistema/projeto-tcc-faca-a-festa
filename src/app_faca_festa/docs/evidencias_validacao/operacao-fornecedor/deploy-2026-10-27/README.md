# Publicação da operação do fornecedor — 27/10/2026

Autorização: pedido explícito do usuário para analisar e executar os deploys. Projeto confirmado em `.firebaserc`, `firebase.json` e inventário remoto: `faca-a-festa`. Nenhum AGENTS.md foi encontrado no repositório ou ancestrais consultados. Alterações locais preexistentes preservadas, sem commit/push.

## Diagnóstico e seleção

O cliente exige o resumo `origem=contratos_repasses`, mas o serviço publicado não atendia ao contrato esperado. O inventário remoto também mostrou 21 exports locais ausentes. Foram selecionadas 78 Functions por ausência ou dependência transitiva de fonte alterada (manifesto anexo), incluindo 57 atualizações e 21 criações. Separação em 64 Functions de operação/financeiro e 14 de reputação/consumidores. Rotinas de migração foram excluídas.

Os índices locais foram comparados aos publicados normalizando o campo implícito `__name__`: nenhum índice necessário ausente. Storage sem alteração neste escopo. Hosting não publicado: execução reportada pelo usuário é local e o defeito era de backend.

## Validação e correções antes da publicação

- `npm --prefix functions run build`: aprovado; compilação efetiva TypeScript, não o script de lint que apenas imprime Skipping lint.
- `npm --prefix functions run check:financeiro`: aprovado (fundação, concorrência, autorização, previsão, recebimentos, estoque, comissão, dashboard, simulação e integração de domínio).
- `flutter test test/features/financeiro/financeiro_contratos_unificado_test.dart test/features/cotacoes/jornada_atendimento_test.dart`: 22 aprovados.
- `dart analyze` do controller financeiro, gateway e diagnóstico: sem problemas.
- Emulador Firestore: execução restrita a projetos demo/loopback, usando `firebase.operacao-test.json` e `testOperacaoFornecedorIntegrada.js`.
- A primeira tentativa usou Java antigo e foi recusada. Foi selecionado o JDK21 local já existente, sem instalação adicional.
- Primeira rodada: 12/13 cenários aprovados; avaliação concorrente retornou código3 Transaction is invalid or closed em vez do conflito de payload esperado. Repetição isolada confirmou invalidação transacional sob concorrência.
- Avaliações passaram a reutilizar `shared/transacaoIdempotente.ts`, já empregado na agenda, que reinicia no máximo duas vezes apenas a transação invalidada/expirada pelo servidor. Identidade determinística, transação atômica, autorização, idempotência e conflito de payload mantidos.
- Segunda rodada: avaliações aprovadas; reputação apresentou o mesmo erro transitório. Os três comandos transacionais de resposta/denúncia/decisão passaram a reutilizar o mesmo helper. A consulta readOnly permanece inalterada.
- Teste de avaliação teve apenas diagnóstico de erro enriquecido; as assertivas de unicidade e código esperado foram preservadas.

## Publicação e conferência

- `firebase deploy --project faca-a-festa --only <Functions do manifesto core> --non-interactive`: 64 operações bem-sucedidas, Deploy complete.
- `firebase deploy --project faca-a-festa --only firestore:rules --non-interactive`: compilação aprovada e regras liberadas no Cloud Firestore.
- Smoke HTTP sem autenticação para resumo financeiro, jornada, agenda, planejamento e painel: todos retornaram401 UNAUTHENTICATED. Nenhum token de usuário foi coletado e nenhum comando financeiro foi executado.

## Limites

Testes integrados utilizam dados sintéticos e persistência no emulador. Validação local usa Node24; runtime publicado é Node22. Publicação e smoke anônimo não comprovam uma sessão autenticada ponta a ponta no navegador do usuário. Não houve migração de dados, cobrança, confirmação bancária, execução de comandos de negócio em produção ou envio de mensagens/notificações de teste.

## Repetições finais e limites da execução

A terceira rodada completa foi interrompida durante recebimentos após permanecer sem terminar; não foi classificada como aprovada. Esse cenário já havia passado nas duas rodadas anteriores, sem mudança posterior em seu código de produção. Os resultados por cenário dessas rodadas estão nos diretórios `10-logs/run-2026-10-27T14-54-09-218Z` e `10-logs/run-2026-10-27T14-59-04-890Z`.

Foi executada repetição isolada de avaliações e gestão de reputação no emulador porta8085. A primeira tentativa isolada revelou que os testes de regras usavam porta8080 fixa; os dois scripts foram corrigidos para respeitar `FIRESTORE_EMULATOR_HOST`, já limitado a loopback pelo guard. Uma tentativa subsequente foi recusada porque a porta ainda estava ocupada; o processo de teste anterior foi encerrado antes de repetir. A repetição final (`deploy-reviews-final-3.txt`) terminou com exit0 e ambas as suítes aprovadas, incluindo concorrência, idempotência, agregados, histórico e regras. Nenhuma assertiva foi removida ou flexibilizada.

Portanto, há aprovação atual dos 13 cenários por evidências complementares, mas não se afirma uma única rodada completa 13/13 nesta publicação. A evidência inclui falhas e execuções interrompidas.

Arquivos de código ajustados nesta publicação:
- `functions/src/services/avaliacoes/avaliacaoVerificadaService.ts`: reutiliza transação idempotente na criação verificada.
- `functions/src/services/avaliacoes/gestaoReputacaoService.ts`: reutiliza transação idempotente em resposta/denúncia/decisão.
- `functions/scripts/testAvaliacoesVerificadasEmulator.js`: porta configurada e diagnóstico do conflito.
- `functions/scripts/testGestaoReputacaoEmulator.js`: porta configurada.

A configuração temporária de publicação de índices gerada durante a análise não foi utilizada: comparação normalizada mostrou zero índices ausentes. Não foi executado deploy de índices nem exclusão de índices existentes.

## Resultado final confirmado

- Segundo grupo: 14/14 Functions publicadas, Deploy complete.
- Inventário remoto após deploy: **78/78 Functions selecionadas em ACTIVE**, runtime Node.js22. As novas Functions estão em southamerica-east1; o trigger de avaliação conserva us-central1.
- Smoke adicional de consulta de reputação, contratos avaliáveis e permissão de reputação:401 UNAUTHENTICATED em todos os endpoints.
- Nenhum endpoint selecionado permaneceu ausente ou falhou na publicação. Logs e inventários anexos permitem conferir cada nome.

As Functions e regras publicadas eliminam a incompatibilidade de versão identificada no financeiro e a ausência dos serviços de jornada, agenda, reputação, planejamento e painel. A confirmação dos dados específicos da conta do usuário deve ser feita ao atualizar a tela e consultar com sua sessão normal; não foi utilizado token dessa conta nesta execução.

Comandos reproduzíveis para seleção (executados na raiz do app): ler IDs do manifesto e executar `firebase deploy --project faca-a-festa --only functions:ID1,functions:ID2,... --non-interactive`. Para testes integrados: selecionar JDK21 local e executar `firebase emulators:exec --config firebase.operacao-test.json --project demo-operacao-fornecedor --only firestore "node functions/scripts/testOperacaoFornecedorIntegrada.js"`. Para repetição isolada: configuração equivalente com porta8085, execução do runner preservado junto aos logs. Configurações temporárias arquivadas precisam ser restauradas à raiz, com seus caminhos relativos, para reprodução.
