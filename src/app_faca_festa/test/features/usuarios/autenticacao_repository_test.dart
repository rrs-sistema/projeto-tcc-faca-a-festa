import 'package:app_faca_festa/data/datasources/remote/autenticacao_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/autenticacao_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expoe o usuario atual e delega a criacao da conta', () async {
    final remote = _AutenticacaoRemoteFake(
      idUsuarioAtual: 'usuario-atual',
      emailUsuarioAtual: 'atual@email.com',
    );
    final repository = AutenticacaoRepositoryImpl(remote);

    final idCriado = await repository.criarUsuario(
      email: 'ana@email.com',
      senha: 'segredo',
    );

    expect(repository.idUsuarioAtual, 'usuario-atual');
    expect(repository.emailUsuarioAtual, 'atual@email.com');
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

    await repository.entrarComGoogle();

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
}

class _AutenticacaoRemoteFake implements AutenticacaoRemoteDatasource {
  _AutenticacaoRemoteFake({
    this.idUsuarioAtual,
    this.emailUsuarioAtual,
    this.erro,
    this.sessoes = const [],
  });

  @override
  final String? idUsuarioAtual;
  @override
  final String? emailUsuarioAtual;
  final AutenticacaoRemoteException? erro;
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
  Future<void> entrarComGoogle() async {
    entradasGoogle++;
    if (erro != null) throw erro!;
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
}
