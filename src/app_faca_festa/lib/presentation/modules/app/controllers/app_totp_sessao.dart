import 'package:get_storage/get_storage.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';

class AppTotpSessao {
  AppTotpSessao(this._storage);

  static const String _chaveLoginMetodo = 'login_metodo';
  static const String _metodoSenha = 'senha';
  static const String _metodoGoogle = 'google';

  final GetStorage _storage;

  String? _usuarioVerificado;

  void marcarLoginComSenha() {
    _usuarioVerificado = null;
    _storage.write(_chaveLoginMetodo, _metodoSenha);
  }

  void marcarLoginComGoogle() {
    _usuarioVerificado = null;
    _storage.write(_chaveLoginMetodo, _metodoGoogle);
  }

  void marcarVerificado(String idUsuario) {
    _usuarioVerificado = idUsuario;
  }

  bool deveExigir(Usuario usuario) {
    return usuario.exigeMfaNoLogin && _usuarioVerificado != usuario.idUsuario;
  }

  void limpar() {
    _usuarioVerificado = null;
    _storage.remove(_chaveLoginMetodo);
  }
}
