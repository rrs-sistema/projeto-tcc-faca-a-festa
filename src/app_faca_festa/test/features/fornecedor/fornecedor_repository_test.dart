import 'package:app_faca_festa/data/datasources/remote/fornecedor_remote_datasource.dart';
import 'package:app_faca_festa/data/models/fornecedor/fornecedor_model.dart';
import 'package:app_faca_festa/data/repositories_impl/fornecedor_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delega busca de fornecedor por usuario sem alterar o modelo', () async {
    final fornecedor = _fornecedor();
    final remote = _FornecedorRemoteFake(fornecedor: fornecedor);
    final repository = FornecedorRepositoryImpl(remote);

    final resultado = await repository.buscarPorUsuario('usuario-1');

    expect(resultado, same(fornecedor));
    expect(remote.idUsuarioBuscado, 'usuario-1');
  });

  test('delega atualizacao de token FCM preservando id e token', () async {
    final remote = _FornecedorRemoteFake();
    final repository = FornecedorRepositoryImpl(remote);

    await repository.atualizarFcmToken(
      idFornecedor: 'fornecedor-1',
      token: 'token-fcm',
    );

    expect(remote.idFornecedorToken, 'fornecedor-1');
    expect(remote.tokenFcm, 'token-fcm');
  });
}

class _FornecedorRemoteFake implements FornecedorRemoteDatasource {
  _FornecedorRemoteFake({this.fornecedor});

  final FornecedorModel? fornecedor;
  String? idUsuarioBuscado;
  String? idFornecedorToken;
  String? tokenFcm;

  @override
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) async {
    idUsuarioBuscado = idUsuario;
    return fornecedor;
  }

  @override
  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  }) async {
    idFornecedorToken = idFornecedor;
    tokenFcm = token;
  }
}

FornecedorModel _fornecedor() {
  return FornecedorModel(
    idFornecedor: 'fornecedor-1',
    idUsuario: 'usuario-1',
    razaoSocial: 'Doces Ana',
    telefone: '44999999999',
    email: 'ana@email.com',
    dataCadastro: DateTime(2026),
  );
}
