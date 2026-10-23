# Evidência — Prompt 01 Fundação financeira e conciliação

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa` (branch `main`, working tree com alterações preexistentes preservadas)  
**Escopo:** fonte confiável dos valores do evento, conciliação admin↔detalhe, contrato/obrigação/liquidação, resumo e conferência na área de orçamento.  
**Não feito (conforme contrato):** deploy, commit, push, migração destrutiva, cobrança real, mensagens externas.

## 1. Diagnóstico

### Campos legados (origem e significado)

| Campo / caminho | Significado | Limite |
|---|---|---|
| `orcamento.custo_estimado` | Estimativa / proposta; não é dívida | Planejamento |
| `orcamento.custo_real` | Custo realizado declarado (legado) | Não substitui contrato sozinho |
| `orcamento.valor_contratado` / `valor_contratado_centavos` | Valor contratado explícito | Obrigação comercial |
| `orcamento.orcamento_fechado` / `status=fechado` | Estado comercial contratado | Não prova pagamento |
| `orcamento.pago` (bool legado) | Flag antiga | **Não** comprova pagamento; deixa resumo incompleto |
| `orcamento_gasto.custo` / `.pago` | Despesa detalhada e liquidação parcial (legado double) | Perspectiva evento; não prova recebimento bancário do fornecedor |
| `orcamento.id_categoria` | Rótulo de categoria | Não dispensa consulta de pagamentos |
| `orcamento.id_cotacao` / `id_necessidade` | Agrupa alternativas de cotação | Alternativas são comparáveis, não somadas |
| `contrato_financeiro` (novo, schema 1) | Contrato com histórico, retenção, reembolso | Centavos BRL |
| `obrigacoes/*` (novo) | Parcelas / estado de liquidação | Separado do estado comercial |
| `liquidacoes/*` + `liquidacoes_idempotencia/*` | Liquidações com chave idempotente | Escrita só via Functions |

### Bug confirmado e corrigido

Em `orcamentos_admin_remote_datasource.dart`, quando existia `idCategoria`, o caminho administrativo **não** lia `orcamento_gasto` e deixava `pago = 0`, desalinhado do detalhe autorizado.  
**Correção:** sempre consulta o detalhe; categoria só nomeia o rótulo.

### Substituição indevida removida

`CompromissoPlanejamentoService` usava `max(custo_real, custo_estimado, soma gastos)` como `valor`/`contrato`.  
**Agora:** estimado, cotado, contratado, despesas e pago são fatos distintos; contrato usa `valor_contratado` / `contrato_financeiro` / estimado do fechamento — nunca o máximo com despesa.

## 2. Regras de negócio aplicadas

1. Estimativa ≠ cotação ≠ contratação ≠ despesa ≠ pagamento.
2. Alternativas da mesma `id_necessidade`: cotado/estimado = **máximo** do grupo; só o contratado gera saldo.
3. Pagamento > saldo → rejeição, salvo `credito` / `adiantamento` explícitos (sem clamp que esconda excesso).
4. Repetição com a mesma `chave_idempotencia` não duplica lançamento.
5. Cancelamento preserva histórico, pagamentos, retenção e reembolso; saldo permanece explicável.
6. Gerente = dono do evento (`evento.id_usuario`) ou solicitante do orçamento; Functions rejeitam evento alheio. Admin de plataforma não ganha custos privados de fornecedor.
7. Campos antigos **não** comprovam recebimento bancário nem custo privado.

## 3. Arquitetura

```
UI Orçamento (resumo + Conferir totais)
    ↓ observa
CompromissosEventoRemote (orcamento + orcamento_gasto + liquidacoes)
    ↓ mapeia
CompromissoPlanejamentoService → ResumoFinanceiroEventoService
    ↓ comandos críticos
FinanceiroEventoRemoteDatasource → Cloud Functions (southamerica-east1)
    → contratoFinanceiroService / liquidacaoFinanceiroService (Admin SDK + tx)
```

Perspectiva persistida: `evento_pagador`. Liquidações espelham `pago` em `orcamento_gasto` para conciliação com a UI legada, sem inventar recebimento do fornecedor.

## 4. Arquivos principais

### Domínio / cliente
- `lib/domain/entities/financeiro/valor_monetario.dart`
- `lib/domain/entities/financeiro/contrato_financeiro.dart`
- `lib/domain/entities/financeiro/obrigacao_financeira.dart`
- `lib/domain/entities/financeiro/liquidacao_financeira.dart`
- `lib/domain/services/compromisso_planejamento_service.dart` (reescrito)
- `lib/domain/services/resumo_financeiro_evento_service.dart` (limite, saldoDue, alternativas)
- `lib/data/datasources/remote/orcamentos_admin_remote_datasource.dart` (conciliação)
- `lib/data/datasources/remote/compromissos_evento_remote.dart` (liquidacoes)
- `lib/data/datasources/remote/financeiro_evento_remote_datasource.dart`
- `lib/presentation/modules/orcamento/controllers/orcamento_controller.dart`
- `lib/presentation/modules/orcamento/sections/orcamento_resumo_section.dart`
- `lib/presentation/modules/orcamento/pages/orcamento_screen.dart` (conferência)

### Backend
- `functions/src/services/financeiro/*`
- `functions/src/functions/financeiro/comandosFinanceiro.ts`
- `functions/src/functions/cotacao/fecharCotacao.ts` (grava contrato + obrigação)
- `functions/src/index.ts` (exports)
- `firestore.rules` (leitura autorizada; write direto de liquidação/obrigação = negado)

### Testes / scripts
- `test/features/financeiro/fundacao_financeira_test.dart`
- `test/features/admin/orcamentos_admin_conciliacao_test.dart`
- `test/firestore/financeiro.rules.test.js`
- `functions/scripts/testFinanceiroFundacao.js`
- `functions/scripts/testLiquidacaoConcorrencia.js`
- `functions/scripts/testAutorizacaoFinanceiro.js`
- scripts npm: `check:financeiro`, `test:financeiro`, `test:rules:financeiro`

## 5. Formato persistido (schema 1)

```json
{
  "contrato_financeiro": {
    "schema": 1,
    "id_contrato": "<id_orcamento>",
    "id_evento": "...",
    "id_orcamento": "...",
    "id_necessidade": "...",
    "valor": { "centavos": 1000000, "moeda": "BRL" },
    "estado_comercial": "contratado|cotado|cancelado|...",
    "perspectiva": "evento_pagador",
    "retencao": { "centavos": 0, "moeda": "BRL" },
    "reembolso": { "centavos": 0, "moeda": "BRL" },
    "historico": [],
    "origem": "comando_contrato|fechar_cotacao|legado_orcamento"
  }
}
```

`orcamento/{id}/obrigacoes/{id}` e `orcamento/{id}/liquidacoes/{id}` seguem o mesmo padrão de centavos.  
Legado `custo_estimado` / `orcamento_gasto.pago` (double) permanece legível; novos fatos preferem centavos. **Sem migração silenciosa em produção.**

## 6. Compatibilidade

- Calculadora / `ResumoCompras` continuam consumindo `valor`, `pago`, `contratado` dos compromissos.
- `valor` agora é compromisso de planejamento (contratado ou estimado), não max com despesa.
- Admin lista passa a mostrar `pago` conciliado com detalhe mesmo com categoria.
- Working tree preexistente (calculadora, MFA, etc.) não foi revertido.

## 7. Índices

Consultas novas são por documento pai (`orcamento/{id}/liquidacoes`, `obrigacoes`) — **não exigem índice composto novo** em `firestore.indexes.json`. Índice existente `orcamento` por `id_evento` permanece suficiente para listagens do evento.

## 8. Testes e resultados reais

### Executados com sucesso

```
fvm flutter test test/features/financeiro \
  test/features/admin/orcamentos_admin_conciliacao_test.dart \
  test/features/calculadora/financeiro_real_test.dart \
  test/features/orcamentos/orcamento_controller_test.dart
→ 20 tests passed

npm --prefix functions run build
→ ok

npm --prefix functions run check:financeiro
→ ok (centavos, 10k/3k/7k, alternativas, excesso, idempotência/concorrência, auth evento alheio)

fvm dart analyze <arquivos financeiros alterados>
→ No issues found

fvm dart format <arquivos financeiros alterados>
→ ok
```

### Critérios de aceite cobertos nos testes

| Critério | Evidência |
|---|---|
| Contrato 10k / pago 3k / saldo 7k | `fundacao_financeira_test` + `testFinanceiroFundacao.js` |
| 3 alternativas ≠ dívida 13,5k | mesmos |
| Admin + categoria concilia detalhe | `orcamentos_admin_conciliacao_test` + correção no datasource |
| Repetição / concorrência sem excesso | `testLiquidacaoConcorrencia.js` (+ tx Firestore no service) |
| Cancelamento com retenção/reembolso | `fundacao_financeira_test` |
| Evento alheio rejeitado (Functions) | `testAutorizacaoFinanceiro.js` + `exigirAcessoFinanceiroEvento` |

### Não executado / limitação de ambiente

```
npm run test:rules:financeiro
→ falhou: firebase-tools exige JDK 21+; ambiente local sem Java ≥ 21.
```

Roteiro reproduzível quando houver JDK 21:

```powershell
npm run test:rules:financeiro
```

Esperado: leitura do dono ok; intruso negado; write direto em `liquidacoes`/`obrigacoes` negado (comandos só via Functions).

### Também não executado

- Deploy das Functions / rules em projeto real.
- Integração autenticada contra emuladores Auth+Functions+Firestore de ponta a ponta (requer emulador completo e credenciais demo).
- `flutter test` da suíte inteira do repositório (fora do escopo; apenas testes financeiros e consumidores diretos).

Mocks unitários **não** substituem a integração Firebase; as Functions compiladas e a lógica de auth/tx estão cobertas offline; rules dependem do emulador (bloqueado por JDK).

## 9. Comportamento entregue na UI

- Resumo do orçamento exibe cotado, contratado, pago líquido e saldo devido.
- Botão **Conferir totais** abre os registros que explicam cada fato (origem/fonte).
- Troca de evento/sessão continua invalidando listeners (`_geracao` / `usuarioAtual`).

## 10. Ativação posterior (sem publicação nesta atividade)

1. Instalar JDK 21+ e rodar `npm run test:rules:financeiro`.
2. Em ambiente demo/emulador: `firebase emulators:start` + exercitar `registrarContratoFinanceiro` / `registrarLiquidacaoFinanceira` / `cancelarContratoFinanceiro`.
3. Revisar e fazer deploy deliberado (fora deste prompt): rules + functions na região `southamerica-east1`.
4. Não migrar double→centavos em lote sem job explícito e auditável.

## 11. Pendências conscientes (fora do Prompt 01)

- Dashboards gerente/fornecedor/admin, estoque e comissões (prompts 02–06).
- Espelho de recebimento no caixa do fornecedor (perspectiva distinta).
- Confirmação bancária externa real.
- Suite completa de emulador Auth+Functions para liquidação concorrente com Admin SDK.

## 12. Alterações preexistentes relevantes

O checkout já continha muitas mudanças locais (calculadora, MFA, jornada, etc.). Esta entrega **não** as reverteu; apenas adicionou/ajustou a fundação financeira e arquivos tocados pelo escopo.
