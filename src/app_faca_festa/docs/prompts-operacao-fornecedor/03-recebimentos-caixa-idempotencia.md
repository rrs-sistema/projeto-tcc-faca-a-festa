# Prompt 03 — Recebimentos e caixa sem duplicidade

Corrija a integridade dos recebimentos e do caixa privado do fornecedor no Faça a Festa, repositório `D:\repository\unicesumar\tcc\app\src\app_faca_festa`, Flutter/GetX e Firebase/Functions TypeScript, Windows/PowerShell. Implemente e teste; este prompt não depende do histórico de outro chat.

Leia AGENTS.md aplicáveis e Git, preserve alterações existentes e reconfirme os achados. Não faça deploy, commit, push nem altere produção. Use emuladores e dados sintéticos. Reutilize a identidade financeira atual e qualquer unificação de contratos já implementada.

## Problemas a investigar

- `registrarRecebimentoFornecedor` grava `contas_receber` e depois `movimentos_caixa` em operações separadas; uma falha intermediária pode deixar escrita parcial.
- O controller gera uma nova chave a cada tentativa. Timeout após persistência seguido de reenvio pode duplicar o fato.
- O cálculo local soma movimentos de entrada e recebimentos, potencialmente contando o mesmo fato duas vezes.
- O resumo agrupa recebimentos por evento, mas a lista por contrato reaplica esse total a cada orçamento.

Arquivos iniciais: `functions/src/functions/financeiro/comandosFinanceiroFornecedor.ts`, `functions/src/services/financeiro/resumoFornecedorService.ts`, `lib/domain/services/resumo_financeiro_fornecedor_service.dart`, `lib/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart` e regras de coleções financeiras privadas.

## Implementação

1. Defina identidade estável por operação, contrato e origem. Preserve a chave durante retries e reconcilie resultado desconhecido após timeout antes de criar outro lançamento. A mesma chave com payload diferente deve ser rejeitada.
2. Grave fato, projeções necessárias e auditoria atomicamente. Implemente idempotência e concorrência no backend; botão desabilitado não é garantia suficiente. Revise caminhos de escrita direta que poderiam contornar essas invariantes, sem remover a privacidade do fornecedor.
3. Cada recebimento deve alimentar o caixa uma única vez. Faça frontend e backend concordarem antes/depois de listeners, refresh e reabertura da sessão.
4. Aloque recebimento ao contrato correto. Para valor que cubra vários contratos, use alocação explícita cuja soma não exceda o fato. Legado sem vínculo deve ficar identificado como não alocado, sem atribuição arbitrária.
5. Trate adiantamento, repasse, recebimento externo, estorno e crédito excedente explicitamente. Não esconda excedentes com clamp nem reconheça execução integral por um recebimento parcial.

## Aceite e testes

Dois contratos do mesmo evento, R$ 2.000,00 e R$ 3.000,00: receber R$ 500,00 no primeiro deixa saldos de R$ 1.500,00 e R$ 3.000,00; o caixa cresce R$ 500,00 uma vez. Repetir a requisição e simular timeout pós-persistência não muda esses totais. Falha antes do commit não deixa espelho parcial.

Teste requisições concorrentes, payload divergente com mesma chave, listener seguido de refresh, adiantamento sem entrega, estorno e legado não alocado. Execute testes de domínio, backend e emulador pertinentes. Registre evidências em `docs/evidencias_validacao/operacao-fornecedor/03-recebimentos-caixa-idempotencia.md`, com resultados reais e limites de compatibilidade.
