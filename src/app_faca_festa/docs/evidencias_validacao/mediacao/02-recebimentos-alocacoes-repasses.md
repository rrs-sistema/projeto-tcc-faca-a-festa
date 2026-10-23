# Evidência — Prompt 02: Recebimentos, alocações e repasses

## Diagnóstico

| Conceito | Estado anterior | Lacuna |
|---|---|---|
| Liquidação em `orcamento/*/liquidacoes` | Perspectiva evento_pagador | Não prova recebimento pela plataforma nem repasse |
| Recebimento fornecedor | Conta a receber do fornecedor | Não é entrada do APP |
| Comissão plataforma | Obrigação própria | Separada, mas sem vínculo operacional recebimento→repasse |
| Política de liberação | Inexistente | Risco de liberar sem regra |

## Entrega

### Domínio (puro)
- `intermediacaoFinanceiraService.ts` / Dart espelho: direitos (desconto vs adição), alocação com teto, elegibilidade, transição de repasse, conciliação, chargeback pós-repasse.
- Dimensões explícitas: recebido, alocado, sem alocação, previsto/elegível/autorizado/confirmado, remuneração APP separada.

### Persistência (Functions)
Coleções (escrita só Admin SDK / callables):
- `plataforma_recebimentos`
- `plataforma_alocacoes`
- `plataforma_repasses`
- `plataforma_liberacao_repasses` (inativa por padrão)
- `plataforma_intermediacao_ajustes`
- `plataforma_intermediacao_auditoria`

Callables: `registrarRecebimentoPlataforma`, `alocarRecebimentoContratos`, `prepararRepasseFornecedor`, `confirmarRepasseManual`, `registrarAjustePosRepasse`, `consultarExtratoIntermediacao`, `salvarPoliticaLiberacaoRepasse`, `simularPosicaoIntermediacao`.

### Rules
Leitura admin; escrita negada no cliente.

### UI
Rota `/admin/intermediacao` + item no painel admin. Formulários mínimos de recebimento/alocação; lista de repasses com **Confirmar manual**. Simulação do cenário de aceite (ícone ciência). Sem cadastro de conta bancária.

## Aceite (testes)

| Cenário | Resultado |
|---|---|
| 10k / 5% descontada | Direito 9.500; comissão 500; sem duplicar cobrança |
| Parcial 4k sem política | A receber 6k; elegível 0; fornecedor não “recebeu” |
| Teto sintético 3k + confirmar | Repassado 3k; residual 1k não vira receita auto |
| Alocação 4k+3k sobre 6k | Rejeitada / concorrência aceita só A |
| Autorizar ≠ confirmado; chargeback | Histórico de repasse preservado |

Scripts: `functions/scripts/testIntermediacaoFinanceira.js`, `test/features/financeiro/intermediacao_financeira_test.dart`.

### Validação executada (local, sem deploy)

| Comando | Resultado |
|---|---|
| `npm --prefix functions run build` (`tsc`) | OK |
| `node functions/scripts/testIntermediacaoFinanceira.js` | 5/5 aceites OK |
| `fvm flutter test test/features/financeiro/intermediacao_financeira_test.dart` | 5/5 OK |
| `fvm dart analyze` (arquivos da entrega) | sem erros (infos cosméticos corrigidos) |

Não executado: emuladores autenticados end-to-end, deploy de rules/functions, migração, cobrança/repasse reais.

## Compatibilidade

- Legado `pago` / liquidação de orçamento **não** vira recebimento plataforma (`origem_legado_pago` permanece falso por padrão).
- Sem migração em produção.
- Sem deploy nesta entrega.
- Alterações anteriores (Prompt 01 identidade/contratação, comissão, AppBar, dashboard financeiro) preservadas.

## Ativação futura (roteiro)

1. `firebase deploy --only firestore:rules,functions:registrarRecebimentoPlataforma,functions:alocarRecebimentoContratos,functions:prepararRepasseFornecedor,functions:confirmarRepasseManual,functions:consultarExtratoIntermediacao,functions:salvarPoliticaLiberacaoRepasse,functions:simularPosicaoIntermediacao,functions:registrarAjustePosRepasse`
2. Criar política de liberação **inativa**; ativar só após decisão de produto.
3. Operar recebimento → alocação manual → preparar → confirmar manual.

## Decisões ainda pendentes

Prestador de pagamento, escrow, gatilho comercial de liberação, disputa/cancelamento jurídico — fora do escopo; política permanece configurável e inativa por padrão.
