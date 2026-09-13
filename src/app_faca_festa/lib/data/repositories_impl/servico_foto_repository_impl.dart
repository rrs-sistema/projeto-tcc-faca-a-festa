import 'package:app_faca_festa/domain/entities/servico_foto.dart';
import 'package:app_faca_festa/domain/repositories/servico_foto_repository.dart';
import '../datasources/remote/servico_foto_remote_datasource.dart';
import '../models/servico_produto/servico_foto_model.dart';

class ServicoFotoRepositoryImpl implements ServicoFotoRepository {
  ServicoFotoRepositoryImpl(this.remote);

  final ServicoFotoRemoteDatasource remote;

  @override
  Future<List<ServicoFoto>> carregarFotos({
    required String idFornecedor,
    required String idProdutoServico,
  }) {
    return remote.carregarFotos(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
    );
  }

  @override
  Future<ServicoFoto> adicionarFotoArquivo({
    required String idFornecedor,
    required String idProdutoServico,
    required List<int> bytes,
    required String nomeArquivo,
  }) {
    return remote.adicionarFotoArquivo(
      idFornecedor: idFornecedor,
      idProdutoServico: idProdutoServico,
      bytes: bytes,
      nomeArquivo: nomeArquivo,
    );
  }

  @override
  Future<void> adicionarFotoDireto(ServicoFoto foto) {
    return remote.adicionarFotoDireto(ServicoFotoModel.fromEntity(foto));
  }

  @override
  Future<void> removerFoto(ServicoFoto foto) {
    return remote.removerFoto(ServicoFotoModel.fromEntity(foto));
  }
}
