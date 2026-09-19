import 'package:get/get.dart';

/// Navegação da home do organizador (abas Festa / Convidados / Orçamento).
class HomeEventNavController extends GetxController {
  static const int abaHome = 0;
  static const int abaConvidados = 1;
  static const int abaOrcamento = 2;

  void Function(int index)? _onMudarAba;

  void vincular(void Function(int index) onMudarAba) {
    _onMudarAba = onMudarAba;
  }

  void desvincular([void Function(int index)? onMudarAba]) {
    if (onMudarAba == null || _onMudarAba == onMudarAba) {
      _onMudarAba = null;
    }
  }

  void irParaConvidados() => _mudarAba(abaConvidados);

  void irParaOrcamento() => _mudarAba(abaOrcamento);

  void irParaFornecedores() {
    _voltarParaHomeEventoSeNecessario();
    Get.toNamed('/fornecedores', preventDuplicates: false);
  }

  void _mudarAba(int index) {
    final mudarAba = _onMudarAba;
    if (mudarAba == null) return;
    _voltarParaHomeEventoSeNecessario();
    mudarAba(index);
  }

  void _voltarParaHomeEventoSeNecessario() {
    final navigator = Get.key.currentState;
    if (navigator == null || !navigator.canPop()) return;
    if (Get.currentRoute == '/HomeEventScreen') return;

    Get.until(
        (route) => route.settings.name == '/HomeEventScreen' || route.isFirst);
  }
}
