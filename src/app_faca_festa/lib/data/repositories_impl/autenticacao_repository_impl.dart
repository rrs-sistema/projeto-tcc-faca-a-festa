import '../../domain/repositories/autenticacao_repository.dart';
import '../datasources/remote/autenticacao_remote_datasource.dart';

class AutenticacaoRepositoryImpl implements AutenticacaoRepository {
  AutenticacaoRepositoryImpl(this.remote);

  final AutenticacaoRemoteDatasource remote;

  @override
  String? get idUsuarioAtual => remote.idUsuarioAtual;

  @override
  String? get emailUsuarioAtual => remote.emailUsuarioAtual;

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
  Future<void> entrar({
    required String email,
    required String senha,
  }) async {
    try {
      await remote.entrar(email: email, senha: senha);
    } on AutenticacaoRemoteException catch (erro) {
      throw AutenticacaoException(erro.codigo);
    }
  }

  @override
  Future<void> entrarComGoogle() async {
    try {
      await remote.entrarComGoogle();
    } on AutenticacaoRemoteException catch (erro) {
      throw AutenticacaoException(erro.codigo);
    }
  }

  @override
  Future<String> criarUsuario({
    required String email,
    required String senha,
  }) async {
    try {
      return await remote.criarUsuario(email: email, senha: senha);
    } on AutenticacaoRemoteException catch (erro) {
      throw AutenticacaoException(erro.codigo);
    }
  }

  @override
  Future<void> sair() async {
    try {
      await remote.sair();
    } on AutenticacaoRemoteException catch (erro) {
      throw AutenticacaoException(erro.codigo);
    }
  }
}
