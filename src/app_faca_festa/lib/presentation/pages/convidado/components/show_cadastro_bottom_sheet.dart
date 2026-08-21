import 'package:flutter/material.dart';

/// Bottom sheet de cadastro: só fecha por ação explícita (Cancelar / Salvar).
Future<T?> showCadastroBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useSafeArea = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    builder: (context) => PopScope(
      canPop: false,
      child: builder(context),
    ),
  );
}
