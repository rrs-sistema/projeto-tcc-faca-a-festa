# Evidência — Prompt 02 Premium: Comissões (administração + pagador)

**Data:** 2026-10-21  
**Escopo:** redesign de ergonomia/intuitividade da tela de comissões.  
**Não feito:** deploy, commit, push, correção de infraestrutura, mudança de regras/fórmulas.

## 1. Diagnóstico (antes)

- Simulador e formulário de política no topo.
- Listas “Políticas” / “Obrigações” sem hierarquia de tarefa.
- Pagador via a mesma composição administrativa (política + simulação em destaque).
- Liquidação embutida em cada card sem detalhe contextual.

## 2. Composição implementada

1. Cabeçalho “Comissões” + **Nova política** (somente admin), sob demanda.
2. Síntese: Gerado / Recebido / A receber a partir do extrato carregado.
3. Abas: **Cobranças** (entrada) · **Políticas** (admin) · **Simulador** (auxiliar).
4. Pagador: só Cobranças + Simulador (sem Políticas).
5. Detalhe da cobrança com regra aplicada (snapshot) e registro manual de recebimento.
6. Ativação de política com diálogo de confirmação (efeito explícito).
7. Simulador: resultado destacado + “Esta simulação não gera cobrança.”

Admin usa `AdminPalette` (verde-petróleo); pagador usa acento índigo do premium fornecedor.

## 3. Arquivos

- `lib/presentation/modules/financeiro/pages/comissao_plataforma_page.dart`
- `lib/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart` (totais, `enviando`, campos de simulação)
- `test/features/financeiro/comissao_plataforma_premium_test.dart`

## 4. Fluxos preservados

| Comando | Observação |
|---|---|
| `salvarPoliticaInativa` | continua `ativa: false` |
| `ativar` | só após confirmação na UI |
| `liquidar` | registro manual; motivo sem confirmação bancária |
| `simularLocal` | domínio local; não gera obrigação |

## 5. Testes

```
fvm dart analyze …comissao_plataforma_* → No issues found
fvm flutter test comissao_plataforma_premium_test.dart → 4 passed
```

| Aceite | Status |
|---|---|
| Cobranças como entrada | OK (aba inicial) |
| Simulador ≠ política ≠ cobrança | OK |
| Pagador sem Políticas | OK (2 abas) |
| Comandos/admin restritos | OK (guards existentes) |
| Fórmula/versão não alteradas | OK |

### Não executado

- Capturas multi-largura / texto 200% na sessão do usuário.
- Confirmação visual pós-hot-restart.

## 6. Limitações

- Nomes amigáveis de evento/pagador: usa referência curta do ID quando não há fonte autorizada de nome.
- Totais da síntese refletem o extrato carregado (não inventam período fiscal).
- Erros de callable: banner de apresentação; causa de infra fora do escopo.
