import 'package:get/get.dart';

/// Navegação da home do organizador (abas Home / Fornecedores / Inspiração).
class HomeEventNavController extends GetxController {
  static const int abaFornecedores = 1;

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

    Get.toNamed('/fornecedores', preventDuplicates: false);
  }

  void _voltarParaHomeEventoSeNecessario() {
    final navigator = Get.key.currentState;
    if (navigator == null || !navigator.canPop()) return;
    if (Get.currentRoute == '/HomeEventScreen') return;

    Get.until(
        (route) => route.settings.name == '/HomeEventScreen' || route.isFirst);
  }
}
