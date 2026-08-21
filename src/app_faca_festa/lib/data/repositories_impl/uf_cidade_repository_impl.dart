import '../../domain/repositories/uf_cidade_repository.dart';
import '../datasources/remote/uf_cidade_remote_datasource.dart';

class UfCidadeRepositoryImpl implements UfCidadeRepository {
  UfCidadeRepositoryImpl(this.remote);

  final UfCidadeRemoteDatasource remote;

  @override
  Future<List<Map<String, dynamic>>> carregarEstados() {
    return remote.carregarEstados();
  }

  @override
  Future<List<Map<String, dynamic>>> carregarCidades(String idEstado) {
    return remote.carregarCidades(idEstado);
  }
}
