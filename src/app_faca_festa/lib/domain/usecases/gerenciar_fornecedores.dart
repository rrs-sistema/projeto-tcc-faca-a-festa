import '../../data/models/fornecedor/fornecedor_model.dart';
import '../repositories/fornecedor_repository.dart';

class GerenciarFornecedores {
  GerenciarFornecedores(this.repository);

  final FornecedorRepository repository;

  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) {
    return repository.buscarPorUsuario(idUsuario);
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
