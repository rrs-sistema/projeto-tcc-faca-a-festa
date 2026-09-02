import '../../domain/repositories/fornecedor_localizacao_repository.dart';
import '../datasources/remote/fornecedor_localizacao_remote_datasource.dart';
import '../models/DTO/fornecedor_servico_detalhado_dto.dart';
import '../models/fornecedor/fornecedor_model.dart';
import '../models/servico_produto/categoria_servico_model.dart';
import '../models/servico_produto/fornecedor_categoria_model.dart';
import '../models/fornecedor/territorio_model.dart';

class FornecedorLocalizacaoRepositoryImpl
    implements FornecedorLocalizacaoRepository {
  FornecedorLocalizacaoRepositoryImpl(this.remote);

  final FornecedorLocalizacaoRemoteDatasource remote;

  @override
  Stream<List<CategoriaServicoModel>> observarCategoriasAtivas() {
    return remote.observarCategoriasAtivas();
  }

  @override
  Stream<List<FornecedorModel>> observarFornecedoresAtivos() {
    return remote.observarFornecedoresAtivos();
  }

  @override
  Stream<List<TerritorioModel>> observarTerritoriosAtivos() {
    return remote.observarTerritoriosAtivos();
  }

  @override
  Stream<List<FornecedorCategoriaModel>> observarCategoriasFornecedor() {
    return remote.observarCategoriasFornecedor();
  }

  @override
  Stream<Map<String, double>> observarMediasAvaliacoes() {
    return remote.observarMediasAvaliacoes();
  }

  @override
  Stream<List<FornecedorServicoDetalhadoDto>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    return remote.observarServicosFornecedor(idFornecedor);
  }

  @override
  Stream<List<FornecedorServicoDetalhadoDto>> observarTodosServicos() {
    return remote.observarTodosServicos();
  }

  @override
  Future<List<FornecedorServicoDetalhadoDto>> listarTodosServicosDoFornecedor(
    String idFornecedor,
  ) {
    return remote.listarTodosServicosDoFornecedor(idFornecedor);
  }

  @override
  Future<List<FornecedorServicoDetalhadoDto>> listarServicosPorCategoria(
    String idCategoria,
  ) {
    return remote.listarServicosPorCategoria(idCategoria);
  }

  @override
  Future<List<FornecedorServicoDetalhadoDto>> listarFornecedoresSemCategoria() {
    return remote.listarFornecedoresSemCategoria();
  }
}
