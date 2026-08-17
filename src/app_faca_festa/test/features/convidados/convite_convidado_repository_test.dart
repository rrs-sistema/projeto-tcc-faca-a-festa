import 'package:app_faca_festa/data/datasources/remote/convite_convidado_remote_datasource.dart';
import 'package:app_faca_festa/data/models/convidado/convidado_model.dart';
import 'package:app_faca_festa/data/repositories_impl/convite_convidado_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('token binding delegates every identity parameter unchanged', () async {
    final remote = _ConviteRemoteFake()..resultado = _convidado();
    final repository = ConviteConvidadoRepositoryImpl(remote);

    final resultado = await repository.vincularPorToken(
      token: 'token-1',
      uid: 'usuario-1',
      email: 'Pessoa@Email.com',
    );

    expect(resultado, same(remote.resultado));
    expect(remote.token, 'token-1');
    expect(remote.uid, 'usuario-1');
    expect(remote.email, 'Pessoa@Email.com');
  });

  test('user binding preserves null when no invitation is found', () async {
    final remote = _ConviteRemoteFake();
    final repository = ConviteConvidadoRepositoryImpl(remote);

    final resultado = await repository.buscarOuVincularPorUsuario(
      uid: 'usuario-2',
      email: 'sem-convite@email.com',
    );

    expect(resultado, isNull);
    expect(remote.uid, 'usuario-2');
    expect(remote.email, 'sem-convite@email.com');
  });
}

ConvidadoModel _convidado() {
  final data = DateTime(2026, 8, 14);
  return ConvidadoModel(
    idConvidado: 'convidado-1',
    idEvento: 'evento-1',
    nome: 'Ana',
    contato: '44999999999',
    dataCadastro: data,
    dataAtualizacao: data,
  );
}

class _ConviteRemoteFake implements ConviteConvidadoRemoteDatasource {
  ConvidadoModel? resultado;
  String? token;
  String? uid;
  String? email;

  @override
  Future<ConvidadoModel?> vincularPorToken({
    required String token,
    required String uid,
    required String email,
  }) async {
    this.token = token;
    this.uid = uid;
    this.email = email;
    return resultado;
  }

  @override
  Future<ConvidadoModel?> buscarOuVincularPorUsuario({
    required String uid,
    required String email,
  }) async {
    this.uid = uid;
    this.email = email;
    return resultado;
  }
}
