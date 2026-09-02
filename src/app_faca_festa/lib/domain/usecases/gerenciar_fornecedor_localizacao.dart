import '../../data/models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../../data/models/fornecedor/fornecedor_model.dart';
import '../../data/models/servico_produto/categoria_servico_model.dart';
import '../../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../../data/models/fornecedor/territorio_model.dart';
import '../repositories/fornecedor_localizacao_repository.dart';

class GerenciarFornecedorLocalizacao {
  GerenciarFornecedorLocalizacao(this.repository);

  final FornecedorLocalizacaoRepository repository;

  Stream<List<CategoriaServicoModel>> observarCategoriasAtivas() {
    return repository.observarCategoriasAtivas();
  }

  Stream<List<FornecedorModel>> observarFornecedoresAtivos() {
    return repository.observarFornecedoresAtivos();
  }

  Stream<List<TerritorioModel>> observarTerritoriosAtivos() {
    return repository.observarTerritoriosAtivos();
  }

  Stream<List<FornecedorCategoriaModel>> observarCategoriasFornecedor() {
    return repository.observarCategoriasFornecedor();
  }

  Stream<Map<String, double>> observarMediasAvaliacoes() {
    return repository.observarMediasAvaliacoes();
  }

  Stream<List<FornecedorServicoDetalhadoDto>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    return repository.observarServicosFornecedor(idFornecedor);
  }

  Stream<List<FornecedorServicoDetalhadoDto>> observarTodosServicos() {
    return repository.observarTodosServicos();
  }

  Future<List<FornecedorServicoDetalhadoDto>> listarTodosServicosDoFornecedor(
    String idFornecedor,
  ) {
    return repository.listarTodosServicosDoFornecedor(idFornecedor);
  }

  Future<List<FornecedorServicoDetalhadoDto>> listarServicosPorCategoria(
    String idCategoria,
  ) {
    return repository.listarServicosPorCategoria(idCategoria);
  }

  Future<List<FornecedorServicoDetalhadoDto>> listarFornecedoresSemCategoria() {
    return repository.listarFornecedoresSemCategoria();
  }
}
