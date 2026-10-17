import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/repositories/documento_repository.dart';
import '../datasources/remote/documento_remote_datasource.dart';

class DocumentoRepositoryImpl implements DocumentoRepository {
  DocumentoRepositoryImpl(this.remote);

  final DocumentoRemoteDatasource remote;

  @override
  Future<void> excluirDocumento({
    required String colecao,
    required String idDocumento,
  }) {
    return UpdateOperations.run(() async {
      return remote.excluirDocumento(
        colecao: colecao,
        idDocumento: idDocumento,
      );
    });
  }
}
