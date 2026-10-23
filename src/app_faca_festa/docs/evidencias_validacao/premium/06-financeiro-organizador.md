# Evidência — Prompt 06 Premium: Financeiro do organizador

**Data:** 2026-10-21  
**Escopo:** redesign de lista + detalhe financeiros do organizador (`FinanceiroGerente*`, nomes internos preservados).  
**Não feito:** deploy, commit, push, correção de backend/regras, novo papel/permissão.

## 1. Diagnóstico (antes)

- Busca + chip de eixo toggle + chips comerciais densos no topo fixo (`Column` + `Expanded`).
- Eixo alternava ao toque sem opções explícitas; “Linhas” opaco.
- Contadores grandes antes da lista; na falha, zeros + mensagem central isolada.
- Detalhe: pills em gradiente misturando todos os números; códigos de alerta e simulador sem hierarquia clara.

## 2. Composição implementada

### Lista
1. Título **Financeiro dos meus eventos** + tema do organizador (`EventThemeController`).
2. Ações: Atualizar · Filtros · Limpar filtros (só se ativos).
3. Busca sincronizada com `filtroBusca` (controller + campo ao limpar/voltar).
4. Seleção explícita **Data do evento** / **Ref. pagamento** + ajuda honesta (não é extrato mensal).
5. Filtros adicionais em sheet: situação (eventos *com itens* naquele estado), período — Aplicar vs Cancelar.
6. Contadores compactos (Eventos, Contratos, Itens/serviços, Fornecedores) só após consulta válida.
7. Cards: nome, data, contratado/pago/saldo + **Ver financeiro**; aviso de parcial próximo.
8. `ListView` único (sem filtros presos consumindo altura).

### Detalhe
1. Orçamento: limite, previsão, folga/excesso (respeita `completo` / `cabeNoLimite`).
2. Contratos: contratado, pago, saldo, falta contratar, despesas.
3. Alertas agrupados (sem código interno na leitura principal).
4. **Como é calculado** sob demanda.
5. **Simular orçamento** secundário (`simularCenariosEvento`) — hipótese separada.
6. Serviços em tabela/cards.

## 3. Arquivos

- `lib/presentation/modules/financeiro/pages/financeiro_gerente_list_page.dart`
- `lib/presentation/modules/financeiro/pages/financeiro_gerente_detalhe_page.dart`
- `lib/presentation/modules/financeiro/controllers/financeiro_gerente_controller.dart` (rótulos eixo, `temFiltrosAtivos`, `mostrarContadores`, `totalItensServico`)
- `test/features/financeiro/financeiro_organizador_premium_test.dart`

## 4. Fluxos preservados

| Capacidade | Observação |
|---|---|
| `iniciar` / listeners compromissos | inalterados |
| `previsoesFiltradas` | mesma semântica (estado = eventos com linha naquele estado) |
| `abrirDetalhe` / retorno Get.to | busca/filtros no controller preservados |
| `simularCenariosEvento` | não altera contratos/limite |
| Autorização | `idUsuario == uid` |

## 5. Testes executados

```
fvm dart analyze …financeiro_gerente_{list,detalhe,controller}* → No issues found
fvm flutter test financeiro_organizador_premium_test.dart → 5 passed
fvm flutter test previsao_gerente_test.dart → passed (domínio)
```

| Aceite | Status |
|---|---|
| 30k / 18k / 7k / 8k → saldo 11k, previsão 26k, folga 4k | OK (domínio) |
| Sem preço → parcial, sem “Dentro do orçamento” | OK |
| Eixo explícito; Linhas → Itens/serviços | OK |
| Falha ≠ zeros confirmados | OK (UI omite contadores) |
| Sem mudança de permissões/backend | OK |

### Não executado

- Capturas 360–1920 / texto 200% no dispositivo do usuário.

## 6. Limitações

- CTA “criar evento” omitido (sem rota única estável no escopo; vazio só orienta).
- Eixo pagamento continua selecionando eventos por última data de pagamento — rótulo deixa claro que não é total pago no mês.
- Erros de listener: banner + tentar novamente; causa de infra fora do escopo.
