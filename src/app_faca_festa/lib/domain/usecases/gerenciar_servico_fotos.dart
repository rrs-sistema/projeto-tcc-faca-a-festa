import '../entities/servico_foto.dart';
import '../repositories/servico_foto_repository.dart';

class GerenciarServicoFotos {
  GerenciarServicoFotos(this.repository);

  final ServicoFotoRepository repository;

  Future<List<ServicoFoto>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  }) {
    return repository.carregarFotos(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
    );
  }

  Future<ServicoFoto> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required List<int> bytes,
    required String nomeArquivo,
  }) {
    return repository.adicionarFotoArquivo(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
      bytes: bytes,
      nomeArquivo: nomeArquivo,
    );
  }

  Future<void> adicionarFotoDireto(ServicoFoto foto) {
    return repository.adicionarFotoDireto(foto);
  }

  Future<void> removerFoto(ServicoFoto foto) {
    return repository.removerFoto(foto);
  }
}
