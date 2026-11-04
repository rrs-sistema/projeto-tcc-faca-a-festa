# Prompt 08 — Vencimentos, projeção de caixa e resultado por evento

Implemente o planejamento financeiro operacional do fornecedor no Faça a Festa, em `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Flutter/GetX, Firestore e Functions TypeScript; Windows/PowerShell. Faça alterações reais com testes; o prompt é autocontido.

Leia AGENTS.md, confira Git e preserve trabalho preexistente. Não faça deploy, commit, push, operações financeiras reais ou migração em produção. Reutilize contratos, custos, obrigações, movimentos e repasses. Se identificar inconsistências de origem/duplicidade, corrija a menor base necessária antes de construir relatórios; não esconda erro com um total alternativo.

## Implementação

1. Ofereça contas a receber e a pagar, vencimento, valor original, baixas parciais, saldo, origem, vínculo e situação. Vencimento precisa estar sustentado por registro/política; ausência de previsão não equivale a atraso. Contrato assinado não confirma entrada de caixa.
2. Separe repasses da plataforma, receitas externas e despesas privadas. Um custo incorrido pode estar a pagar ou pago; consumo de material comprado anteriormente não gera novo desembolso. Reutilize as entidades de obrigação/liquidação existentes.
3. Mostre projeção de entradas/saídas por período com origem e grau de confirmação. Diferencie repasse previsto sem data, autorizado e confirmado. Permita saldo inicial informado persistido; sem ele, apresente movimento/projeção das variações e não saldo bancário fictício.
4. Mostre resultado por evento e consolidado: bruto contratado, comissão/deduções conhecidas, custos previstos/incorridos, recebido e saldo pendente. Separe resultado previsto, realizado e caixa. Não chame margem direta de lucro líquido.
5. Diferencie zero confirmado, não informado e não aplicável. Persista configurações/deduções privadas apropriadas, evitando depender apenas do estado do controller. Não desconte novamente uma comissão já incorporada à base líquida.
6. Implemente filtros coerentes por evento, período e situação. Defina qual data cada filtro utiliza. Inclua exportação CSV dos dados autorizados e filtrados, com origem, data de geração e proteção contra fórmulas injetadas em células. Exportar não concede acesso adicional.
7. Preserve histórico em baixas, estornos e ajustes com autoria, data, motivo e idempotência. Interface responsiva e acessível; consultas incompletas não devem gerar resumo aparentemente definitivo.

## Aceite

Contrato de R$ 3.150,00 com comissão de R$ 157,50 e custo previsto de R$ 1.000,00: resultado direto previsto de R$ 1.992,50 antes de outras deduções, explicitamente parcial se faltarem componentes. Isso não é entrada de caixa. Um desembolso de R$ 400,00 e repasse confirmado de R$ 1.000,00 produzem movimento líquido de R$ 600,00, sem contagem duplicada.

Teste baixas parciais, vencidos, data ausente, consumo de estoque, filtros, deduções, autorização e exportação. Confira paridade entre relatório, CSV e fatos persistidos. Registre verificações reais e limitações em `docs/evidencias_validacao/operacao-fornecedor/08-planejamento-relatorios-financeiros.md`.
