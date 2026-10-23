# Evidência — Prompt 05 Premium: Extrato de comissões do fornecedor (pagador)

**Data:** 2026-10-21  
**Escopo:** redesign da variante pagador/fornecedor de Comissões; admin preservado na mesma página.  
**Não feito:** deploy, commit, push, correção de infra, novos fluxos de pagamento.

## 1. Diagnóstico (antes)

- Mesmo título/linguagem administrativa para o pagador.
- Simulador como aba de primeiro nível (paridade com gestão).
- Risco de “Políticas” ou mensagem “só admin” como conteúdo de navegação.
- Coluna Pagador e registro de recebimento pouco adequados ao próprio extrato.

## 2. Composição implementada (pagador)

1. Título **Minhas comissões** · “Acompanhe as comissões dos seus contratos”.
2. Ação secundária **Simular comissão** (dialog/sheet) — hipótese separada do extrato.
3. Síntese: Total gerado · Pagamentos · Saldo; atraso só com status `vencida`.
4. Extrato como conteúdo principal (sem abas de gestão).
5. Tabela/cards: referência, taxa do snapshot, valor, saldo, situação.
6. Detalhe: taxa da contratação (não taxa global atual); sem liquidação admin; sem “Pagar agora”.
7. Vazio: “Nenhuma comissão encontrada” + contexto (não isenção permanente).

**Admin (inalterado na intenção):** abas Cobranças · Políticas · Simulador; Nova política; registro manual.

## 3. Arquivos

- `lib/presentation/modules/financeiro/pages/comissao_plataforma_page.dart`
- `lib/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart` (`qtdVencidas`, `percentualBpsAplicadoDe`, `baseElegivelCentavosDe`)
- `test/features/financeiro/comissao_pagador_premium_test.dart`

## 4. Fluxos preservados

| Comando | Pagador | Admin |
|---|---|---|
| `consultarExtrato` | `idPagador = uid` | sem filtro de pagador |
| `simularLocal` | hipótese local | idem |
| `salvarPoliticaInativa` / `ativar` / `liquidar` | bloqueados | ativos |

## 5. Testes executados

```
fvm dart analyze …comissao_plataforma_{page,controller}.dart → No issues found
fvm flutter test comissao_pagador_premium_test.dart → 6 passed
fvm flutter test comissao_plataforma_premium_test.dart → 4 passed
```

| Aceite | Status |
|---|---|
| Identifica cobrança/saldo sem menu admin | OK |
| Sem formulário de política / liquidação | OK |
| 5% × R\$ 10.000 → R\$ 500 simulado ≠ extrato | OK |
| Taxa do snapshot no detalhe | OK |
| Admin com abas/controles | OK (layout separado) |

### Não executado

- Capturas multi-largura / texto 200% no dispositivo do usuário.

## 6. Limitações

- Nome amigável de evento: continua referência curta de ID sem catálogo autorizado.
- Simulador usa placeholders “Ex.: 5 / 10000”; não pré-grava valores.
- Erros de callable: banner; causa de infra fora do escopo.
