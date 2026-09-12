import '../entities/categoria_servico.dart';
import '../entities/fornecedor.dart';
import '../entities/fornecedor_categoria.dart';
import '../entities/fornecedor_servico_detalhado.dart';
import '../entities/territorio.dart';

abstract interface class FornecedorLocalizacaoRepository {
  Stream<List<CategoriaServico>> observarCategoriasAtivas();

  Stream<List<Fornecedor>> observarFornecedoresAtivos();

  Stream<List<Territorio>> observarTerritoriosAtivos();

  Stream<List<FornecedorCategoria>> observarCategoriasFornecedor();

  Stream<Map<String, double>> observarMediasAvaliacoes();

  Stream<List<FornecedorServicoDetalhado>> observarServicosFornecedor(
    String idFornecedor,
  );

  Stream<List<FornecedorServicoDetalhado>> observarTodosServicos();

  Future<List<FornecedorServicoDetalhado>> listarTodosServicosDoFornecedor(
    String idFornecedor,
  );

  Future<List<FornecedorServicoDetalhado>> listarServicosPorCategoria(
    String idCategoria,
  );

  Future<List<FornecedorServicoDetalhado>> listarFornecedoresSemCategoria();
}
