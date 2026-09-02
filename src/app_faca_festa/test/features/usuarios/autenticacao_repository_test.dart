import 'package:app_faca_festa/data/datasources/remote/autenticacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/autenticacao_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expoe o usuario atual e delega a criacao da conta', () async {
    final remote = _AutenticacaoRemoteFake(
      idUsuarioAtual: 'usuario-atual',
      emailUsuarioAtual: 'atual@email.com',
      nomeUsuarioAtual: 'Atual',
      fotoUsuarioAtual: 'https://example.com/foto.jpg',
      contaAtualTemLoginComSenha: true,
    );
    final repository = AutenticacaoRepositoryImpl(remote);

    final idCriado = await repository.criarUsuario(
      email: 'ana@email.com',
      senha: 'segredo',
    );

    expect(repository.idUsuarioAtual, 'usuario-atual');
    expect(repository.emailUsuarioAtual, 'atual@email.com');
    expect(repository.nomeUsuarioAtual, 'Atual');
    expect(repository.fotoUsuarioAtual, 'https://example.com/foto.jpg');
    expect(repository.contaAtualTemLoginComSenha, isTrue);
    expect(idCriado, 'usuario-criado');
    expect(remote.email, 'ana@email.com');
    expect(remote.senha, 'segredo');
  });

  test('delega o login preservando email e senha', () async {
    final remote = _AutenticacaoRemoteFake();
    final repository = AutenticacaoRepositoryImpl(remote);

    await repository.entrar(email: 'login@email.com', senha: 'senha-login');

    expect(remote.email, 'login@email.com');
    expect(remote.senha, 'senha-login');
    expect(remote.entradas, 1);
  });

  test('delega o login com Google', () async {
    final remote = _AutenticacaoRemoteFake();
    final repository = AutenticacaoRepositoryImpl(remote);

    final autenticou = await repository.entrarComGoogle();

    expect(autenticou, isTrue);
    expect(remote.entradasGoogle, 1);
  });

  test('converte o stream de sessao e delega o logout', () async {
    final remote = _AutenticacaoRemoteFake(
      sessoes: const [
        SessaoUsuarioRemote(
          idUsuario: 'usuario-1',
          email: 'sessao@email.com',
        ),
        null,
      ],
    );
    final repository = AutenticacaoRepositoryImpl(remote);

    final sessoes = await repository.observarSessao().toList();
    await repository.sair();

    expect(sessoes.first?.idUsuario, 'usuario-1');
    expect(sessoes.first?.email, 'sessao@email.com');
    expect(sessoes.last, isNull);
    expect(remote.saidas, 1);
  });

  test('converte o erro remoto em erro de dominio com o mesmo codigo',
      () async {
    final repository = AutenticacaoRepositoryImpl(
      _AutenticacaoRemoteFake(
        erro: const AutenticacaoRemoteException('email-already-in-use'),
      ),
    );

    expect(
      () => repository.criarUsuario(email: 'repetido@email.com', senha: '123'),
      throwsA(
        isA<AutenticacaoException>().having(
          (erro) => erro.codigo,
          'codigo',
          'email-already-in-use',
        ),
      ),
    );
    expect(
      () => repository.entrar(email: 'invalido@email.com', senha: '123'),
      throwsA(
        isA<AutenticacaoException>().having(
          (erro) => erro.codigo,
          'codigo',
          'email-already-in-use',
        ),
      ),
    );
    expect(
      repository.entrarComGoogle,
      throwsA(
        isA<AutenticacaoException>().having(
          (erro) => erro.codigo,
          'codigo',
          'email-already-in-use',
        ),
      ),
    );
    expect(
      repository.sair,
      throwsA(
        isA<AutenticacaoException>().having(
          (erro) => erro.codigo,
          'codigo',
          'email-already-in-use',
        ),
      ),
    );
  });

  test('reconhece cancelamento do provedor Google sem conta selecionada', () {
    expect(autenticacaoFoiCancelada('canceled'), isTrue);
    expect(autenticacaoFoiCancelada('web-context-canceled'), isTrue);
    expect(autenticacaoFoiCancelada('ERROR_WEB_CONTEXT_CANCELED'), isTrue);
    expect(autenticacaoFoiCancelada('popup-closed-by-user'), isTrue);
    expect(autenticacaoFoiCancelada('invalid-email'), isFalse);
    expect(const AutenticacaoException('web-context-canceled').foiCancelada,
        isTrue);
  });

  test('converte cancelamento remoto do Google em retorno false', () async {
    final repository = AutenticacaoRepositoryImpl(
      _AutenticacaoRemoteFake(googleCancelado: true),
    );

    expect(await repository.entrarComGoogle(), isFalse);
  });

  test('nao lanca excecao quando o remoto devolve cancelamento', () async {
    final repository = AutenticacaoRepositoryImpl(
      _AutenticacaoRemoteFake(
        erro: const AutenticacaoRemoteException('canceled'),
      ),
    );

    expect(await repository.entrarComGoogle(), isFalse);
  });
}

