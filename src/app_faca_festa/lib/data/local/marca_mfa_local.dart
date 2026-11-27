import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';

/// Lembra que a segunda etapa foi confirmada pelo servidor neste login.
///
/// Vale só para o mesmo `uid` e o mesmo horário de login: um novo login, ou
/// outro usuário no aparelho, volta a exigir a verificação online. As regras
/// do Firestore continuam exigindo a sessão MFA real no servidor.
class MarcaMfaLocal {
  MarcaMfaLocal([GetStorage? storage]) : _storage = storage;

  static const chave = 'mfa_sessao_local_v1';
  GetStorage? _storage;

  GetStorage? get _box {
    try {
      return _storage ??= GetStorage();
    } catch (_) {
      return null;
    }
  }

  static String? marcaDe(User? usuario) {
    final login = usuario?.metadata.lastSignInTime;
    if (usuario == null || login == null) return null;
    return '${usuario.uid}|${login.millisecondsSinceEpoch}';
  }

  void gravar(User? usuario) {
    final marca = marcaDe(usuario);
    if (marca == null) return;
    try {
      _box?.write(chave, marca);
    } catch (_) {}
  }

  bool confere(User? usuario) {
    final marca = marcaDe(usuario);
    if (marca == null) return false;
    try {
      return _box?.read(chave) == marca;
    } catch (_) {
      return false;
    }
  }

  void limpar() {
    try {
      _box?.remove(chave);
    } catch (_) {}
  }
}
