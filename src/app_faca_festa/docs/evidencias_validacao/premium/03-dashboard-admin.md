# Evidência — Prompt 03 Premium: Dashboard financeiro administrativo

**Data:** 2026-10-21  
**Escopo:** redesign de ergonomia/intuitividade da Visão financeira (admin).  
**Não feito:** deploy, commit, push, correção de infraestrutura Firebase/Functions, mudança de fórmulas/centavos/permissões.

## 1. Diagnóstico (antes)

- Faixa longa de filtros verticais com botão **Aplicar** em largura extrema.
- Fornecedor exposto como ID na entrada principal, sem distinção de rascunho vs consulta aplicada.
- Pouca hierarquia executiva: volume contratado e comissão da plataforma competiam visualmente como se fossem a mesma natureza de receita.
- Exportação rotulada de forma genérica; risco de copiar CSV do recorte antigo com filtros novos não aplicados.
- Eventos sem tabela desktop / cards mobile com ação explícita de detalhe.

## 2. Composição implementada

1. Cabeçalho **Visão financeira** + contexto + estado da consulta; ações **Atualizar** e **Copiar CSV** (comportamento real: clipboard).
2. Barra compacta de filtros: referência temporal (data do evento × data da contratação, com rótulo do significado), fornecedor (identificador, com lacuna de nomes documentada), situação comercial; período AAAA-MM-DD em **Mais opções**.
3. Chip **Não aplicados** quando rascunho ≠ última consulta; Copiar CSV avisa e não usa recorte desatualizado sem indicação.
4. Síntese executiva (até 4 KPIs): Movimentado em contratos · Comissão gerada · Comissão recebida · Saldo de comissões — volume rotulado como não-receita própria.
5. Indicadores operacionais menores (eventos, contratos, serviços, fornecedores, oportunidades).
6. Bloco de receita própria da plataforma com incompletude/`comissaoConfigurada` explícitos; sem gráfico ornamental.
7. Eventos: tabela (≥768) / cards (mobile); **Ver detalhes** explícito (linha não finge navegação).
8. Vazio ≠ erro: falha de consulta em banner; lista vazia só com recorte sem linhas.

Área central limitada (~1400 px). Vocabulário `AdminPalette` / `admin_kit`.

## 3. Arquivos

- `lib/presentation/modules/financeiro/pages/dashboard_financeiro_admin_page.dart`
- `lib/presentation/modules/financeiro/controllers/dashboard_financeiro_admin_controller.dart` (`filtrosPendentes`, snapshot aplicado, `limparFiltros`, `consultarFn` para testes)
- `test/features/financeiro/dashboard_financeiro_admin_premium_test.dart`

## 4. Fluxos preservados

| Comando | Observação |
|---|---|
| `remote.consultar` / callable | mesmos parâmetros: eixo, período, idFornecedor, estado |
| `exportarCsv` | mesmas colunas; alinhado ao último `resumo` sincronizado |
| Autorização | rota `/admin/financeiro` + middleware `A` inalterados |

## 5. Testes executados

```
fvm dart analyze …dashboard_financeiro_admin_{page,controller}.dart → No issues found
fvm flutter test dashboard_financeiro_admin_premium_test.dart → 5 passed
fvm flutter test dashboard_financeiro_admin_test.dart → passed (domínio)
```

| Aceite | Status |
|---|---|
| R\$ 100.000 contratos ≠ R\$ 5.000 comissão / receita própria | OK (rótulos + fixture) |
| Eixo com significado explícito | OK |
| Filtros/exportação mesmo conjunto; pendentes avisados | OK |
| Desktop não estica a 1900 px | OK (maxWidth 1400) |
| Sem filtro simulado de nome de fornecedor | OK (lacuna documentada) |

### Não executado nesta sessão

- Capturas manuais em 360 / 390 / 768 / 1280 / 1920 px
- Texto ampliado a 200% no dispositivo do usuário
- Hot-restart visual no app Windows em execução

## 6. Limitações

- Sem catálogo autorizado de nomes de fornecedor → campo permanece identificador interno, sob “Mais opções” explicado.
- Sem série temporal no contrato da callable → sem gráfico de tendência.
- Erros de backend continuam banner de apresentação; causa de infra fora do escopo.
