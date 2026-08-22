import '../../data/models/fornecedor/fornecedor_model.dart';
import '../repositories/fornecedor_repository.dart';

class GerenciarFornecedores {
  GerenciarFornecedores(this.repository);

  final FornecedorRepository repository;

  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) {
    return repository.buscarPorUsuario(idUsuario);
  }

  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario) {
    return repository.buscarPorIdUsuario(idUsuario);
  }

  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor) {
    return repository.observarFornecedorAtivo(idFornecedor);
  }

  Future<void> atualizarFornecedor(FornecedorModel fornecedor) {
    return repository.atualizarFornecedor(fornecedor);
  }

  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  }) {
    return repository.atualizarStatusAtivo(
      idFornecedor: idFornecedor,
      ativo: ativo,
    );
  }

  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  }) {
    return repository.atualizarAptoParaOperar(
      idFornecedor: idFornecedor,
      apto: apto,
    );
  }

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  }) {
    return repository.atualizarFcmToken(
      idFornecedor: idFornecedor,
      token: token,
    );
  }
}
