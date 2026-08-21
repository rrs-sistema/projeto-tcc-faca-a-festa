import 'dart:io';

import '../../data/models/servico_produto/servico_foto_model.dart';
import '../repositories/servico_foto_repository.dart';

class GerenciarServicoFotos {
  GerenciarServicoFotos(this.repository);

  final ServicoFotoRepository repository;

  Future<List<ServicoFotoModel>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  }) {
    return repository.carregarFotos(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
    );
  }

  Future<ServicoFotoModel> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required File arquivo,
    required String nomeArquivo,
  }) {
    return repository.adicionarFotoArquivo(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
      arquivo: arquivo,
      nomeArquivo: nomeArquivo,
    );
  }

  Future<void> adicionarFotoDireto(ServicoFotoModel foto) {
    return repository.adicionarFotoDireto(foto);
  }

  Future<void> removerFoto(ServicoFotoModel foto) {
    return repository.removerFoto(foto);
  }
}
