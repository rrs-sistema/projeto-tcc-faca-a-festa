# Área Admin - Itens Configuráveis da Calculadora

## Objetivo

Esta área administrativa permite manter, sem alteração de código, os itens usados pela calculadora inteligente do app **Faça a Festa**.

Ela gerencia duas coleções no Firestore:

- `calculadora_itens_base`: catálogo global de itens.
- `calculadora_evento_itens`: regras por tipo de evento e perfil de festa.

## Arquivos entregues

- `calculadora_itens_admin_controller.dart`
- `calculadora_itens_admin_page.dart`
- `calculadora_item_base_form_dialog.dart`
- `calculadora_evento_item_form_dialog.dart`
- `calculadora_itens_admin_binding.dart`
- `calculadora_itens_admin_routes_snippet.dart`

## Estrutura sugerida

```text
lib/features/calculadora/
  data/
    models/evento/
      calculadora_item_base_model.dart
      calculadora_evento_item_model.dart
    repositories/
      calculadora_itens_base_repository.dart
  presentation/
    bindings/
      calculadora_itens_admin_binding.dart
    controllers/
      calculadora_itens_admin_controller.dart
    pages/admin/
      calculadora_itens_admin_page.dart
    widgets/admin/
      calculadora_item_base_form_dialog.dart
      calculadora_evento_item_form_dialog.dart
```

## Rota sugerida

```dart
static const String calculadoraItensAdmin = '/calculadora/itens-admin';
```

```dart
GetPage(
  name: AppRoutes.calculadoraItensAdmin,
  page: () => const CalculadoraItensAdminPage(),
  binding: CalculadoraItensAdminBinding(),
  middlewares: [
    // Middleware padrão do projeto para admin/suporte.
  ],
),
```

## Segurança

A tela deve ser adicionada apenas ao menu administrativo e protegida pelo middleware/autorização já usado no projeto.

Além disso, as regras do Firestore devem permitir escrita nas coleções `calculadora_itens_base` e `calculadora_evento_itens` somente para usuários admin/suporte.

## Observações técnicas

- A tela não altera `CalculadoraFestaScreen`.
- A tela não remove o fallback local em `CalculadoraFestaService.itensPadraoEstimativa`.
- O controller administrativo não executa cálculo; ele apenas mantém dados.
- A calculadora continua usando o fluxo já implementado: Firestore como fonte principal e fallback local como segunda fonte.
