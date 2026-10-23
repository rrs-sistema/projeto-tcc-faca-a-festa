# Evidência — Prompt 03: Central administrativa de contratações e mediação

## Diagnóstico

| Área | Estado anterior | Lacuna |
|---|---|---|
| Dashboard financeiro admin | Agregados + “Por contratação” com expand | Sem central operacional com ações de mediação |
| Detalhe | Contagens/IDs e identidade Prompt 01 | Sem dossiê Partes / Financeiro intermediado / Caso |
| Casos de mediação | Inexistente | Sem trilha nota interna × compartilhável |
| Fechar / decidir | — | Risco de confundir status com efeito financeiro |

## Escolhas

- Lista principal **por contratação**; agrupamento por evento opcional na API (`agruparPorEvento`).
- Saldos **separados**: a receber do cliente × pendente de repasse × repassado — sem campo `saldo` único.
- Capacidades mínimas explícitas para tipo `A`: `consulta_comercial`, `notas_internas`, `decisao_mediacao`, `autorizacao_financeira`.
- Política de retenção **não definida** → `recomendarBloqueioRevisao` só grava recomendação no contrato do caso; não retém outros fornecedores do evento.
- Fechar/decidir **não** dispara reembolso/repasse; referências a comandos ficam auditáveis com `efeito_financeiro_executado: false`.
- Sem e-mail/WhatsApp automático ao solicitar informação.

## Arquivos

### Backend
- `functions/src/services/financeiro/mediacaoOperacionalService.ts`
- `functions/src/services/financeiro/mediacaoPersistenciaService.ts`
- `functions/src/functions/financeiro/consultarCentralContratacoes.ts`
- `functions/src/functions/financeiro/comandosMediacao.ts`
- Export em `functions/src/index.ts`

### Rules
- `plataforma_mediacao_casos` / `_registros` / `_auditoria`: leitura admin; escrita `false` (só Functions)

### Cliente
- Entidade/serviço Dart espelho
- Remote `CentralMediacaoRemote`
- UI `/admin/contratacoes-mediacao` + detalhe
- Atalhos: painel admin + Visão financeira (“Contratações e mediação”)

## Contrato de dados / API

### Coleções
| Coleção | Campos-chave |
|---|---|
| `plataforma_mediacao_casos` | id_evento, id_contrato, id_orcamento, partes, categoria, estado, responsável, recomendação_bloqueio, chave_idempotencia |
| `plataforma_mediacao_registros` | id_caso, tipo, visibilidade (`interna`\|`compartilhavel`), texto, efeito_financeiro_executado |
| `plataforma_mediacao_auditoria` | acao, autor_id, metadados |

### Callables
`consultarCentralContratacoes`, `consultarDetalheContratacao`, `abrirCasoMediacao`, `atribuirResponsavelCaso`, `registrarRegistroMediacao`, `solicitarInformacaoCaso`, `registrarDecisaoCaso`, `fecharCasoMediacao`, `recomendarBloqueioRevisao`, `consultarCasoMediacao`.

### Consulta central — paginação / completeness
- Limite amostra orçamentos: 200.
- Resposta inclui `paginacao.truncado`, `aviso` e `metricas_amostra.completo`.
- Contadores da tela **não** afirmam inventário global.

## Índices

Queries usadas:
- `plataforma_mediacao_casos`: `chave_idempotencia ==`
- `id_contrato ==` + `estado in [...]` (composto — criar no console se Firebase exigir no primeiro uso)
- `id_contrato in [...]` (casos abertos por lote)
- Alocações/repasses por `id_orcamento` (Prompt 02)

Dry-run: sem migração de produção; casos nascem sob demanda.

## Compatibilidade

- Prompt 01 (identidade) e Prompt 02 (intermediação) preservados e reutilizados.
- Legado `pago` aparece no detalhe como `legado_pago_centavos` com aviso — não vira recebimento plataforma.
- Sem deploy nesta entrega.

## Aceite (testes de domínio)

| Critério | Evidência |
|---|---|
| Operador vê nomes (cliente/fornecedor/serviço) | `testMediacaoOperacional.js` + Flutter |
| Caso em um contrato não afeta o outro | `escopoBloqueioRevisao` |
| Cliente só compartilhável; interna não exporta | `filtrarRegistrosPorPapel` / `registrosParaExportacao` |
| Fechar ≠ reembolso | `efeitosFinanceiros: []` |
| Pendências multi-estado | `montarLinhaCentral.pendencias` |
| Filtros/posição na volta | Controller mantém busca/offset/`scrollOffsetLista`; rota detalhe reutiliza mesmo tag GetX |

## Validação executada (local)

| Comando | Resultado |
|---|---|
| `npm --prefix functions run build` (`tsc`) | OK |
| `node functions/scripts/testMediacaoOperacional.js` | 5/5 aceites OK |
| `fvm flutter test test/features/financeiro/mediacao_operacional_test.dart` | 5/5 OK |
| `fvm dart analyze` (arquivos da entrega) | No issues found |

Não executado: deploy, emuladores autenticados E2E, e-mail/WhatsApp, retenção real, migração.

## Ativação futura (sem publicação agora)

1. Deploy rules + functions da lista acima (região `southamerica-east1`).
2. Criar índice composto de casos se o console solicitar.
3. Operar: Visão financeira → Contratações e mediação → Detalhe → Abrir caso → registros → fechar.
4. Só após política comercial: ativar retenção efetiva (hoje sempre `politicaRetencaoAtiva: false`).

## Decisões ainda pendentes

Prestador de pagamento, escrow, disputa jurídica, gatilho de liberação, retenção automática, canal oficial de comunicação com partes.
