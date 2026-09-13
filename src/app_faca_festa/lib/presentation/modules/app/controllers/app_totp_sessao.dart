import 'package:get_storage/get_storage.dart';

class AppTotpSessao {
  AppTotpSessao(
    this._storage, {
    required bool Function() contaTemLoginComSenha,
  }) : _contaTemLoginComSenha = contaTemLoginComSenha;

  static const String _chaveLoginMetodo = 'login_metodo';
  static const String _metodoSenha = 'senha';
  static const String _metodoGoogle = 'google';

  final GetStorage _storage;
  final bool Function() _contaTemLoginComSenha;

  bool verificadoNestaSessao = false;

  void marcarLoginComSenha() {
    verificadoNestaSessao = false;
    _storage.write(_chaveLoginMetodo, _metodoSenha);
  }

  void marcarLoginComGoogle() {
    verificadoNestaSessao = true;
    _storage.write(_chaveLoginMetodo, _metodoGoogle);
  }

  void marcarVerificado() {
    verificadoNestaSessao = true;
  }

  bool deveExigir() {
    if (verificadoNestaSessao) return false;
    if (_storage.read(_chaveLoginMetodo) == _metodoGoogle) return false;
    if (!_contaTemLoginComSenha()) return false;
    return true;
  }

  void limpar() {
    verificadoNestaSessao = false;
    _storage.remove(_chaveLoginMetodo);
  }
}
