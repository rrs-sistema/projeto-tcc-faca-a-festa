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

  test('delega observacao de fornecedor ativo preservando id', () async {
    final fornecedor = _fornecedor();
    final remote = _FornecedorRemoteFake(fornecedorAtivo: fornecedor);
    final repository = FornecedorRepositoryImpl(remote);

    final resultado =
        await repository.observarFornecedorAtivo('fornecedor-1').first;

    expect(resultado, same(fornecedor));
    expect(remote.idFornecedorObservado, 'fornecedor-1');
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

  test('delega atualizacao do fornecedor sem alterar o modelo', () async {
    final fornecedor = _fornecedor();
    final remote = _FornecedorRemoteFake();
    final repository = FornecedorRepositoryImpl(remote);

    await repository.atualizarFornecedor(fornecedor);

    expect(remote.fornecedorAtualizado, same(fornecedor));
  });

  test('delega atualizacao de status ativo preservando id e valor', () async {
    final remote = _FornecedorRemoteFake();
    final repository = FornecedorRepositoryImpl(remote);

    await repository.atualizarStatusAtivo(
      idFornecedor: 'fornecedor-1',
      ativo: false,
    );

    expect(remote.idFornecedorStatusAtivo, 'fornecedor-1');
    expect(remote.statusAtivo, isFalse);
  });

  test('delega atualizacao de aptidao operacional preservando id e valor',
      () async {
    final remote = _FornecedorRemoteFake();
    final repository = FornecedorRepositoryImpl(remote);

    await repository.atualizarAptoParaOperar(
      idFornecedor: 'fornecedor-1',
      apto: true,
    );

    expect(remote.idFornecedorApto, 'fornecedor-1');
    expect(remote.aptoParaOperar, isTrue);
  });
}

class _FornecedorRemoteFake implements FornecedorRemoteDatasource {
  _FornecedorRemoteFake({this.fornecedor, this.fornecedorAtivo});

  final FornecedorModel? fornecedor;
  final FornecedorModel? fornecedorAtivo;
  String? idUsuarioBuscado;
  String? idFornecedorObservado;
  String? idFornecedorToken;
  String? tokenFcm;
  FornecedorModel? fornecedorAtualizado;
  String? idFornecedorStatusAtivo;
  bool? statusAtivo;
  String? idFornecedorApto;
  bool? aptoParaOperar;

  @override
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) async {
    idUsuarioBuscado = idUsuario;
    return fornecedor;
  }

  @override
  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor) {
    idFornecedorObservado = idFornecedor;
    return Stream.value(fornecedorAtivo);
  }

  @override
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) async {
    fornecedorAtualizado = fornecedor;
  }

  @override
  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  }) async {
    idFornecedorStatusAtivo = idFornecedor;
    statusAtivo = ativo;
  }

  @override
  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  }) async {
    idFornecedorApto = idFornecedor;
    aptoParaOperar = apto;
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
