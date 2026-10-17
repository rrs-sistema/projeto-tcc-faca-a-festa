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
  Future<InicioTotpMfa> iniciarTotpMfa() {
    return UpdateOperations.run(() async {
      try {
        return await remote.iniciarTotpMfa();
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<CodigoEmailMfa> solicitarCodigoEmailMfa() {
    return UpdateOperations.run(() async {
      try {
        return await remote.solicitarCodigoEmailMfa();
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> confirmarTotpMfa(String codigo) {
    return UpdateOperations.run(() async {
      try {
        await remote.confirmarTotpMfa(codigo);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> confirmarEmailMfa(String codigo) {
    return UpdateOperations.run(() async {
      try {
        await remote.confirmarEmailMfa(codigo);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> verificarTotpMfa(String codigo) {
    return UpdateOperations.run(() async {
      try {
        await remote.verificarTotpMfa(codigo);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

  @override
  Future<void> verificarEmailMfa(String codigo) {
    return UpdateOperations.run(() async {
      try {
        await remote.verificarEmailMfa(codigo);
      } on AutenticacaoRemoteException catch (erro) {
        throw AutenticacaoException(erro.codigo, erro.mensagem);
      }
    });
  }

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
