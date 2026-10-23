# 01 — Contexto e prontidão da Calculadora Inteligente

Data: 19/10/2026. Entrega local, sem publicação, commit ou push.

## Diagnóstico e reprodução

O Git já continha alterações extensas (inclusive nos controllers, telas, regras e backend). Elas foram preservadas. Nenhum AGENTS.md foi localizado no diretório e seus ancestrais ou na árvore consultada.

A preparação capturava previsão e limite na entrada. O listener do evento atualizava EventoController, mas a calculadora não acompanhava essas premissas. O coordenador apenas iniciava listeners: terminar seu Future não significava receber todos os snapshots. A consulta de cardápios começava marcada como completa na preparação. CardapioController não distinguia gerações de escuta, e o cancelamento assíncrono podia interferir em uma escuta mais recente. Operação e gastos já possuíam proteções parciais, que foram reutilizadas.

A investigação e os testes reproduziram A/B com respostas fora de ordem, falha independente do financeiro, público manual e histórico isolado. O teste antigo de público esperava substituir uma previsão de 99 por uma lista de uma pessoa; passou a conferir preservação da previsão e depois uma escolha explícita pela lista. Um teste de capacidade esperava gravar a verba ao simular, enquanto o diálogo existente já exige “Usar esta verba”; a expectativa agora verifica ausência de mutação na prévia, mantendo as demais verificações.

## Decisão e implementação

- ContextoPlanejamentoEvento e FontePlanejamento são valores imutáveis derivados das fontes existentes: usuário, evento, rascunho explícito, geração, origem, revisão e disponibilidade. Não armazenam cópias dos dados de negócio.
- Estados tipados: não consultada, carregando, disponível, vazia, erro, desatualizada e escrita pendente. Pendências têm nomes de negócio e ação de atualização na tela.
- Capacidades distintas para quantidades, compras, custos, comparação e aplicação. O salvamento e envio pela tela consultam a prontidão pertinente. IA permanece independente do motor determinístico.
- Revisão de cardápios usa conteúdo dos itens; regras usam conteúdo serializado; operação usa revisão existente; gastos usam assinatura de conteúdo. Geração diferencia inclusive A → B → A.
- Worker do evento atualiza limite e previsão, recalcula a projeção e invalida a análise. Alterações apenas de título/capa não entram na assinatura quantitativa. Alteração de período marca contexto desatualizado, remove resultados correntes e exige atualização explícita para continuar.
- Público previsto é a entrada inicial quando existe previsão no evento. Lista parcial não substitui essa previsão. A escolha de base nominal continua disponível; alterações da lista preservam o público manual.
- Histórico usa metadados de origem “simulação salva”, sem consumir revisões correntes. Evento, gastos, convidados e operação rejeitam atualizações incompatíveis durante consulta histórica. Atualizar é a transição explícita para os dados atuais.
- Respostas tardias da leitura inteligente são rejeitadas por assinatura/geração; retorno de alteração de operação verifica geração antes de alterar a sessão. Durante a escrita da operação, a fonte é pendente até confirmação ou falha.
- Cardápios e itens verificam geração; cancelamento captura e desassocia as subscriptions antes de esperar. Consulta negada continua sendo erro e não cria exemplos.
- Atualização permite retentar cardápios com erro, preservando listeners válidos e seus dados correntes.

## Arquivos desta entrega

- lib/domain/entities/contexto_planejamento_evento.dart
- lib/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart
- lib/presentation/modules/calculadora/controllers/calculadora_festa_operacao.dart
- lib/presentation/modules/calculadora/controllers/calculadora_festa_analise_ia.dart
- lib/presentation/modules/calculadora/controllers/calculadora_festa_entrada.dart
- lib/presentation/modules/calculadora/controllers/calculadora_festa_historico.dart
- lib/presentation/modules/calculadora/controllers/calculadora_festa_proposta.dart
- lib/presentation/modules/calculadora/pages/calculadora_festa_screen.dart
- lib/presentation/modules/convidado/controllers/cardapio_controller.dart
- test/features/calculadora/contexto_prontidao_test.dart
- test/features/calculadora/calculadora_jornada_base_test.dart
- test/features/calculadora/calculadora_jornada_test.dart
- test/features/calculadora/calculadora_autonomia_widgets_test.dart
- test/firestore/calculadora.rules.test.js

