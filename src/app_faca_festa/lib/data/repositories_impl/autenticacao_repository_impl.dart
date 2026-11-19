import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/resultados_operacao.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import '../datasources/remote/autenticacao_remote_datasource.dart';

class AutenticacaoRepositoryImpl implements AutenticacaoRepository {
  AutenticacaoRepositoryImpl(this.remote);

  final AutenticacaoRemoteDatasource remote;

  @override
  String? get idUsuarioAtual => remote.idUsuarioAtual;

  @override
  String? get emailUsuarioAtual => remote.emailUsuarioAtual;

  @override
  String? get nomeUsuarioAtual => remote.nomeUsuarioAtual;

  @override
  String? get fotoUsuarioAtual => remote.fotoUsuarioAtual;

  @override
  Stream<SessaoUsuario?> observarSessao() => remote.observarSessao().map(
        (sessao) => sessao == null
            ? null
            : SessaoUsuario(
                idUsuario: sessao.idUsuario,
                email: sessao.email,
              ),
      );

  @override
  bool get sessaoAnonima => remote.sessaoAnonima;

  @override
  bool get contaAtualTemLoginComSenha => remote.contaAtualTemLoginComSenha;

  @override
  bool get sessaoVisitanteConvite => remote.sessaoVisitanteConvite;

  @override
  Future<void> entrarAnonimamente() {
    return UpdateOperations.run(() async {
      try {
        await remote.entrarAnonimamente();
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> entrarComTokenCustomizado(String token) {
    return UpdateOperations.run(() async {
      try {
        await remote.entrarComTokenCustomizado(token);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> entrar({
    required String email,
    required String senha,
  }) {
    return UpdateOperations.run(() async {
      try {
        await remote.entrar(email: email, senha: senha);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<bool> entrarComGoogle() {
    return UpdateOperations.run(() async {
      try {
        return await remote.entrarComGoogle();
      } on AutenticacaoRemoteException catch (erro) {
        if (autenticacaoFoiCancelada(erro.codigo)) {
          return false;
        }
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<String> criarUsuario({
    required String email,
    required String senha,
  }) {
    return UpdateOperations.run(() async {
      try {
        return await remote.criarUsuario(email: email, senha: senha);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> solicitarCodigoRedefinicaoSenha({
    required String email,
  }) {
    return UpdateOperations.run(() async {
      try {
        await remote.solicitarCodigoRedefinicaoSenha(email: email);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> redefinirSenhaComCodigo({
    required String email,
    required String codigo,
    required String novaSenha,
  }) {
    return UpdateOperations.run(() async {
      try {
        await remote.redefinirSenhaComCodigo(
          email: email,
          codigo: codigo,
          novaSenha: novaSenha,
        );
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<InicioTotpMfa> iniciarTotpMfa({String? autorizacao}) =>
      _operarMfa(() => remote.iniciarTotpMfa(autorizacao: autorizacao));

  @override
  Future<CodigoEmailMfa> solicitarCodigoEmailMfa({String? autorizacao}) =>
      _operarMfa(
          () => remote.solicitarCodigoEmailMfa(autorizacao: autorizacao));

  @override
  Future<String> confirmarTotpMfa(String codigo, {String? autorizacao}) =>
      _operarMfa(
          () => remote.confirmarTotpMfa(codigo, autorizacao: autorizacao));

  @override
  Future<String> confirmarEmailMfa(String codigo, {String? autorizacao}) =>
      _operarMfa(
          () => remote.confirmarEmailMfa(codigo, autorizacao: autorizacao));

  @override
  Future<String> verificarTotpMfa(String codigo) =>
      _operarMfa(() => remote.verificarTotpMfa(codigo));

  @override
  Future<String> verificarEmailMfa(String codigo) =>
      _operarMfa(() => remote.verificarEmailMfa(codigo));

  @override
  Future<String> verificarCodigoRecuperacaoMfa(String codigo) =>
      _operarMfa(() => remote.verificarCodigoRecuperacaoMfa(codigo));

  @override
  Future<List<String>> gerarCodigosRecuperacaoMfa(String autorizacao) =>
      _operarMfa(() => remote.gerarCodigosRecuperacaoMfa(autorizacao));

  Future<T> _operarMfa<T>(Future<T> Function() operacao) {
    return UpdateOperations.run(() async {
      try {
        return await operacao();
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> definirMfaOpcional(bool ativar, String autorizacao) =>
      _operarMfa(() => remote.definirMfaOpcional(ativar, autorizacao));

  @override
  Future<bool> sessaoMfaVerificada() =>
      _operarMfa(() => remote.sessaoMfaVerificada());

  @override
  Future<void> sair() {
    return UpdateOperations.run(() async {
      try {
        await remote.sair();
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }
}
