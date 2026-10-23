# Evidência — Prompt 02 Dashboard financeiro do gerente do evento

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa`  
**Escopo:** visão do responsável autorizado (dono do evento) — contratado, pago, falta contratar, previsão vs limite, lista consolidada, detalhe, filtros e alertas.  
**Não feito:** deploy, commit, push, migração destrutiva, cobrança real, mensagens externas.

## 1. Diagnóstico

- Autorização do gerente = `evento.id_usuario` (organizador dono). Sem hierarquia empresarial inventada.
- Fundação do Prompt 01 reutilizada (`ResumoFinanceiroEventoService`, compromissos, liquidacoes).
- Home já tinha card “Financeiro da festa” apontando só para a aba Orçamento; agora abre o dashboard consolidado.
- `Evento.custoEstimado` = limite confirmado do cliente. Reserva de contingência lida se existir `reserva_contingencia` / `_centavos` no documento (Function); no modelo Dart tipado ainda default 0 até campo tipado.
- Calculadora/`ListaCompras` já marca buffet como `incluido` (falta 0) — previsão não soma compra coberta.

## 2. Regras

1. Previsão final = contratos atuais + necessidades descobertas restantes + despesas fora dos contratos + cancelamentos ainda devidos. **Pagamentos não entram de novo.**
2. Saldo contratado = contratado − pago líquido (sem clamp que esconda excesso).
3. Folga antes da reserva = limite − previsão; reserva fica separada.
4. Cobertura parcial: necessidade 100 / 60 contratadas → projeta 40 × preço.
5. Preço ausente → projeção parcial; `cabeNoLimite = null` (não afirma que cabe).
6. Buffet cobrindo alimentação (`cobertaPorBuffet` / `SituacaoCompra.incluido`) não duplica.
7. Escopos eliminados saem da projeção sem apagar histórico na origem.
8. Troca de sessão/evento chama `aoTrocarSessao` / `EventoSessionCoordinator.cancel` — cancela listeners e limpa previsões.
9. Function `consultarPrevisaoFinanceiraGerente` exige dono do evento (`permitirAdminEvento: false`).

## 3. Arquitetura

```
Menu / card home → /financeiroGerente
  FinanceiroGerenteController
    ← eventosDoUsuario (só id_usuario == sessão)
    ← CompromissosEventoRemote (listeners por evento + geração)
    → PrevisaoFinanceiraGerenteService (+ CoberturaParcial)
UI lista (tabela/cards) + detalhe + filtros (eixo mes_evento | mes_pagamento)
Backend: consultarPrevisaoFinanceiraGerente (Auth + Admin SDK)
```

## 4. Arquivos

### Domínio
- `lib/domain/entities/financeiro/alerta_financeiro.dart`
- `lib/domain/services/cobertura_parcial_necessidade_service.dart`
- `lib/domain/services/previsao_financeira_gerente_service.dart`

### UI / app
- `lib/presentation/modules/financeiro/controllers/financeiro_gerente_controller.dart`
- `lib/presentation/modules/financeiro/pages/financeiro_gerente_list_page.dart`
- `lib/presentation/modules/financeiro/pages/financeiro_gerente_detalhe_page.dart`
- `lib/app/bootstrap/financeiro_gerente_bootstrap.dart`
- `lib/app/bootstrap/evento_bootstrap.dart` (registro + session)
- `lib/presentation/coordinators/evento_session_coordinator.dart`
- `lib/presentation/modules/app/controllers/app_controller.dart` (logout limpa financeiro)
- `lib/presentation/widgets/menu_drawer_faca_festa.dart` (item Financeiro)
- `lib/presentation/modules/eventos/pages/home_event_screen.dart` (card abre dashboard)
- `lib/app/routes/app_routes.dart` (`/financeiroGerente`)

### Backend
- `functions/src/services/financeiro/previsaoGerenteService.ts`
- `functions/src/functions/financeiro/consultarPrevisaoGerente.ts`
- `functions/src/index.ts`

### Testes
- `test/features/financeiro/previsao_gerente_test.dart`
- `functions/scripts/testPrevisaoGerente.js`
- scripts: `check:financeiro`, `test:financeiro:gerente`

## 5. Formato / compatibilidade

Entrada de necessidades (cliente → Function ou `atualizarNecessidades`):

```json
{
  "id": "n1",
  "descricao": "Decoração",
  "quantidade_necessaria": 100,
  "quantidade_contratada": 60,
  "preco_unitario": 10,
  "custo_estimado_total": null,
  "coberta_por_buffet": false,
  "eliminada": false
}
```

Saída de previsão (domínio): limite, contratado, pagoLiquido, saldoContratado, faltaContratar, despesasAdicionais, custoFinalPrevisto, reserva, folgas, completo, cabeNoLimite, alertas, detalhes, contagens.

Compatível com compromissos do Prompt 01; não migra doubles legados.

## 6. Índices

Consulta `orcamento` por `id_evento` — índice existente. Sem índice novo.

## 7. Testes e resultados

```
fvm flutter test test/features/financeiro
→ 12 tests passed

npm --prefix functions run build → ok
npm --prefix functions run check:financeiro → ok
  (fundação + concorrência + auth + previsão gerente)

fvm dart format / analyze (arquivos do escopo)
→ format ok; analyze limpo após remover import não usado
```

### Critérios de aceite

| Critério | Resultado |
|---|---|
| 30k / 18k / 7k / 8k → saldo 11k, previsão 26k, folga 4k | OK (Dart + JS) |
| Buffet não duplica compra | OK |
| 100 un. com 60 → 40 restantes | OK |
| Sem preço → parcial, não afirma que cabe | OK |
| Troca sessão/evento limpa / invalida | OK (`aoTrocarSessao` + coordinator + logout) |

### Não executado

- `test:rules:financeiro` / emulador Firestore: JDK &lt; 21 no ambiente (mesmo bloqueio do Prompt 01).
- Deploy Functions; integração autenticada ponta a ponta no emulador Auth+Functions.
- Campo tipado `reservaContingencia` em `Evento` (lê 0 no cliente tipado; Function já aceita campo no documento).

Roteiro rules (com JDK 21+): `npm run test:rules:financeiro`.

## 8. Comportamento entregue na UI

- Menu **Mais → Financeiro** e toque no card financeiro da home abrem lista consolidada dos eventos do organizador logado.
- Contadores: eventos, contratos, linhas, fornecedores (separados).
- Tabela (desktop) / cards (mobile): limite, contratado, pago, saldo, falta contratar, previsão, alertas.
- Detalhe: métricas, folga, alertas verificáveis, linhas com necessidade/categoria/fornecedor/contrato/vencimento/fonte.
- Filtros: busca, estado comercial, eixo temporal (mês evento ≠ mês pagamento).

## 9. Ativação posterior (sem publicação)

1. JDK 21+ + `npm run test:rules:financeiro`.
2. Deploy deliberado de `consultarPrevisaoFinanceiraGerente` + cliente HTTPS se Windows.
3. Opcional: tipar `reserva_contingencia` em `Evento` e alimentar necessidades da calculadora via `atualizarNecessidades`.

## 10. Pendências / preexistente

- Prompts 03–06 (fornecedor, estoque, comissão, admin).
- Working tree preexistente (calculadora, MFA, fundação 01, etc.) preservado.
