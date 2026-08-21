import '../../data/models/fornecedor/fornecedor_model.dart';

abstract interface class FornecedorRepository {
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario);

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  });
}
