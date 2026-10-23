# Evidência — Prompt 04: Acompanhamento das partes e validação da intermediação

## Diagnóstico

| Papel | Antes | Lacuna |
|---|---|---|
| Organizador (`financeiro_gerente_*`) | Previsão contratado/pago legado | Sem visão intermediada (declarado/conferido/confirmado) nem execução/aceite |
| Fornecedor (`financeiro_fornecedor_*`) | Caixa/custos privados | Risco de confundir pagamento cliente→APP com entrada própria |
| Execução | `estado_execucao` no contrato | Sem ações informar entrega / aceite / contestação |
| CTAs | — | Risco de “Pagar agora/Sacar” sem integração |

## Escolhas

- Declaração de pagamento do cliente é fato `declaracao` (`plataforma_pagamentos_declarados` + agregador no orçamento); **não** confirma recebimento nem libera repasse.
- Fornecedor vê alocado plataforma como **estado comercial** (`trataAlocadoComoCaixaProprio: false`).
- Comissão descontada marcada `comissaoJaDescontadaDoRepasse` — extrato de comissão ≠ dívida duplicada.
- Aceite só após `entrega_informada`; abrir detalhe/ler mensagem não aceita.
- Fechar/abrir mediação pela parte não executa reembolso.
- Sem gateway/saque/garantia: CTAs `Pagar agora`, `Sacar`, `Pagamento garantido` bloqueados na API/UI.
- Política de liberação ausente → próximo passo = pendência de **configuração**, sem prazo.

## Arquivos

### Backend
- `functions/src/services/financeiro/acompanhamentoPartesService.ts`
- `functions/src/services/financeiro/acompanhamentoPersistenciaService.ts`
- `functions/src/functions/financeiro/comandosAcompanhamentoPartes.ts`
- Export `index.ts`

### Rules
- `plataforma_pagamentos_declarados`: leitura autor/admin; escrita `false`

### Cliente
- Domínio/remote/controller Dart
- UI `/acompanhamento-organizador`, `/acompanhamento-fornecedor`
- Atalhos no detalhe financeiro do organizador e no financeiro do fornecedor

## Contrato API

| Callable | Quem |
|---|---|
| `consultarAcompanhamentoOrganizador` | dono/solicitante do evento |
| `consultarAcompanhamentoFornecedor` | fornecedor autorizado |
| `declararPagamentoPlataforma` | cliente (declaração) |
| `informarEntregaFornecedor` | fornecedor |
| `registrarAceiteCliente` | cliente (aceite ou contestação) |
| `abrirCasoMediacaoParte` | parte vinculada ao contrato |

Histórico de execução: `orcamento/{id}/execucao_historico` (imutável, idempotente por chave).

## Compatibilidade / migração dry-run

- Sem migração de produção.
- Legado `pago` permanece distinto; declaração nova não reescreve liquidação antiga.
- Prompts 01–03 preservados.

## Índices

- `plataforma_pagamentos_declarados`: `chave_idempotencia`, `id_orcamento_declarado` (se usado)
- `orcamento` por `id_evento` / `id_fornecedor` (já existentes no produto)
- Subcoleção `execucao_historico` por `chave_idempotencia`

## Cenário integrado (domínio + script)

Dois clientes (Ana + outra), dois fornecedores (Débora + outro), admin — modelado em `testAcompanhamentoPartes.js` / Flutter:

1. Ana contrata Débora R$ 10.000; declara R$ 4.000 → pendência conferência; Débora caixa 0.
2. Confirmação alocada R$ 4.000 → Ana a pagar R$ 6.000; Débora vê estado comercial, não caixa.
3. Comissão 5% descontada → líquido R$ 9.500; repasse confirmado R$ 3.000 → saldo previsto R$ 6.500.
4. Outro fornecedor/cliente: `acessoCruzadoNegado`.
5. Contestação após entrega: histórico preservado; sem reembolso.
6. Retry idempotente (chave) e CTAs bloqueados.

**Emuladores autenticados E2E:** não executados nesta entrega (sem projeto demo ligado nesta sessão). Roteiro:

```powershell
# Com emuladores Auth/Firestore/Functions ativos e seed demo:
node functions/scripts/testAcompanhamentoPartes.js
# Depois: login Ana → /acompanhamento-organizador; Débora → /acompanhamento-fornecedor
# Admin → /admin/intermediacao (conferir declaração ≠ alocação)
```

## Validação local executada

| Comando | Resultado |
|---|---|
| `npm --prefix functions run build` (`tsc`) | OK |
| `node functions/scripts/testAcompanhamentoPartes.js` | 7/7 aceites OK |
| `fvm flutter test test/features/financeiro/acompanhamento_partes_test.dart` | 5/5 OK |
| `fvm dart analyze` (arquivos da entrega) | No issues found |

Não executado: deploy, emuladores E2E autenticados, cobrança/repasse reais, envio externo.

## Ativação futura

1. Deploy rules + functions de acompanhamento (região `southamerica-east1`).
2. Operar declaração → conferência admin (Prompt 02) → alocação → repasse manual.
3. Só então considerar CTAs de gateway/saque se integração existir.

## Decisões pendentes

Prestador de pagamento, escrow, prazo de liberação, disputa jurídica, canal de mensagem automática.
