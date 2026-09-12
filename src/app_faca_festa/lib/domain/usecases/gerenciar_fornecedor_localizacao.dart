import '../entities/categoria_servico.dart';
import '../entities/fornecedor.dart';
import '../entities/fornecedor_categoria.dart';
import '../entities/fornecedor_servico_detalhado.dart';
import '../entities/territorio.dart';
import '../repositories/fornecedor_localizacao_repository.dart';

class GerenciarFornecedorLocalizacao {
  GerenciarFornecedorLocalizacao(this.repository);

  final FornecedorLocalizacaoRepository repository;

  Stream<List<CategoriaServico>> observarCategoriasAtivas() {
    return repository.observarCategoriasAtivas();
  }

  Stream<List<Fornecedor>> observarFornecedoresAtivos() {
    return repository.observarFornecedoresAtivos();
  }

  Stream<List<Territorio>> observarTerritoriosAtivos() {
    return repository.observarTerritoriosAtivos();
  }

  Stream<List<FornecedorCategoria>> observarCategoriasFornecedor() {
    return repository.observarCategoriasFornecedor();
  }

  Stream<Map<String, double>> observarMediasAvaliacoes() {
    return repository.observarMediasAvaliacoes();
  }

  Stream<List<FornecedorServicoDetalhado>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    return repository.observarServicosFornecedor(idFornecedor);
  }

  Stream<List<FornecedorServicoDetalhado>> observarTodosServicos() {
    return repository.observarTodosServicos();
  }

  Future<List<FornecedorServicoDetalhado>> listarTodosServicosDoFornecedor(
    String idFornecedor,
  ) {
    return repository.listarTodosServicosDoFornecedor(idFornecedor);
  }

  Future<List<FornecedorServicoDetalhado>> listarServicosPorCategoria(
    String idCategoria,
  ) {
    return repository.listarServicosPorCategoria(idCategoria);
  }

  Future<List<FornecedorServicoDetalhado>> listarFornecedoresSemCategoria() {
    return repository.listarFornecedoresSemCategoria();
  }
}
