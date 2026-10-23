# Entrega 08 — Financeiro real, verba alimentar e capacidade

Data: 20/10/2026, America/Sao_Paulo. Escopo da entrega 08; não homologa a jornada inteira. Alterações preexistentes das entregas anteriores foram preservadas. Sem deploy, produção, migração destrutiva, commit ou push.

## Diagnóstico reproduzido

- A Home chamava a soma de `custo_estimado` de **Gasto**. O controller do orçamento somava o estimado de um contrato fechado a **Pago**, caso não existisse um controller de despesas aberto. O valor dependia, portanto, de qual tela tinha sido aberta.
- A calculadora já consultava `orcamento/{id}/orcamento_gasto` e conciliava cobertura por identidade do evento/cardápio/item. Essa aquisição foi compartilhada com o orçamento, sem uma segunda tabela financeira.
- A cobertura contratada por destino já dispensava compra adicional; foi preservada e testada. Cobertura antiga sem destino, concorrente ou ainda não contratada continua exigindo conferência.
- O motor de capacidade já rejeitava grupos e públicos próprios. O modal, porém, podia trocar um público misto por adultos antes da simulação. Confirmar verba também exigia passar primeiro pela simulação.
- A máscara de moeda apagava uma entrada explícita de zero. A regressão detectou ainda um excesso de altura no modal com teclado e fonte ampliada quando as ações foram separadas; ambos foram corrigidos.

## Decisões e implementação

**Estimado**, **cotado nos orçamentos**, **contratado** e **pago registrado** são métricas distintas, não parcelas a somar entre si. Contrato fechado não comprova pagamento. Pago é a soma dos valores das despesas vinculadas; não é estimado menos saldo, nem preço de uma cotação. Uma flag antiga `pago: true`, sem despesas verificáveis, fica pendente de conferência. Cancelar um orçamento não inventa estorno de pagamentos registrados.

O valor cotado exibido refere-se aos orçamentos identificados como cotação/negociação. A tela de cotações continua representando as propostas dos fornecedores; as alternativas não são automaticamente contratadas ou pagas. Fechar cotação mantém o valor pago inicial em zero e registra seu vínculo de origem no orçamento.

O limite total continua em `evento.custo_estimado`. Limite ausente e limite zero confirmado têm apresentação distinta na Home e no orçamento. A verba alimentar permanece uma escolha privada em `calculadora_operacao/{evento}.configuracao_planejamento`. **Simular capacidade** não grava. **Usar esta verba** confirma independentemente de uma estimativa de pessoas, inclusive verba zero. Cancelar conserva a escolha anterior. A confirmação usa a revisão/idempotência existentes e reconsulta o limite do evento na transação. Uma redução posterior do limite revalida a projeção e gera aviso quando a verba antiga o supera, preservando compras e pagamentos.

Capacidade é um cenário teórico de compra integral para adultos, com a reserva escolhida. Não desconta estoque, buffet ou pagamento para aparentar mais pessoas. Públicos mistos, grupos, destinos específicos ou cobertura insuficiente recebem limitação e próxima ação, sem extrapolação falsa. Confirmar verba continua possível nesses casos. Fonte, estado e unidade do preço precisam permanecer compatíveis; preço ausente, zero ou incompatível deixa custo pendente sem impedir quantidade válida.

## Arquivos e camadas

