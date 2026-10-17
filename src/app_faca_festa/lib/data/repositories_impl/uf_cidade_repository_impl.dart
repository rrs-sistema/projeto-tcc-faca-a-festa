import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/uf_cidade.dart';
import 'package:app_faca_festa/domain/repositories/uf_cidade_repository.dart';
import '../datasources/remote/uf_cidade_remote_datasource.dart';

class UfCidadeRepositoryImpl implements UfCidadeRepository {
  UfCidadeRepositoryImpl(this.remote);

  final UfCidadeRemoteDatasource remote;

  @override
  Future<List<Estado>> carregarEstados() {
    return UpdateOperations.run(() async {
      return remote.carregarEstados();
    });
  }

  @override
  Future<List<Cidade>> carregarCidades(String idEstado) {
    return UpdateOperations.run(() async {
      return remote.carregarCidades(idEstado);
    });
  }
}
