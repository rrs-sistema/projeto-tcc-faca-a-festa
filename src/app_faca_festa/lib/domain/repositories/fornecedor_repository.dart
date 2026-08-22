import '../../data/models/fornecedor/fornecedor_model.dart';

abstract interface class FornecedorRepository {
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario);

  Future<void> atualizarFornecedor(FornecedorModel fornecedor);

  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  });

  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  });

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  });
}
