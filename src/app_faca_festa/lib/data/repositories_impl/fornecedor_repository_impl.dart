import '../../domain/repositories/fornecedor_repository.dart';
import '../datasources/remote/fornecedor_remote_datasource.dart';
import '../models/fornecedor/fornecedor_model.dart';

class FornecedorRepositoryImpl implements FornecedorRepository {
  FornecedorRepositoryImpl(this.remote);

  final FornecedorRemoteDatasource remote;

  @override
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) {
    return remote.buscarPorUsuario(idUsuario);
  }

  @override
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) {
    return remote.atualizarFornecedor(fornecedor);
  }

  @override
  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  }) {
    return remote.atualizarStatusAtivo(
      idFornecedor: idFornecedor,
      ativo: ativo,
    );
  }

  @override
  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  }) {
    return remote.atualizarAptoParaOperar(
      idFornecedor: idFornecedor,
      apto: apto,
    );
  }

  @override
  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  }) {
    return remote.atualizarFcmToken(
      idFornecedor: idFornecedor,
      token: token,
    );
  }
}
