# Evidência — Prompt 01 Premium: Financeiro da empresa fornecedora

**Data:** 2026-10-21  
**Repositório:** `app_faca_festa`  
**Escopo:** redesign de ergonomia/intuitividade da tela Financeiro do fornecedor.  
**Não feito:** deploy, commit, push, correção de infraestrutura Firebase, mudança de regras financeiras.

## 1. Diagnóstico (antes)

- Filtro por “ID do evento” na entrada principal.
- Sete pills minúsculas em faixa com gradiente.
- Fórmula e textos técnicos na leitura principal.
- Formulários de custo/recebimento permanentes na rolagem.
- Alertas repetidos visualmente pela mesma causa.
- Campos “valor em centavos” pouco intuitivos.

## 2. Composição implementada

1. Cabeçalho “Financeiro” + ações **Registrar recebimento** (primária) e **Lançar custo** (secundária).
2. Barra contextual: chips de eventos já conhecidos nos fatos locais; “Mais opções” guarda identificador interno com explicação (sem catálogo de nomes autorizado nesta visão).
3. Quatro métricas: Contratado, Recebido, A receber, Custo previsto (+ detalhe de custos sob demanda).
4. Resultado e Caixa em duas colunas (≥768 px) / uma coluna no celular; “Ver pendências” e “Como é calculado” sob divulgação progressiva.
5. Alertas agrupados por causa (`agruparAlertasFinanceiros`).
6. Lançamentos consultáveis (custos/movimentos) em tabela desktop / lista mobile.
7. Formulários em dialog (desktop) ou bottom sheet (mobile); valor em R$ → centavos no comando; `enviando` evita duplo toque; Cancelar não grava.

## 3. Arquivos

- `lib/presentation/modules/financeiro/pages/financeiro_fornecedor_page.dart` (rewrite UI)
- `lib/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart` (apresentação: agrupamento, eventos conhecidos, `enviando`)
- `test/features/financeiro/financeiro_fornecedor_premium_test.dart`
- Vocabulário reutilizado: `fornecedor_premium_layout.dart` (`FornecedorPremiumPalette`, `PremiumSectionShell`, `PremiumMetricTile`)

## 4. Fluxos preservados

| Comando | Contrato |
|---|---|
| `registrarCustoManual` | mesmos `idEvento`, `valorCentavos`, origem manual/estoque_consumo |
| `registrarRecebimento` | mesmos parâmetros; adiantamento vs execução |
| Autorização | `uid == idFornecedor` |

## 5. Testes executados

```
fvm dart analyze …financeiro_fornecedor_page/controller → No issues found
fvm flutter test financeiro_fornecedor_premium_test.dart → 2 passed
fvm dart format … → ok
```

| Aceite | Status |
|---|---|
| 10k / 4k / 6k identificáveis sem fórmula | OK (teste widget) |
| Resultado parcial ≠ lucro/saldo bancário | OK (rótulos + pendências) |
| Grid desktop / coluna mobile | OK (código; QA visual multi-largura não instrumentado com capturas) |
| Comandos com mesmos IDs/valores | OK (contratos preservados) |
| Filtro sem memorizar ID quando há chips | OK quando há fatos locais; senão explica limitação |

### Não executado

- Capturas after em 360/390/768/1280/1920 e texto 200% (sessão Flutter do usuário).
- Teclado físico sistemático no Windows.
- Fonte de nomes de evento autorizada (lacuna registrada).

## 6. Limitações

- Sem lista autorizada nome+data de eventos do fornecedor: chips usam IDs já presentes nos fatos; campo interno fica em “Mais opções”.
- Erros de callable/rede: apresentação de banner mantida; causa de infraestrutura fora do escopo deste prompt.
- Escritas ainda dependem das Functions no ambiente (comportamento pré-existente).
