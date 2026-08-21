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
  bool get sessaoVisitanteConvite => remote.sessaoVisitanteConvite;

  @override
  Future<void> entrarAnonimamente() async {
    try {
      await remote.entrarAnonimamente();
    } on AutenticacaoRemoteException catch (erro) {
      throw AutenticacaoException(erro.codigo);
    }
  }

  @override
  Future<void> entrarComTokenCustomizado(String token) async {
    try {
      await remote.entrarComTokenCustomizado(token);
    } on AutenticacaoRemoteException catch (erro) {
      throw AutenticacaoException(erro.codigo);
    }
  }

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
  Future<bool> entrarComGoogle() async {
    try {
      return await remote.entrarComGoogle();
    } on AutenticacaoRemoteException catch (erro) {
      if (autenticacaoFoiCancelada(erro.codigo)) {
        return false;
      }
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
