# Evidência — Prompt 06 Dashboard financeiro da administração

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa`  
**Escopo:** dashboard financeiro/comercial admin (oportunidades, contratos, execução, receita própria).  
**Não feito:** deploy, commit, push, migração destrutiva, cobrança real, mensagens externas.

## 1. Diagnóstico

- `AdminDashboardStats` cobre KPIs operacionais (eventos, fornecedores, orçamentos abertos) — **preservados**.
- Lista admin de orçamentos carregava gastos por documento (escala ruim para painel) — dashboard novo agrega no backend com campos do orçamento + amostra de liquidação/gasto.
- Comissão (Prompt 05) alimenta receita própria; volume contratado permanece distinto.
- Custos privados (`fornecedor/*/custos_internos`) **excluídos** da consulta e das rules de leitura admin.

## 2. Regras

1. Contagem por identidade: eventos ≠ contratos ≠ serviços ≠ categorias.
2. Alternativas da mesma `id_necessidade`: previsão usa máximo, não soma.
3. Separação: oportunidades | volume contratado | pagamentos eventos | receita plataforma (comissões recebidas).
4. Sem política/dados de comissão → “não configurado” (não inventa %).
5. Sem despesas próprias completas → rótulo `receitas_e_movimentos` (não lucro líquido).
6. Agregação pura idempotente; reabrir/repetir gatilho não muda totais.
7. Auth: somente `tipo == A`.

## 3. Arquitetura

```
Admin dashboard (card Financeiro) → /admin/financeiro
  DashboardFinanceiroAdminController
    → consultarDashboardFinanceiroAdmin (southamerica-east1)
      lê orcamento + plataforma_comissao_* (não custos privados)
      agregarDashboardAdmin (puro)
```

## 4. Arquivos

- `lib/domain/entities/financeiro/dashboard_financeiro_admin.dart`
- `lib/domain/services/dashboard_financeiro_admin_service.dart`
- `lib/data/datasources/remote/dashboard_financeiro_admin_remote.dart`
- `lib/presentation/modules/financeiro/controllers/dashboard_financeiro_admin_controller.dart`
- `lib/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart`
- `lib/app/routes/app_routes.dart` · `admin_dashboard_screen.dart`
- `functions/src/services/financeiro/dashboardAdminService.ts`
- `functions/src/functions/financeiro/consultarDashboardFinanceiroAdmin.ts`
- `functions/src/index.ts`
- testes + scripts `test:dashboard:admin` / `test:rules:dashboard:admin`

## 5. Formato / consistência

Resposta callable inclui contagens, valores em centavos, `linhas_evento`, `comissao_*`, `formula_abrangencia`, `consistencia` (fontes, exclusões, limite 500 orçamentos, reprocessamento sem backfill).

## 6. Índices

- `plataforma_comissao_politicas` where `ativa` (single-field).
- Sem collection group obrigatório para o caminho feliz (pago no doc).
- Amostra até 40 orçamentos incompletos consulta subcoleções `liquidacoes` / `orcamento_gasto`.

## 7. Testes

```
flutter test dashboard_financeiro_admin_test.dart → 6 passed
node testDashboardAdmin.js → ok
npm --prefix functions run check:financeiro → ok
fvm dart analyze (escopo) → No issues found
```

| Aceite | Status |
|---|---|
| 2 eventos × 3 contratos = 2 / 6 | OK |
| 100k movimentados + 5k comissão ≠ 100k receita | OK |
| Repetir agregação idempotente | OK |
| Alternativas não inflacionam | OK |
| Privados não vazam | rules test + exclusão na callable |

### Não executado

- `test:rules:dashboard:admin` — JDK &lt; 21.
- Deploy; integração autenticada ponta a ponta.

## 8. Ativação

1. Deploy callable + (opcional) rules.
2. Abrir Admin → Financeiro.
3. Exportação CSV usa mesmos filtros (copia clipboard).

## 9. Pendências / preexistente

- Cache persistido `plataforma_financeiro_dashboard/{periodo}` opcional.
- Despesas próprias da plataforma ainda manuais (parâmetro).
- Tree 01–05 preservada.