Esses arquivos podem conter também alterações anteriores à entrega; o diff contra HEAD não representa somente este trabalho.

## Persistência e compatibilidade

Não foi criada coleção, nem alterado formato persistido, regras de produção ou callable nesta entrega. calculadora_operacao/{idEvento}, revisão transacional e snapshot histórico existentes continuam sendo os caminhos de domínio. O contrato de prontidão é derivado em memória; gerações são locais e não são versões globais do Firestore. Snapshot histórico legado não recebe metadados retroativos nem tem seus valores atualizados por listeners correntes. Não há migração necessária. Escrita pendente descreve a chamada de domínio em andamento, sem afirmar confirmação antes do retorno.

O script de regras agora exige FIRESTORE_EMULATOR_HOST local e usa demo-faca-festa-contexto. A primeira tentativa foi recusada pela CLI por Java inferior a 21; foi utilizado o JBR 21 já instalado no Android Studio, somente no ambiente do comando.

## Validação executada

- dart format: arquivos Dart modificados formatados.
- dart analyze: arquivos modificados e partes de controllers, incluindo testes alterados, sem problemas na execução final.
- flutter test test/features/calculadora test/features/cardapios --reporter expanded: **267 testes aprovados**, código de saída 0.
- O conjunto inclui quatro testes novos de coordenação: respostas A/B fora de ordem e erros independentes; gravação pendente/troca de sessão; leitura inteligente tardia A/B/A; cardápios negados e troca de escuta. Inclui teste de orçamento remoto, título visual, período desatualizado, público manual e histórico.
- npm --prefix functions run check:calculadora: aprovado, incluindo tsc --noEmit e verificações de planejamento/IA, limite compartilhado, renovação, autorização e fallback.
- firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js": aprovado, “Calculadora Firestore rules: OK”, saída 0. PERMISSION_DENIED nos casos negativos é esperado.
- git diff --check: sem erros de whitespace; há avisos de normalização CRLF em arquivos do working tree.

Os testes Dart com repositórios controlados comprovam coordenação, não integração SDK/dispositivo. O teste de regras usa Firestore emulado real com contextos autenticados sintéticos; não comprova a jornada Flutter autenticada completa.

## Limites e ativação posterior

flutter devices identificou Windows, Chrome e Edge, sem aparelho/emulador móvel conectado. Não foi executado integration_test em aparelho, nem cenário real simultâneo de dois clientes Flutter. Não foram usadas credenciais ou dados reais. Os testes existentes integration_test/jornada_calculadora_aparelho_test.dart e entrada_inteligente_aparelho_test.dart exigem o harness demo correspondente (Auth/Firestore/Functions, dados sintéticos e CALCULADORA_QA); não devem ser apontados a produção.

O contrato representa a disponibilidade conhecida pela aplicação. Os repositórios atuais não propagam integralmente SnapshotMetadata.isFromCache/hasPendingWrites de todas as fontes; portanto não há homologação de distinção entre cache offline e confirmação do servidor para cada listener. Comparações e gravações fora das entradas da tela mantêm suas validações de domínio existentes; esta entrega não constitui auditoria de todos os comandos da jornada.

Para ativar: revisar o diff preservando alterações anteriores, repetir os comandos acima em ambiente de desenvolvimento e executar o harness demo em dispositivo, incluindo fonte ampliada/teclado, mudança de orçamento em segundo cliente, perda de rede e retomada. O backend e as regras já existentes devem estar disponibilizados pelo processo normal do projeto; nenhuma publicação foi executada aqui. Esta evidência cobre este escopo e não declara a jornada inteira homologada.
