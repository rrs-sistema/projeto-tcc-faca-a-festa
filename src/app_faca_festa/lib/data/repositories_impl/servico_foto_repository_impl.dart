import 'dart:io';

import '../../domain/repositories/servico_foto_repository.dart';
import '../datasources/remote/servico_foto_remote_datasource.dart';
import '../models/servico_produto/servico_foto_model.dart';

class ServicoFotoRepositoryImpl implements ServicoFotoRepository {
  ServicoFotoRepositoryImpl(this.remote);

  final ServicoFotoRemoteDatasource remote;

  @override
  Future<List<ServicoFotoModel>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  }) {
    return remote.carregarFotos(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
    );
  }

  @override
  Future<ServicoFotoModel> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required File arquivo,
    required String nomeArquivo,
  }) {
    return remote.adicionarFotoArquivo(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
      arquivo: arquivo,
      nomeArquivo: nomeArquivo,
    );
  }

  @override
  Future<void> adicionarFotoDireto(ServicoFotoModel foto) {
    return remote.adicionarFotoDireto(foto);
  }

  @override
  Future<void> removerFoto(ServicoFotoModel foto) {
    return remote.removerFoto(foto);
  }
}
