# Integração autenticada da calculadora — 17/10/2026

## Correções

O registro de pagamentos pela entrada inteligente produzia uma linha com custo zero e valor pago positivo. Essa representação não atendia à regra do editor financeiro (`0 ≤ pago ≤ custo`). Agora o pagamento atualiza as despesas vinculadas, respeitando o saldo de cada uma. Um orçamento antigo sem detalhamento recebe uma despesa com o custo já previsto, sem acrescentá-lo outra vez à projeção.

Despesas e cotações criadas pela entrada passam a preencher `id_gasto` e `nome`, consumidos pelo modelo e pela tela de despesas. Pagamento parcial, custo e contratação continuam sendo informações distintas. Dados antigos inconsistentes são recusados para conferência; o servidor não inventa uma correção financeira.

Os adaptadores da calculadora, executor e revisão pós-evento passaram a usar a mesma aplicação Firebase da autenticação, inclusive quando a conexão é injetada. Isso permite verificar a integração no projeto demo sem alcançar a conexão padrão do aplicativo.

A regra de atualização de eventos também foi corrigida: um organizador precisa ser o proprietário atual para editar o evento e não pode transferi-lo alterando `id_usuario`. A criação pelo próprio organizador e a exceção administrativa foram mantidas. O teste autenticado recusa tanto a tentativa de outro organizador assumir o evento quanto a troca de proprietário pelo dono; a edição legítima do orçamento continua permitida.

Na retomada com o aparelho conectado, o executor revelou uma divergência real entre SDKs: `Timestamp.toDate()` do SDK Admin arredonda milissegundos, enquanto o Flutter preserva microssegundos. O normalizador montava uma data arredondada e acrescentava a fração original, recusando propostas sem qualquer edição concorrente. Agora a parcela de milissegundos é construída sem arredondamento antes de acrescentar os microssegundos. A proteção contra alteração real permanece ativa. As mensagens do executor também tiveram a acentuação corrigida.

## Roteiro reproduzível

`functions/scripts/testJornadaCalculadoraAparelho.js` prepara somente usuários e referências fictícios em emuladores e executa `integration_test/jornada_calculadora_aparelho_test.dart` no pacote Android de QA. O roteiro recusa execução sem os emuladores. Não é exportado nem implantado no backend.

O teste utiliza SDKs, autenticação, regras, repositórios, controlador quantitativo, revisão de criação do cardápio e modal de entrada reais. O cadastro inicial do evento passa pelo repositório; o roteiro não navega por todos os campos da tela de cadastro. A interpretação documental é determinística no harness, para isolar integração de extração. Os testes do provedor real estão documentados no relatório da entrada inteligente.

```powershell
npm --prefix functions run build
firebase emulators:exec --config firebase.calculadora-test.json --only "firestore,auth" --project demo-calculadora-entrada "node functions/scripts/testJornadaCalculadoraAparelho.js"
```

O aparelho precisa estar conectado ao ADB. O script aceita `CALCULADORA_QA_DEVICE`; o padrão identifica o aparelho de QA utilizado nesta execução. Os encaminhamentos locais das portas são restaurados pelo roteiro.

## Verificações concluídas