- `lib/data/datasources/remote/compromissos_evento_remote.dart`: extração da aquisição que já existia na calculadora. Escuta orçamentos e respectivas despesas, aguarda todos os filhos, cancela escutas anteriores e distingue cache/escrita pendente de consulta sincronizada. Consultas pontuais exigem servidor.
- Datasources da calculadora e do orçamento, `orcamento_repository_impl.dart` e `lib/domain/repositories/financeiro_evento_repository.dart`: reutilizam essa mesma fonte real.
- `compromisso_planejamento_service.dart` e `resumo_financeiro_evento_service.dart`: valores separados, origem da consulta e validação de dados financeiros. Registros inválidos não são tratados como zero conhecido/completude financeira.
- `orcamento_controller.dart`, `orcamento_gasto_controller.dart` e bootstrap: total pago independente de controllers de despesas abertos, listeners com geração e sessão, cancelamento e limpeza ao trocar contexto. A antiga inferência de pagamento por contrato foi removida.
- `home_organizador_copy.dart`, `home_event_screen.dart`, resumo e tela do orçamento: nomes corretos e métricas separadas, com estados de consulta pendente. A linha de serviço contratado sem despesa também deixa de apresentar o contrato como pago.
- `orcamento_gasto_remote_datasource.dart` e `firestore.rules`: valores finitos; atualização transacional do total pago que respeita o custo/saldo atual da despesa; repetição do mesmo total não soma novamente. Regras validam custo, pago e vínculo ao orçamento, além das permissões existentes.
- `estimativa_financeira.dart`, `calculadora_festa_service.dart`, `resumo_compras_service.dart`, `capacidade_alimentos_service.dart` e editor manual: validação do vínculo preço/unidade/estado. Trocar a unidade de compra apaga o preço anterior; novas confirmações preservam origem e data do preço. A informação de quantidade permanece disponível com custo pendente.
- `calculadora_capacidade_dialog.dart`, configuração/controller e seção de totais: simulação e confirmação independentes, proteção de público misto e contexto/sessão, aviso de verba acima do limite atualizado e layout com conteúdo rolável.
- `numeric_input.dart`: zero explicitamente digitado permanece uma entrada de moeda válida.
- `entradaAssistenteService.ts`, `publicoPlanejamentoService.ts` e `financeiroCalculadoraService.ts`: origem/data da verba e do preço confirmados pela entrada assistida, leitura compatível da configuração e limite zero explicitamente conhecido. A IA continua explicando dados fornecidos; não registra pagamento por aprovar uma proposta.
- `fecharCotacao.ts`: preserva `id_cotacao` no orçamento originado pela contratação, sem registrar quitação.

## Persistência e compatibilidade

Não é necessária migração ou regravação de históricos. Permanecem as coleções existentes:

```text
evento/{evento}.custo_estimado                limite total
orcamento/{orcamento}.custo_estimado          estimativa/proposta
orcamento/{orcamento}.id_cotacao              vínculo opcional de origem
orcamento/{orcamento}/orcamento_gasto/{gasto}
  id_orcamento, custo, pago                   despesa e pagamento real
  pagamento_atualizado_em                     timestamp de atualização

calculadora_operacao/{evento}.configuracao_planejamento
  verba_alimentacao                          escolha privada, null e zero distintos
  verba_confirmacao                          opcional em registros novos
    versao: 1
    valor: número ou null
    fonte: organizador
    confirmado_por: uid
    confirmado_em: ISO-8601 UTC

execucao.regras[].premissas
  preco_unidade, preco_estado, preco_fonte, preco_confirmado_em
```

A confirmação direta da configuração registra a data do aplicativo, e a entrada assistida registra a data da Function; o documento só é aplicado após a gravação validada. Registros antigos sem metadados continuam legíveis e não recebem data ou pagamento inventados. Preços antigos mantêm a associação que já existia à unidade/estado da regra; incompatibilidade explícita é recusada e mudanças no editor exigem novo preço.

As regras continuam limitando escrita financeira ao organizador/solicitante autorizado ou administrador. Elas passam também a recusar pago negativo, pago superior ao custo e vínculo da despesa com outro orçamento. Isso não cria um livro contábil imutável: as ações explícitas de manutenção de despesas já existentes continuam disponíveis.

## Testes e reprodução

