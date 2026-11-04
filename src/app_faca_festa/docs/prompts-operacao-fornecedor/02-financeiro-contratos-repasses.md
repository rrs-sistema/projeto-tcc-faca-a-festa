# Prompt 02 — Unificação financeira por contrato

Implemente uma visão financeira coerente do fornecedor no Faça a Festa, em `D:\repository\unicesumar\tcc\app\src\app_faca_festa`. Stack: Flutter/GetX, Firestore e Functions TypeScript; Windows/PowerShell. Este pedido é autocontido e exige alterações concretas e validação.

Leia AGENTS.md aplicáveis, confira Git e implementação atual. Preserve trabalho em andamento, especialmente alterações de repasse e comissão. Reutilize serviços existentes; não crie outro livro financeiro. Não faça deploy, commit, push ou operações reais/produção.

## Diagnóstico a confirmar

O resumo mostra R$ 3.150,00 a receber enquanto o contrato mostra R$ 2.992,50 após comissão de R$ 157,50. O resumo consulta orçamentos/recebimentos privados; o acompanhamento consulta repasses. A comissão aparece também como cobrança a vencer. Não presuma cobrança efetivamente duplicada: já existem alterações de retenção e liquidação no código local.

Inspecione `functions/src/functions/financeiro/comandosFinanceiroFornecedor.ts`, `functions/src/services/financeiro/{resumoFornecedorService,intermediacaoPersistenciaService,liberacaoRepasseService,acompanhamentoPersistenciaService,comissaoPlataformaService}.ts`, o controller `financeiro_fornecedor_controller.dart` e as páginas financeiras correspondentes.

## Implementação

1. Estabeleça a identidade canônica por contratação e a origem de cada fato. Preserve compatibilidade com orçamento legado sem somá-lo novamente ao contrato. Use centavos inteiros e política de arredondamento explícita nos novos cálculos.
2. Reutilize a regra contratada para exibir bruto contratado, comissão, outras deduções identificadas, líquido previsto, repasse autorizado, confirmado e saldo líquido pendente. Comissão adicionada ao cliente ou absorvida pela plataforma não reduz automaticamente o direito do fornecedor.
3. Faça resumo, lista, detalhe e extrato de comissão convergirem para os mesmos fatos e revisões. Pagamento do cliente à plataforma não é caixa do fornecedor. Recebimento próprio e repasse são origens distintas; não transforme declaração em confirmação bancária.
4. Diferencie comissão prevista para retenção, retida e cobrada separadamente. Retenção e pagamento separado devem ser conciliados sem cobrança/baixa duplicada, inclusive em repasses parciais. Preserve autor, origem e histórico.
5. Mostre pendência, responsável e previsão apenas quando sustentados por política e dados reais. Dados indisponíveis não viram zero. Integre custos privados sem expô-los ao cliente ou administrador.

## Aceite

Contrato de R$ 3.150,00, desconto de 5%, sem outras deduções: bruto R$ 3.150,00, comissão R$ 157,50, líquido previsto e pendente R$ 2.992,50. Repasse confirmado de R$ 1.000,00 deixa R$ 1.992,50 pendentes em todas as telas. Pagamento apenas declarado pelo cliente não muda o recebido do fornecedor.

Teste comissão adicionada/absorvida, retenção parcial e integral, pagamento separado, cancelamento e estorno sem apagar fatos, contratos legados e indisponibilidade de consulta. Cubra regras, Functions e apresentação com os testes pertinentes; não use somente mocks como prova de integração. Documente compatibilidade e resultados em `docs/evidencias_validacao/operacao-fornecedor/02-financeiro-contratos-repasses.md` e entregue o resultado implementado com limitações explícitas.
