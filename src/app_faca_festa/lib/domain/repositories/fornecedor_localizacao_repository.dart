import '../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../data/models/fornecedor/fornecedor_model.dart';
import '../../data/models/servico_produto/categoria_servico_model.dart';
import '../../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../../data/models/fornecedor/territorio_model.dart';

abstract interface class FornecedorLocalizacaoRepository {
  Stream<List<CategoriaServicoModel>> observarCategoriasAtivas();

  Stream<List<FornecedorModel>> observarFornecedoresAtivos();

  Stream<List<TerritorioModel>> observarTerritoriosAtivos();

  Stream<List<FornecedorCategoriaModel>> observarCategoriasFornecedor();

  Stream<Map<String, double>> observarMediasAvaliacoes();

  Stream<List<FornecedorServicoDetalhadoDto>> observarServicosFornecedor(
    String idFornecedor,
  );

  Stream<List<FornecedorServicoDetalhadoDto>> observarTodosServicos();

  Future<List<FornecedorServicoDetalhadoDto>> listarTodosServicosDoFornecedor(
    String idFornecedor,
  );

  Future<List<FornecedorServicoDetalhadoDto>> listarServicosPorCategoria(
    String idCategoria,
  );

  Future<List<FornecedorServicoDetalhadoDto>> listarFornecedoresSemCategoria();
}
