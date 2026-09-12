import '../entities/servico_foto.dart';

abstract class ServicoFotoRepository {
  Future<List<ServicoFoto>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  });

  Future<ServicoFoto> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required List<int> bytes,
    required String nomeArquivo,
  });

  Future<void> adicionarFotoDireto(ServicoFoto foto);

  Future<void> removerFoto(ServicoFoto foto);
}
