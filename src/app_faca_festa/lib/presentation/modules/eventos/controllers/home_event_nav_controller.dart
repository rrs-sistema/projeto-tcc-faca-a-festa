import 'package:get/get.dart';

import 'package:flutter/widgets.dart';

/// Navegação da home do organizador (abas Home / Fornecedores / Inspiração).
class HomeEventNavController extends GetxController {
  HomeEventNavController({
    required Widget Function() fornecedoresPageBuilder,
  }) : _fornecedoresPageBuilder = fornecedoresPageBuilder;

  static const int abaFornecedores = 1;

  final Widget Function() _fornecedoresPageBuilder;
  void Function(int index)? _onMudarAba;

  void vincular(void Function(int index) onMudarAba) {
    _onMudarAba = onMudarAba;
  }

  void desvincular([void Function(int index)? onMudarAba]) {
    if (onMudarAba == null || _onMudarAba == onMudarAba) {
      _onMudarAba = null;
    }
  }

  void irParaFornecedores() {
    final mudarAba = _onMudarAba;
    if (mudarAba != null) {
      _voltarParaHomeEventoSeNecessario();
      mudarAba(abaFornecedores);
      return;
    }

    Get.to(
      _fornecedoresPageBuilder,
      routeName: '/fornecedores',
      preventDuplicates: false,
    );
  }

  void _voltarParaHomeEventoSeNecessario() {
    final navigator = Get.key.currentState;
    if (navigator == null || !navigator.canPop()) return;
    if (Get.currentRoute == '/HomeEventScreen') return;

    Get.until(
        (route) => route.settings.name == '/HomeEventScreen' || route.isFirst);
  }
}
