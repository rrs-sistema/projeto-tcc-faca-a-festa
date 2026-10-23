# Evidência — Prompt 05 Percentual e comissões da plataforma

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa`  
**Escopo:** política de comissão, simulação, obrigação por contratação elegível, liquidação manual e ajustes — sem cobrança externa.  
**Não feito:** deploy, commit, push, migração destrutiva, cobrança real, mensagens externas.

## 1. Diagnóstico

- Não havia módulo de comissão de plataforma; fornecedor só informava comissão manual no P&L privado.
- Contratação elegível: fechamento de cotação (`fecharCotacao`) gera orçamento/contrato; volume contratado ≠ receita da plataforma.
- Decisões comerciais (pagador, exigibilidade, retenções) **modeladas explicitamente** e documentadas como pendentes de aprovação.
- Novas políticas: **inativas por padrão**. Simulação não persiste. Sem dívida retroativa.

## 2. Regras

1. Base preferencial: `servicos_contratados_plataforma` (não limite global do cliente).
2. Percentual em basis points (0–10000); **zero válido ≠ ausente**.
3. Snapshot imutável `politica_aplicada` na obrigação; mudança global não recalcula anteriores.
4. Geração única por contrato (`comissao-{idContrato}`); estados: previsão/gerada/a_vencer/vencida/recebida/estornada.
5. Liquidação = registro manual (`confirmacao_bancaria: false`).
6. Reversão proporcional: redução elegível → ajuste negativo + crédito/reembolso explícito.
7. Auth: configurar/ativar/liquidar = admin (`A`); pagador lê só `id_pagador == uid`.
8. Hook `fecharCotacao`: tenta gerar só se política ativa; falha silenciosa se ausente/inativa.

## 3. Arquitetura

```
Admin /admin/comissoes  → política, simulação, extrato, liquidação
Fornecedor /fornecedor/comissoes → extrato do pagador
Functions: salvar/ativar/simular/gerar/liquidar/ajustar/consultar
Persistência: plataforma_comissao_{politicas,obrigacoes,liquidacoes,ajustes,auditoria}
```

## 4. Arquivos

### Domínio
- `lib/domain/entities/financeiro/comissao_plataforma.dart`
- `lib/domain/services/comissao_plataforma_service.dart`

### Cliente
- `lib/data/datasources/remote/comissao_plataforma_remote_datasource.dart`
- `lib/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart`
- `lib/presentation/modules/financeiro/pages/comissao_plataforma_page.dart`
- `lib/app/routes/app_routes.dart`
- `lib/presentation/modules/admin/pages/admin_dashboard_screen.dart`
- `lib/presentation/modules/fornecedor/sections/resumo_section.dart`

### Backend / rules
- `functions/src/services/financeiro/comissaoPlataformaService.ts`
- `functions/src/services/financeiro/autorizacaoComissao.ts`
- `functions/src/functions/financeiro/comandosComissaoPlataforma.ts`
- `functions/src/functions/cotacao/fecharCotacao.ts` (hook opcional)
- `functions/src/index.ts`
- `firestore.rules`

### Testes
- `test/features/financeiro/comissao_plataforma_test.dart`
- `functions/scripts/testComissaoPlataforma.js`
- `test/firestore/comissao_plataforma.rules.test.js`
- scripts: `test:comissao`, `test:rules:comissao`; incluso em `check:financeiro`

## 5. Formato persistido

```json
{
  "schema": 1,
  "id_politica": "...",
  "versao": 1,
  "percentual_bps": 500,
  "base_elegivel": "servicos_contratados_plataforma",
  "pagador": "fornecedor|organizador|plataforma_absorve",
  "gatilho_geracao": "contratacao_confirmada|evento_realizado|manual",
  "reversao": "proporcional|nenhuma|manual",
  "ativa": false,
  "completa": true,
  "dias_vencimento_apos_geracao": 30,
  "observacoes_comerciais": "Decisões comerciais ainda pendentes de aprovação."
}
```

Obrigação: `valor_original`, `valor_ajustes_centavos`, `valor_liquidado`, `saldo_centavos`, `politica_aplicada` (snapshot).

## 6. Compatibilidade / índices

- Centavos inteiros; arredondamento `Math.round(base * bps / 10000)`.
- Índice single-field `ativa` / `id_pagador` / `id_evento` (automático).
- Working tree 01–04 + calculadora preservado.

## 7. Testes e resultados

```
fvm flutter test test/features/financeiro/comissao_plataforma_test.dart → 6 passed
node functions/scripts/testComissaoPlataforma.js → ok
npm --prefix functions run check:financeiro → ok
fvm dart analyze (escopo) → limpo após remoção de warning
```

### Critérios de aceite

| Critério | Evidência |
|---|---|
| 5% × R$10.000 = R$500 uma vez | Dart + JS |
| Taxa futura 6% preserva R$500 | Dart + JS (snapshot) |
| Liquidação R$200 → saldo R$300 | Dart + JS |
| Redução R$2.000 → ajuste R$100 + crédito explícito | Dart + JS |
| Ausente/inativa/incompleta não gera; simulação sem escrita | Dart + JS |
| Alteração não autorizada rejeitada | Auth admin-only + JS |

### Não executado

- `npm run test:rules:comissao` — JDK &lt; 21.
- Deploy; integração autenticada ponta a ponta.
- Cobrança externa / gateway.

Roteiro rules: JDK 21+ e `npm run test:rules:comissao`.

## 8. Ativação posterior

1. Aprovar decisões comerciais (pagador, vencimento, retenções).
2. Salvar política → ativar deliberadamente.
3. Deploy Functions + rules.
4. Opcional: claim `comissao_liquidar` separado de configurar.

## 9. Pendências / preexistente

- Prompt 06 admin consolidado.
- Alterações locais prévias (01–04) preservadas.
