import 'package:get_storage/get_storage.dart';

/// Mantém o token do convite de co-organizador entre login e aceite.
class TokenConviteCoOrganizador {
  TokenConviteCoOrganizador._();

  static const _chave = 'convite_co_organizador_pendente';
  static String? _memoria;

  static void guardar(String token) {
    final t = token.trim();
    if (t.isEmpty) return;
    _memoria = t;
    try {
      GetStorage().write(_chave, t);
    } catch (_) {
      // Memória já basta no mesmo ciclo de app.
    }
  }

  static String? ler() {
    final memoria = (_memoria ?? '').trim();
    if (memoria.isNotEmpty) return memoria;
    try {
      final valor = GetStorage().read(_chave);
      if (valor is String && valor.trim().isNotEmpty) {
        _memoria = valor.trim();
        return _memoria;
      }
    } catch (_) {}
    return null;
  }

  static void limpar() {
    _memoria = null;
    try {
      GetStorage().remove(_chave);
    } catch (_) {}
  }

  static String rotaAceite([String? token]) {
    final t = (token ?? ler() ?? '').trim();
    return t.isEmpty ? '/convite-organizador' : '/convite-organizador/$t';
  }
}
