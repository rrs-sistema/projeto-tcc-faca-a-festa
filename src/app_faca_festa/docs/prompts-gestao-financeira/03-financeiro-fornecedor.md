# Prompt 03 — Custos, caixa e resultado do fornecedor

## Contexto e execução independente

Atue como desenvolvedor sênior Flutter/Firebase e analista financeiro de eventos. Implemente a atividade deste prompt no Faça a Festa com comportamento integrado e verificável. Este arquivo contém todo o contexto necessário: não exige histórico de outro chat, leitura de outro prompt ou etapa anterior executada pelo usuário.

Repositório: `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Ambiente Windows/PowerShell. Stack observada: Flutter/Dart, GetX, Firebase Auth, Firestore e Cloud Functions TypeScript em `functions/`.

Antes de editar, leia os AGENTS.md aplicáveis, examine o Git e confirme os comportamentos atuais. Preserve alterações preexistentes. Os caminhos citados são pistas que precisam ser confirmadas. Reutilize entidades, autorização, serviços e interface adequados, sem criar um financeiro paralelo. Se faltar uma dependência necessária ao objetivo, implemente somente a menor base real e reutilizável para entregá-lo. Não exija a execução de outro prompt nem entregue telas desconectadas, mocks de produção ou apenas documentação.

## Contrato financeiro e técnico obrigatório

- Estimativa, cotação, contratação, custo realizado, obrigação e pagamento são fatos distintos. Planejamento aprovado não significa compra, contratação ou pagamento. Cotação não aceita não é dívida ou receita garantida.
- Separe evento, empresa fornecedora e plataforma. Volume contratado não é receita da plataforma. Custos e margens internos são privados do fornecedor. Seu acesso não inclui orçamento global do cliente.
- Gerente significa responsável autorizado pelo evento. Descubra o modelo de autorização; se necessário, estabeleça vínculo explícito por evento. Rótulo de interface não concede permissão. Administrador não recebe automaticamente acesso a custos privados.
- Valores monetários novos usam centavos inteiros em BRL, limites e arredondamento explícitos. Adapte campos legados em double com compatibilidade e sem migração silenciosa em produção.
- Cada fato tem identidade, origem, titular/perspectiva, evento e vínculos pertinentes. Não duplique valores entre orçamento legado, contrato, compra e estoque. Propostas alternativas para uma necessidade não são somadas como compromisso.
- Pagamento e recebimento têm perspectivas definidas. Uma liquidação compartilhada pode alimentar duas visões, mas não duas movimentações na mesma visão. Diferencie registro manual declarado de confirmação externa. Não copie automaticamente registros privados do cliente como recebimento comprovado do fornecedor.
- Preserve descontos, adiantamentos, multas, estornos, reembolsos e créditos explicitamente. Não esconda pagamentos excedentes com clamp. Retificações preservam histórico, autor, data, motivo e origem.
- Ausente, zero confirmado, consulta incompleta, erro, cache e sincronização pendente não são equivalentes. Informação incompleta não sustenta afirmação de economia, lucro ou quitação.
- Valide cálculos e comandos críticos no backend. Functions com Admin SDK verificam autorização própria. Use idempotência, transações e controle de concorrência onde necessário. Troca de sessão/evento deve cancelar listeners e invalidar callbacks antigos.
- Proteja leituras, subcoleções, comandos, anexos, agregados, logs e exportações. Interface em português, responsiva para celular/web/desktop e fonte ampliada, com origem, filtros e atualização dos números. Reutilize padrões visuais existentes.
- Não faça deploy, alterações em produção, migração destrutiva, commit ou push. Não execute cobrança real nem envie mensagens externas. Testes autenticados usam dados sintéticos e projeto demo/emuladores, recusando produção.

## Validação e entrega

Implemente as camadas pertinentes: domínio, persistência, backend/permissões e interface. Confira os scripts atuais antes de usá-los. Existem referências a `flutter test`, `npm --prefix functions run build`, `npm --prefix functions run check:calculadora`, `npm run test:rules` e `npm run test:rules:calculadora`; selecione os adequados e adicione testes específicos necessários. O lint das Functions pode apenas informar que foi ignorado; isso não comprova análise estática.

Execute formatação, análise estática e testes pertinentes, inclusive regras e Functions separadamente, acesso negado, repetição e concorrência quando aplicáveis. Não corrija problemas alheios ao escopo. Falta de aparelho/credencial não impede trabalho independente: entregue roteiro reproduzível e explicite o que não foi executado. Mocks não comprovam integração Firebase.

Registre evidência no caminho indicado ao final: diagnóstico, regras, arquitetura, arquivos, formato persistido, compatibilidade, índices, testes/resultados reais, limitações e ativação posterior sem publicação. Ao concluir, explique comportamento entregue, pendências e alterações preexistentes relevantes.

## Objetivo

Implemente gestão financeira privada da empresa fornecedora por evento e consolidada: vendas, recebimentos, custos, obrigações, resultado e caixa. Valor vendido e saldo do organizador não comprovam lucro.

## Investigue

`lib/presentation/modules/fornecedor/pages/fornecedor_home_screen.dart`, painel de cotação, controllers/seções do fornecedor, entidades de fornecedor/orçamento/cotação, gastos, autenticação e regras. Se não houver membros de empresa, preserve o proprietário atual sem criar acesso global por papel genérico.

## Requisitos

1. Financeiro com filtros por evento, período, categoria e vencimento. Mostre contratado, recebido, a receber, custo realizado, custo restante previsto e contas vencidas.
2. Registre custos internos por evento/serviço: consumo de materiais, mão de obra, terceiros, transporte, montagem, locação e perdas. Separe custo incorrido de obrigação e desembolso. Referências/comprovantes respeitam autorização.
3. Contas a pagar/receber com parcelas, liquidações e estornos. Pagamento declarado por uma parte não vira automaticamente recebimento comprovado da outra.
4. Resultado direto previsto e realizado com fórmula e completude visíveis. Receita realizada depende da regra de execução/entrega, não de mero adiantamento. Resultado após rateios exige base, período e regra explícitos; não invente rateio.
5. Inclua comissão aplicável, taxas e tributos informados quando pertinentes, sem criar alíquotas. Se faltarem componentes relevantes, indique resultado parcial. Margem de contribuição não recebe rótulo de lucro líquido.
6. Fluxo de caixa: saldo inicial informado, entradas, saídas, saldo final e projeção por vencimento. Sem saldo inicial, mostre movimento líquido; não afirme saldo bancário sem integração.
7. Integre consumo de estoque, se existente. Caso contrário, permita custo manual com origem rastreável para evitar duplicação futura. Reutilizável não custa sua aquisição integral a cada evento.

## Critérios de aceite

- Contrato R$ 10.000, recebido R$ 4.000: a receber R$ 6.000, independentemente dos custos.
- Custos diretos realizados R$ 3.000 e restantes R$ 2.000: custo direto previsto R$ 5.000; outras despesas incluídas/ausentes ficam explícitas.
- Consumo de material comprado antes gera custo sem nova saída de caixa.
- Adiantamento para evento futuro afeta caixa sem virar automaticamente receita realizada.
- Organizadores, outros fornecedores e administradores sem permissão específica não acessam margens/custos privados, inclusive em agregados/exportações.

Evidência: `docs/evidencias_validacao/financeiro/03-financeiro-fornecedor.md`.
