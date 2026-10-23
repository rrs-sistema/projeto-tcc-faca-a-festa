# Evidência — Prompt 07 Previsão financeira e cotação conforme orçamento

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa`  
**Escopo:** simulação por limite, cenários, precificação fornecedor, teto compartilhado — sem efeitos financeiros.  
**Não feito:** deploy, commit, push, cobrança real, mensagens externas.

## 1. Diagnóstico

- Previsão do gerente (Prompt 02) e `financeiroCalculadoraService` já separam incompleto/limite.
- Faltavam: fórmula margem+taxas na mesma base, cenários econômico/intermediário/completo, teto por serviço sem limite global, garantia explícita de simulação read-only.
- Calculadora/IA: números autoritativos; IA só explica — preservado.

## 2. Regras

1. Livres = limite − comprometido (antes de despesas/reserva).
2. Alternativas da mesma necessidade: uma por cobertura; não somar concorrentes.
3. Preço = custos / (1 − margem − taxas) se mesma base; denominador ≤ 0 rejeitado.
4. Markup ≠ margem; estoque usa custo de uso/consumo.
5. Fornecedor: só teto/faixa compartilhado explicitamente do seu serviço.
6. Valor ponderado comercial ≠ receita garantida.
7. `alteraFinanceiro: false` — não gera contrato/compra/reserva/pagamento/comissão.
8. Preço/histórico inválido → projeção parcial.

## 3. Arquitetura

```
Financeiro gerente (detalhe) → Simular cenários (local)
Callables: simularOrcamentoEvento | calcularPrecoFornecedor | consultarTetoCotacaoFornecedor
Domínio: SimulacaoOrcamentoEventoService + PrecificacaoFornecedorService
Reutiliza: PrevisaoFinanceiraGerenteService / ResumoFinanceiroEventoService
```

## 4. Arquivos

- `lib/domain/services/precificacao_fornecedor_service.dart`
- `lib/domain/services/simulacao_orcamento_evento_service.dart`
- `lib/presentation/modules/financeiro/controllers/financeiro_gerente_controller.dart`
- `lib/presentation/modules/financeiro/pages/financeiro_gerente_detalhe_page.dart`
- `functions/src/services/financeiro/precificacaoFornecedorService.ts`
- `functions/src/services/financeiro/simulacaoOrcamentoService.ts`
- `functions/src/functions/financeiro/simularOrcamentoEvento.ts`
- `functions/src/index.ts`
- `test/features/financeiro/simulacao_orcamento_test.dart`
- `functions/scripts/testSimulacaoOrcamento.js`

## 5. Formato

Simulação retorna centavos, cenários, `alteraFinanceiro: false`, `efeitos: {contrato,compra,reserva,pagamento,comissao: false}`, premissas e horizonte.

## 6. Compatibilidade

- Compromissos legados em reais no resumo; conversão ×100 explícita.
- Sem migração silenciosa; working tree 01–06 preservada.

## 7. Testes

```
flutter test simulacao_orcamento_test.dart → 5 passed
node testSimulacaoOrcamento.js → ok
check:financeiro → inclui simulação
```

| Aceite | Status |
|---|---|
| 20k / 15k → 5k livres | OK |
| Alternativas não somadas | OK |
| 700 / (1−0,2−0,1) = 1000 | OK |
| Histórico inválido → parcial | OK |
| Simulação sem fatos financeiros | OK |

### Não executado

- Emulador rules (JDK); deploy; E2E autenticado.

## 8. Ativação

Deploy das três callables; botão “Simular cenários” no detalhe do gerente já usa domínio local.

## 9. Pendências

- Hipóteses comerciais com coortes persistidas (opcional).
- Compartilhamento de teto na UI de cotação (callable pronta).
