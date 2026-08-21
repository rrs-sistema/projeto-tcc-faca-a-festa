import 'dart:io';

import '../../data/models/servico_produto/servico_foto_model.dart';

abstract class ServicoFotoRepository {
  Future<List<ServicoFotoModel>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  });

  Future<ServicoFotoModel> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required File arquivo,
    required String nomeArquivo,
  });

  Future<void> adicionarFotoDireto(ServicoFotoModel foto);

  Future<void> removerFoto(ServicoFotoModel foto);
}
