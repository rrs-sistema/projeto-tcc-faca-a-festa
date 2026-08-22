import 'package:app_faca_festa/data/datasources/remote/documento_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/documento_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('delega exclusao de documento preservando colecao e id', () async {
    final remote = _DocumentoRemoteFake();
    final repository = DocumentoRepositoryImpl(remote);

    await repository.excluirDocumento(
      colecao: 'colecao_teste',
      idDocumento: 'documento-1',
    );

    expect(remote.colecao, 'colecao_teste');
    expect(remote.idDocumento, 'documento-1');
  });
}

class _DocumentoRemoteFake implements DocumentoRemoteDatasource {
  String? colecao;
  String? idDocumento;

  @override
  Future<void> excluirDocumento({
    required String colecao,
    required String idDocumento,
  }) async {
    this.colecao = colecao;
    this.idDocumento = idDocumento;
  }
}
