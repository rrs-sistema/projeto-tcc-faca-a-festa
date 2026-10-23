# Evidência — Prompt 03 Custos, caixa e resultado do fornecedor

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa`  
**Escopo:** financeiro privado da empresa fornecedora (vendas, recebimentos, custos internos, resultado direto, caixa).  
**Não feito:** deploy, commit, push, migração destrutiva, cobrança real, mensagens externas.

## 1. Diagnóstico

- Proprietário atual: `usuarios.tipo == 'F'` com `fornecedor/{uid}` — sem membros de empresa; acesso = `uid == idFornecedor`.
- Orçamentos com `id_fornecedor` expõem valor contratado ao fornecedor; **não** comprovam lucro.
- Subcoleções genéricas de `fornecedor/{id}/{sub}` eram legíveis por qualquer autenticado — **corrigido** para coleções financeiras privadas.
- Não há módulo de estoque empresarial maduro: custo manual com origem `estoque_consumo` (custo sem desembolso) evita duplicação futura.
- Pagamento do organizador (`orcamento_gasto` / liquidacoes evento) **não** é copiado como recebimento do fornecedor.

## 2. Regras

1. Perspectiva `fornecedor_privado` / `fornecedor_recebedor` distinta da do evento pagador.
2. A receber = contratado − recebido confirmado (independente de custos).
3. Custo incorrido ≠ obrigação ≠ desembolso; `estoque_consumo` gera custo sem saída de caixa.
4. Adiantamento → caixa; receita realizada só com execução/entrega explícita.
5. Resultado direto previsto/realizado com fórmula visível; margem de contribuição ≠ lucro líquido.
6. Comissão/taxas/tributos só se informados (sem inventar alíquotas); ausências → resultado parcial.
7. Sem saldo inicial → movimento líquido (não afirma saldo bancário).
8. Auth Functions e Rules: organizador, outro fornecedor e admin (outro uid) **negados**.

## 3. Arquitetura

```
Home fornecedor (card Financeiro) → /fornecedor/financeiro
  FinanceiroFornecedorController (tag por id)
    → Functions: consultarResumo / registrarCusto / registrarRecebimento
    → listeners privados: custos_internos, contas_receber, movimentos_caixa
Persistência: fornecedor/{idFornecedor}/custos_internos|contas_receber|contas_pagar|movimentos_caixa
```

## 4. Arquivos

### Domínio
- `lib/domain/entities/financeiro/custo_interno_fornecedor.dart`
- `lib/domain/services/resumo_financeiro_fornecedor_service.dart`

### Cliente
- `lib/data/datasources/remote/financeiro_fornecedor_remote_datasource.dart`
- `lib/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart`
- `lib/presentation/modules/financeiro/pages/financeiro_fornecedor_page.dart`
- `lib/presentation/modules/fornecedor/sections/resumo_section.dart` (atalho)
- `lib/app/routes/app_routes.dart`

### Backend / rules
- `functions/src/services/financeiro/autorizacaoFornecedorFinanceiro.ts`
- `functions/src/services/financeiro/resumoFornecedorService.ts`
- `functions/src/functions/financeiro/comandosFinanceiroFornecedor.ts`
- `functions/src/index.ts`
- `firestore.rules` (coleções privadas só dono)

### Testes
- `test/features/financeiro/financeiro_fornecedor_test.dart`
- `functions/scripts/testFinanceiroFornecedor.js`
- `test/firestore/financeiro_fornecedor.rules.test.js`
- scripts: `check:financeiro`, `test:financeiro:fornecedor`, `test:rules:financeiro:fornecedor`

## 5. Formato persistido (centavos)

```json
{
  "schema": 1,
  "id_custo": "...",
  "id_fornecedor": "...",
  "id_evento": "...",
  "tipo": "material|mao_de_obra|terceiros|transporte|montagem|locacao|perdas|outro",
  "valor_incorrido": { "centavos": 300000, "moeda": "BRL" },
  "valor_obrigacao": { "centavos": 0, "moeda": "BRL" },
  "valor_desembolso": { "centavos": 0, "moeda": "BRL" },
  "previsto_restante": { "centavos": 200000, "moeda": "BRL" },
  "origem": "manual|estoque_consumo|obrigacao|desembolso",
  "reutilizavel": false,
  "perspectiva": "fornecedor_privado",
  "chave_idempotencia": "..."
}
```

Recebimento: `contas_receber` + espelho `movimentos_caixa` (entrada). Flag `adiantamento` / `execucao_confirmada` separa caixa de receita.

## 6. Compatibilidade / índices

- Reutiliza `orcamento` por `id_fornecedor` (+ `id_evento`) — índice composto já existente.
- Sem migração silenciosa de doubles legados.
- Working tree preexistente (prompts 01–02, calculadora, etc.) preservado.

## 7. Testes e resultados

```
fvm flutter test test/features/financeiro/financeiro_fornecedor_test.dart
→ 5 passed

npm --prefix functions run build → ok
npm --prefix functions run check:financeiro → ok (inclui testFinanceiroFornecedor.js)

fvm dart format (escopo) → ok
fvm dart analyze (controller + domínio + page + remote) → No issues found
```

### Critérios de aceite

| Critério | Evidência |
|---|---|
| 10k contratado / 4k recebido → a receber 6k | Dart + JS |
| Custos 3k + 2k restante → previsto 5k; outras ausentes explícitas | Dart + JS |
| Estoque prévio: custo sem saída de caixa | Dart + JS + origem `estoque_consumo` |
| Adiantamento: caixa sem receita realizada | Dart + JS |
| Org/outro/admin sem uid dono: negado | JS auth + rules test (emulador) |

### Não executado

- `npm run test:rules:financeiro:fornecedor` — JDK &lt; 21 no ambiente (mesmo bloqueio anterior).
- Deploy Functions/rules; integração autenticada ponta a ponta no emulador.
- Contas a pagar completas na UI (modelo/rules prontos; registro via custos/obrigação).
- Rateio indireto (exigiria base/período/regra explícitos — não inventado).

Roteiro rules: instalar JDK 21+ e `npm run test:rules:financeiro:fornecedor`.

## 8. Comportamento na UI

- Card **Financeiro** no resumo do fornecedor abre tela privada.
- Mostra contratado, recebido, a receber, custos, resultado (fórmula + completude), caixa.
- Formulários: custo manual/desembolso, consumo de estoque, recebimento com execução, adiantamento (só caixa).
- Filtro por evento; listeners cancelados em `aoTrocarSessao` / `onClose`.

## 9. Ativação posterior

1. JDK 21+ + teste de rules.
2. Deploy deliberado das três callables + rules.
3. Opcional: integrar estoque real ao origem `estoque_consumo` no Prompt 04.

## 10. Pendências / preexistente

- Prompt 04 estoque; 05 comissões plataforma; 06 admin.
- Alterações locais prévias preservadas.