class _AutenticacaoRemoteFake implements AutenticacaoRemoteDatasource {
  _AutenticacaoRemoteFake({
    this.idUsuarioAtual,
    this.emailUsuarioAtual,
    this.nomeUsuarioAtual,
    this.fotoUsuarioAtual,
    this.contaAtualTemLoginComSenha = false,
    this.erro,
    this.googleCancelado = false,
    this.sessoes = const [],
  });

  @override
  final String? idUsuarioAtual;
  @override
  final String? emailUsuarioAtual;
  @override
  final String? nomeUsuarioAtual;
  @override
  final String? fotoUsuarioAtual;
  @override
  final bool contaAtualTemLoginComSenha;
  final AutenticacaoRemoteException? erro;
  final bool googleCancelado;
  final List<SessaoUsuarioRemote?> sessoes;
  String? email;
  String? senha;
  int entradas = 0;
  int entradasGoogle = 0;
  int saidas = 0;

  @override
  Stream<SessaoUsuarioRemote?> observarSessao() => Stream.fromIterable(sessoes);

  @override
  Future<void> sair() async {
    saidas++;
    if (erro != null) throw erro!;
  }

  @override
  Future<void> entrar({
    required String email,
    required String senha,
  }) async {
    this.email = email;
    this.senha = senha;
    entradas++;
    if (erro != null) throw erro!;
  }

  @override
  Future<bool> entrarComGoogle() async {
    entradasGoogle++;
    if (googleCancelado) return false;
    if (erro != null) throw erro!;
    return true;
  }

  @override
  Future<String> criarUsuario({
    required String email,
    required String senha,
  }) async {
    this.email = email;
    this.senha = senha;
    if (erro != null) throw erro!;
    return 'usuario-criado';
  }

  @override
  bool get sessaoAnonima => false;

  @override
  bool get sessaoVisitanteConvite => false;

  @override
  Future<void> entrarAnonimamente() async {
    if (erro != null) throw erro!;
  }

  @override
  Future<void> entrarComTokenCustomizado(String token) async {
    if (erro != null) throw erro!;
  }

  @override
  Future<void> solicitarCodigoRedefinicaoSenha({
    required String email,
  }) async {
    if (erro != null) throw erro!;
  }

  @override
  Future<void> redefinirSenhaComCodigo({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    if (erro != null) throw erro!;
  }

  @override
  Future<Map<String, dynamic>> iniciarTotpMfa() async {
    if (erro != null) throw erro!;
    return const {};
  }

  @override
  Future<Map<String, dynamic>> solicitarCodigoEmailMfa() async {
    if (erro != null) throw erro!;
    return const {};
  }

  @override
  Future<void> confirmarTotpMfa(String codigo) async {
    if (erro != null) throw erro!;
  }

  @override
  Future<void> confirmarEmailMfa(String codigo) async {
    if (erro != null) throw erro!;
  }

  @override
  Future<void> verificarTotpMfa(String codigo) async {
    if (erro != null) throw erro!;
  }

  @override
  Future<void> verificarEmailMfa(String codigo) async {
    if (erro != null) throw erro!;
  }
}
