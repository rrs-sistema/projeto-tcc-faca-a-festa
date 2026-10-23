# Evidência — Prompt 01: Identificação das partes e contratação rastreável

## Diagnóstico (antes)

| Fonte | Papel atual | Lacuna |
|---|---|---|
| `orcamento.id_solicitante` / `nome_solicitante` | quem abriu/aceitou o orçamento | não é necessariamente contratante ≠ pagador ≠ organizador |
| `evento.id_usuario` / `nome_evento` | proprietário/organizador | ausente no dashboard admin |
| `orcamento.id_fornecedor` / `nome_fornecedor` | prestador comercial | IDs no agregado; nomes não garantidos |
| `ContratoFinanceiro` | valor + estado comercial | sem snapshot de identidades; sem estado de execução |
| `consultarDashboardFinanceiroAdmin` | fatos por ID + linhas por evento | sem dossiê por contratação; “sincronizado” sem truncamento explícito |

## Entrega

### Domínio / persistência
- `SnapshotIdentidadeComercial` + `EstadoExecucaoContrato` + `LinhaContratacaoAdmin` (Dart).
- `ContratoFinanceiro` passa a persistir `estado_execucao` e `snapshot_identidade` (comercial ≠ execução).
- Backend: `contratacaoIdentidadeService.ts` (montagem de snapshot, pendências, resolução de linha).
- Aceite (`registrarOuAtualizarContrato`, `fecharCotacao`) grava snapshot no servidor sem inventar nomes.

### Consulta admin
- `consultarDashboardFinanceiroAdmin` carrega evento/fornecedor/usuário em lote.
- Resposta inclui `linhasContratacao` (evento, contratante, fornecedor, serviço, estados, pendências).
- `linhasEvento` enriquecidas com nome + lista de contratações do evento.
- `paginacao` / `consistencia.truncado` / `qtdIdentidadeIncompleta` explícitos.

### UI
- Seção **Por contratação** (tabela/cards) com detalhe Partes + Serviço/Contrato.
- Detalhe do evento lista contratações por fornecedor (não atribui fornecedor único).
- Avisos de truncamento e identificação incompleta.

## Aceite verificado em teste

| Critério | Como |
|---|---|
| Dois fornecedores, mesmo organizador | `testContratacaoIdentidade.js` + teste Flutter |
| Pagador ≠ contratante/organizador | script JS |
| Snapshot preservado vs perfil atual | script JS |
| Oportunidade ≠ serviço prestado | `contratado: false` na linha |
| Legado incompleto → pendência | `avaliarPendencias` |
| Comercial ≠ execução | contrato Dart + `estado_execucao` |

## Decisões ainda pendentes (produto)

Recebimento/repasse reais, elegibilidade, disputa, papel jurídico da plataforma — fora deste prompt; recursos permanecem inativos.

## Compatibilidade / migração

- Sem migração em produção. Legados sem snapshot recebem enriquecimento em leitura + `pendencias_identificacao`.
- Novos aceites passam a gravar snapshot.
- Sem deploy nesta entrega.

## Testes executados

- `npm --prefix functions run build` (+ correção TS)
- `node functions/scripts/testContratacaoIdentidade.js`
- `node functions/scripts/testDashboardAdmin.js`
- `fvm flutter test test/features/financeiro/contratacao_identidade_test.dart`
- `fvm dart analyze` nos arquivos alterados

## Arquivos principais

- `functions/src/services/financeiro/contratacaoIdentidadeService.ts`
- `functions/src/services/financeiro/contratoFinanceiroService.ts`
- `functions/src/functions/financeiro/consultarDashboardFinanceiroAdmin.ts`
- `functions/src/functions/cotacao/fecharCotacao.ts`
- `lib/domain/entities/financeiro/contratacao_identidade.dart`
- `lib/domain/entities/financeiro/contrato_financeiro.dart`
- `lib/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart`
- `lib/presentation/modules/financeiro/controllers/dashboard_financeiro_admin_controller.dart`
