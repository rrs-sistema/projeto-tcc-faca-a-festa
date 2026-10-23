# Evidência — Prompt 04 Estoque, reservas e custos por evento

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa`  
**Escopo:** estoque empresarial privado do fornecedor (itens, reservas, consumo, valorização CMP, custo de evento).  
**Não feito:** deploy, commit, push, migração destrutiva, cobrança real, mensagens externas.

## 1. Diagnóstico

- Estoque alimentar da calculadora (`operacao_calculadora_service` / lotes por evento) **não** é estoque empresarial: escopo de refeição/organizador, reservas por item de cardápio.
- Prompt 03 já previa origem `estoque_consumo` (custo sem desembolso) sem módulo de itens — este prompt cria a origem única do movimento.
- Auth: `uid == idFornecedor` (mesmo padrão do financeiro privado); sem membros de empresa.
- Lotes privados do organizador **não** são transferidos para a empresa.

## 2. Regras de negócio

1. Naturezas: `consumivel` | `reutilizavel` | `locado_terceiro`.
2. Reserva ≠ consumo ≠ pagamento. Compra (entrada) abastece estoque e pode gerar obrigação (`contas_pagar`), sem custo integral de evento.
3. Consumo atribui custo via `custos_internos` com `origem: estoque_consumo` e `valor_desembolso: 0`.
4. Reutilizáveis: capacidade por intervalo efetivo (montagem + transporte + desmontagem); limite 30 dias.
5. Valorização gerencial: **custo médio móvel** para consumíveis; seleção física por validade não altera o método.
6. Reutilizáveis: `custo_uso` configurado (não depreciação fiscal). Locados: `custo_locacao`.
7. Item `vencido` / `manutencao` não oferece disponibilidade.
8. Transições não descontam duas vezes; cancelamento só reserva `ativa`; idempotência por chave.

## 3. Arquitetura

```
Home fornecedor (card Estoque) → /fornecedor/estoque
  EstoqueFornecedorController
    → Functions: cadastrar / entrada / reservar / retirar / consumir / cancelar / devolver / consultar
    → listeners: estoque_itens
Consumo → estoque_movimentos + custos_internos (origem estoque_consumo)
Persistência: fornecedor/{id}/estoque_itens|estoque_reservas|estoque_movimentos
```

## 4. Arquivos

### Domínio
- `lib/domain/entities/financeiro/item_estoque_fornecedor.dart`
- `lib/domain/entities/financeiro/movimento_estoque_fornecedor.dart`
- `lib/domain/services/estoque_fornecedor_service.dart`

### Cliente
- `lib/data/datasources/remote/estoque_fornecedor_remote_datasource.dart`
- `lib/presentation/modules/financeiro/controllers/estoque_fornecedor_controller.dart`
- `lib/presentation/modules/financeiro/pages/estoque_fornecedor_page.dart`
- `lib/presentation/modules/fornecedor/sections/resumo_section.dart` (atalho)
- `lib/app/routes/app_routes.dart`

### Backend / rules
- `functions/src/services/financeiro/estoqueFornecedorService.ts`
- `functions/src/functions/financeiro/comandosEstoqueFornecedor.ts`
- `functions/src/index.ts`
- `firestore.rules` (estoque_* privados só dono)

### Testes / scripts
- `test/features/financeiro/estoque_fornecedor_test.dart`
- `functions/scripts/testEstoqueFornecedor.js`
- `test/firestore/estoque_fornecedor.rules.test.js`
- `npm run test:estoque:fornecedor` / `test:rules:estoque:fornecedor`
- `check:financeiro` inclui `testEstoqueFornecedor.js`

## 5. Formato persistido

```json
{
  "schema": 1,
  "id_item": "...",
  "id_fornecedor": "...",
  "nome": "Cadeira",
  "natureza": "consumivel|reutilizavel|locado_terceiro",
  "unidade": "un",
  "quantidade_total": 100,
  "quantidade_reservada": 60,
  "quantidade_em_uso": 0,
  "status": "disponivel|manutencao|vencido|inativo",
  "metodo_valorizacao": "custo_medio_movel",
  "custo_medio_unitario": { "centavos": 500, "moeda": "BRL" },
  "custo_uso": { "centavos": 0, "moeda": "BRL" },
  "custo_locacao": { "centavos": 0, "moeda": "BRL" },
  "montagem_minutos": 0,
  "transporte_minutos": 0,
  "desmontagem_minutos": 0,
  "perspectiva": "fornecedor_privado"
}
```

Reserva: `intervalo_inicio` / `intervalo_fim` efetivos + solicitados.  
Movimento consumo: `origem_custo: estoque_consumo`, `gera_desembolso: false`.

## 6. Compatibilidade / índices

- Sem migração silenciosa; centavos inteiros.
- Query de reservas por `id_item` (índice single-field automático).
- Histórico `orderBy criado_em` com fallback se índice ausente.
- Working tree preexistente (prompts 01–03, calculadora) preservado.

## 7. Testes e resultados

```
fvm flutter test test/features/financeiro/estoque_fornecedor_test.dart → 7 passed
node functions/scripts/testEstoqueFornecedor.js → ok
npm --prefix functions run check:financeiro → ok (inclui estoque)
fvm dart format / analyze (escopo) → No issues found
```

### Critérios de aceite

| Critério | Evidência |
|---|---|
| 100 / reserva 60 → concorrente 50 rejeitada | Dart + JS |
| Retirada não desconta novamente | Dart + JS |
| 10 cadeiras: não sobrepostos ok; conflito não | Dart + JS |
| Consumo 20 × R$5 = R$100 sem desembolso | Dart + JS + custo `estoque_consumo` |
| Idempotência; cancel só ativa | Dart + JS |
| Outra empresa / vencido / manutenção | JS auth + domain + rules test |

### Não executado

- `npm run test:rules:estoque:fornecedor` — JDK &lt; 21 (mesmo bloqueio).
- Deploy Functions/rules; integração autenticada ponta a ponta no emulador.
- FEFO físico de lote na UI (método CMP documentado; seleção física não altera valorização).

Roteiro rules: JDK 21+ e `npm run test:rules:estoque:fornecedor`.

## 8. Comportamento na UI

- Card **Estoque** no resumo do fornecedor.
- Cadastro de item (natureza, qtd, custo), filtros, alertas, reserva/consumo por evento.
- Sessão: listeners cancelados em `aoTrocarSessao` / `onClose`.

## 9. Ativação posterior

1. JDK 21+ + teste de rules.
2. Deploy deliberado das callables de estoque + rules.
3. Opcional: FEFO de lotes na retirada física; manutenção agendada.

## 10. Pendências / preexistente

- Prompt 05 comissões plataforma; 06 admin.
- Alterações locais prévias (01–03, calculadora) preservadas.
