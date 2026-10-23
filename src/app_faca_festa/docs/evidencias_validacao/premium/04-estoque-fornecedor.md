# Evidência — Prompt 04 Premium: Estoque da empresa fornecedora

**Data:** 2026-10-21  
**Escopo:** redesign de ergonomia/intuitividade da tela Estoque (fornecedor).  
**Não feito:** deploy, commit, push, correção de infraestrutura Firebase, novas operações de domínio (inventário, devolução UI, etc.).

## 1. Diagnóstico (antes)

- Formulário de cadastro permanente e largo no topo da leitura.
- Texto inicial de arquitetura (“Privado do fornecedor… calculadora…”) em vez da tarefa.
- Hierarquia fraca: consultar / cadastrar / reservar-consumir misturados no card.
- Quantidade padrão 10 e custo 5 pré-preenchidos (risco de gravar defaults).
- Evento por ID embutido em cada card; reserva/consumo sem confirmação do efeito.
- Vazio pouco orientado (“Nenhum item cadastrado.”).

## 2. Composição implementada

1. Cabeçalho **Estoque** + contexto curto; busca local por nome; CTA **Novo item**.
2. Síntese: contagem de **cadastros** por tipo (não soma 10 un + 5 kg).
3. Filtros Todos / Consumíveis / Reutilizáveis / Locados com contagem da lista carregada.
4. Alertas agrupados por causa (`agruparAlertasEstoque`).
5. Tabela desktop (≥768) / cards mobile: nome, tipo, livre/reservado/em uso (campos reais), custo; **Detalhes** explícito.
6. Cadastro sob demanda (painel lateral desktop / sheet mobile): placeholders sem defaults enviáveis; campos de reutilizável só quando tipo = reutilizável; Escape/Cancelar não grava.
7. Detalhe: consulta → Reservar ou Consumir; confirmação com efeito explícito; evento como identificador (lacuna de nomes documentada); intervalo na reserva.
8. Vazio inicial: “Seu estoque começa aqui” + **Cadastrar primeiro item**; vazio filtrado: limpar filtros.

Vocabulário: `FornecedorPremiumPalette`, `PremiumSectionShell`, `PremiumMetricTile`, `PremiumEmptyState`.

## 3. Arquivos

- `lib/presentation/modules/financeiro/pages/estoque_fornecedor_page.dart`
- `lib/presentation/modules/financeiro/controllers/estoque_fornecedor_controller.dart` (`buscaTexto`, `enviando`, contagens, `agruparAlertasEstoque`, `limparFiltros`)
- `test/features/financeiro/estoque_fornecedor_premium_test.dart`

## 4. Fluxos preservados

| Comando | Observação |
|---|---|
| `cadastrarItem` | mesmos parâmetros; `unidade` opcional; `enviando` anti duplo toque |
| `reservar` | idItem, idEvento, quantidade, início/fim ISO |
| `consumir` | idItem, idEvento, quantidade; custo atribuído ≠ pagamento |
| Autorização | `uid == idFornecedor` inalterada |

**Lacunas (não inventadas na UI):** devolução/manutenção/histórico; seletor de evento por nome; `retirar`/`cancelarReserva` do remote sem wiring no controller desta entrega.

## 5. Testes executados

```
fvm dart analyze …estoque_fornecedor_{page,controller}.dart → No issues found
fvm flutter test estoque_fornecedor_premium_test.dart → 5 passed
fvm flutter test estoque_fornecedor_test.dart → 7 passed (domínio)
```

| Aceite | Status |
|---|---|
| Consultar sem atravessar cadastro | OK |
| Contagem ≠ soma física | OK |
| Cancelar não grava | OK (fecha painel sem chamar remote) |
| Reserva ≠ consumo ≠ pagamento | OK (rótulos + confirmação) |
| Fórmulas/permissões inalteradas | OK |

### Não executado nesta sessão

- Capturas multi-largura / texto 200% no dispositivo do usuário
- Hot-restart visual no Chrome/Windows em execução

## 6. Limitações

- Evento permanece identificador interno (sem catálogo autorizado).
- Intervalo da reserva em texto ISO simplificado (contrato exige início/fim).
- Erros de listener/callable: banner de apresentação; causa de infra fora do escopo.