- Suíte geral Flutter: **574 testes aprovados** (`.dart_tool/jornada-suite-completa.log`).
- Regressão dirigida de entrada, criação e persistência: **15 testes aprovados** (`.dart_tool/jornada-regressao-flutter.log`).
- Entrada e financeiro no servidor: **67 verificações aprovadas**, incluindo pagamentos parciais, distribuição entre despesas, orçamento sem detalhamento, invariantes do editor e propriedade do evento. A regressão com o normalizador de datas corrigido também passou (`.dart_tool/jornada-entrada-datas-emulador.log`).
- Executor e revisão pós-evento: **54 verificações aprovadas** (`.dart_tool/jornada-executor-datas-emulador.log`). Os novos casos usam datas esperadas independentes do normalizador, incluindo frações que arredondariam, passagem de segundo e data anterior à época Unix; uma mudança real de um microssegundo continua recusada. Esse roteiro usa seu próprio projeto demo para que a audiência do token corresponda ao SDK Admin.
- Regras da calculadora e tarefas: aprovadas (`.dart_tool/jornada-regras-calculadora.log` e `.dart_tool/jornada-regras-tarefas.log`).
- Análise estática dirigida: sem ocorrências (`.dart_tool/jornada-analysis.log`).
- Backend atualizado: `aplicarPlanoCalculadora`, `interpretarEntradaCalculadora` e `aplicarEntradaCalculadora`, todas `ACTIVE`; chamadas sem autenticação retornaram `401 UNAUTHENTICATED` (`.dart_tool/jornada-deploy-datas.log` e `.dart_tool/jornada-smoke-datas-publicado.json`). Regras atualizadas com compilação aprovada (`.dart_tool/jornada-deploy-regras.log`).

## Teste integrado no aparelho: aprovado

**SM G990E, Android 16, pacote isolado de QA: execução completa aprovada** (`.dart_tool/jornada-integrada-aparelho-final.log`, `All tests passed!`, saída zero). A conexão ADB foi restabelecida pelo usuário antes da retomada. A divergência de datas encontrada no roteiro foi corrigida no servidor e coberta por testes de regressão.

| Verificação | Resultado observado |
| --- | --- |
| Cadastro e edição pelo repositório real | Evento criado com orçamento e público previsto; edições posteriores preservaram cardápio, despesas e planejamento. |
| Público efetivo | 29 adultos e 8 crianças não recusados, distintos dos 35 previstos; a recusa adicional foi excluída. |
| Proposta e revisão | Três itens calculados; criação do cardápio e histórico pela revisão real; repetição sem duplicação; nenhuma compra ou quantidade final presumida pela criação. |
| Duas refeições e estoque | Arroz final de 4 kg + 2 kg, lote central de 3 kg, compra restante de 3 kg; reservas somadas em 3 kg; tarefas criadas. |
| Aplicação repetida | Recibo reconhecido sem executar o conjunto novamente. |
| Entrada inteligente | Revisão real antes de gravar compra de 1 kg, preço de R$ 6/kg, despesa de R$ 60, pagamento parcial de R$ 20 e cotação de R$ 500. A interpretação é determinística no harness. |
| Financeiro | Custo total de R$ 560 e pagamento de R$ 20; detalhe de despesa com nome e ID válidos. Quitação pelo adaptador real elevou o pago a R$ 60 sem duplicar o custo de R$ 560. Cotação permaneceu sem contratação. |
| Replanejamento | Após a compra de 1 kg, o restante de arroz passou de 3 kg para 2 kg, mantendo as quantidades finais de 4 kg e 2 kg. |
| Concorrência | Alteração posterior do orçamento invalidou a proposta pendente; a aplicação foi recusada. |
| Pós-evento | Tentativa de registrar revisão antes da data do evento foi recusada. |
| Novo login | Público, orçamento atualizado, preço, quantidade final, estoque e valores pagos recuperados pelo controlador/repositórios. |
| Acesso | Outro organizador foi impedido de carregar a execução; leitura inteligente sem login recusada. |

O diagnóstico local registrou **nenhuma divergência** na primeira aplicação (`.dart_tool/jornada-fontes-qa-jornada_1.json`) e a alteração esperada em `evento/festa` no cenário propositalmente obsoleto (`.dart_tool/jornada-fontes-qa-jornada_obsoleta.json`). Os arquivos contêm somente fontes fictícias de QA. A atestação App Check não integrou o critério deste teste; a autenticação Firebase foi validada pelos wrappers callable.

## Limite da evidência

O cenário usa dados sintéticos e não modifica o evento real de 23/10/2026. Integração técnica não comprova suficiência alimentar, qualidade universal da extração documental ou redução de 70%–80% das intervenções. O piloto observado e as medições de consumo após o evento continuam necessários. Aplicativo e hosting permanecem sem publicação.