- `test/features/calculadora/financeiro_real_test.dart`: R$ 6.500 estimados e R$ 500 pagos; contrato/cotação sem pagamento; flag antiga sem prova; cancelamento sem estorno fictício; dados inválidos/sincronização; preço incompatível; buffet com cobertura por destino sem compra adicional duplicada.
- `calculadora_capacidade_dialog_test.dart`: confirmar sem simular, cancelar preservando verba, zero conhecido e limitação de público misto.
- `orcamento_controller_test.dart`: valor pago não inferido de contrato; aquisição sem controller de gastos aberto e callback após troca de sessão.
- Regressões existentes de capacidade em tela pequena/fonte ampliada, resumo de compras, sobreposição, cobertura, preço e saldo foram executadas. Os sete problemas do primeiro passe geral foram corrigidos; os 23 testes focados correspondentes passaram após a correção.
- `test/firestore/calculadora.rules.test.js`: permissões reais e novos casos de pagamento parcial, excesso, negativo, tipo inválido e vínculo adulterado.
- `integration_test/financeiro_capacidade_emulator_test.dart` com `functions/scripts/testFinanceiroDesktop.js`: SDKs reais Auth/Firestore no Windows. Fixtures sintéticas; recusa ambiente fora de localhost/projeto demo. Exercita listener de pagamento parcial e repetição, bloqueio por saldo/vínculo/permissão, simular/cancelar sem escrita, confirmação remota da verba, retomada e redução do limite preservando despesa.

Comandos sem publicação:

```powershell
flutter test
npm --prefix functions run check:calculadora

$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
firebase emulators:exec --project demo-faca-festa-contexto --config firebase.calculadora-test.json --only firestore "node test/firestore/calculadora.rules.test.js"
firebase emulators:exec --project demo-financeiro08 --config firebase.calculadora-test.json --only 'firestore,auth' "node functions/scripts/testFinanceiroDesktop.js"
firebase emulators:exec --project demo-financeiro-entrada --config firebase.calculadora-test.json --only firestore "node functions/scripts/testFinanceiroEntradaEmulator.js"
```

Logs locais ignorados pelo Git: `.dart_tool/financeiro-unit.log`, `financeiro-regressoes.log`, `financeiro-suite.log`, `financeiro-functions.log`, `financeiro-analyze.log`, `financeiro-rules.log`, `financeiro-sdk.log`, `financeiro-entrada.log`, `financeiro-suite-validada.log`, `financeiro-analyze-concluida.log`. Resultados finais:

- `flutter test`: **654 testes passaram** na rodada final, incluindo os dez casos novos desta entrega.
- Entrada monetária: **14 testes passaram**, preservando zero explícito e permitindo apagar o último dígito.
- `npm --prefix functions run check:calculadora`: **passou**, incluindo compilação TypeScript e teste de limite zero conhecido.
- Firestore rules, com os novos casos de pagamento e vínculo: **passaram**.
- Windows nativo com SDKs reais Auth/Firestore emulados: **passou**. A confirmação da verba foi conferida no documento remoto, recriação do controller e posterior redução do limite.
- `functions/scripts/testFinanceiroEntradaEmulator.js`: **passou** contra Firestore real emulado. O serviço de produção guardou a origem/data da verba, recusou outro organizador e repetição não reaplicou a ação; nenhum orçamento/despesa/pagamento foi criado. Somente a interpretação foi fornecida por extrator sintético, sem modelo externo.
- Análise estática final: conferida nos arquivos da entrega após corrigir os apontamentos de estilo. Fontes Dart formatadas e `git diff --check` sem erros nos arquivos conferidos.

## Limites e ativação posterior

Não há chamada a modelo externo nesta validação, nem transação em produção. O teste nativo é Windows; não homologa aparelho Android/iOS físico. Os cenários de teclado, largura pequena e fonte ampliada são testes Flutter de layout. O ambiente local usa Node do host para os scripts; isso não comprova o runtime Node 22 das Functions.

Para ativar posteriormente, revisar e distribuir os leitores/app compatíveis e as regras atualizadas; publicar as alterações das Functions de entrada/cotação apenas no ambiente autorizado. Conferir despesas legadas que violem o novo contrato antes de editá-las. Não é necessário transformar estimativas antigas em despesas ou marcar cotações como pagas. A implantação não foi executada nesta entrega.
