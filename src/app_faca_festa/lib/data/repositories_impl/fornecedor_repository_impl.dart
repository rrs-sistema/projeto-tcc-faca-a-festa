import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_repository.dart';
import '../datasources/remote/fornecedor_remote_datasource.dart';
import '../models/cotacao/cotacao_model.dart';
import '../models/evento/evento_model.dart';
import '../models/fornecedor/fornecedor_admin_snapshot.dart';
import '../models/fornecedor/fornecedor_estatisticas_model.dart';
import '../models/fornecedor/fornecedor_model.dart';
import '../models/servico_produto/fornecedor_categoria_model.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_dados_cadastrais.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_cadastro_edicao.dart';

class FornecedorRepositoryImpl implements FornecedorRepository {
  FornecedorRepositoryImpl(this.remote);

  final FornecedorRemoteDatasource remote;

  @override
  Future<FornecedorCadastroEdicao> carregarCadastroEdicao(
          String idFornecedor) =>
      remote.carregarCadastroEdicao(idFornecedor);
  @override
  Future<void> salvarCadastroEdicao(FornecedorCadastroAlteracao alteracao) =>
      UpdateOperations.run(() => remote.salvarCadastroEdicao(alteracao));

  @override
  Future<FornecedorAdminSnapshot> carregarSnapshotAdmin({
    required bool incluirEnderecos,
  }) {
    return UpdateOperations.run(() async {
      return remote.carregarSnapshotAdmin(incluirEnderecos: incluirEnderecos);
    });
  }

  @override
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) {
    return UpdateOperations.run(() async {
      return remote.buscarPorUsuario(idUsuario);
    });
  }

  @override
  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario) {
    return UpdateOperations.run(() async {
      return remote.buscarPorIdUsuario(idUsuario);
    });
  }

  @override
  Future<EventoModel?> buscarEventoPorId(String idEvento) {
    return UpdateOperations.run(() async {
      return remote.buscarEventoPorId(idEvento);
    });
  }

  @override
  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor) {
    return remote.observarFornecedorAtivo(idFornecedor);
  }

  @override
  Stream<int> observarMensagensNaoLidas(String idFornecedor) {
    return remote.observarMensagensNaoLidas(idFornecedor);
  }

  @override
  Stream<int> observarSolicitacoesPendentes(String idFornecedor) {
    return remote.observarSolicitacoesPendentes(idFornecedor);
  }

  @override
  Stream<List<FornecedorProdutoServico>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    return remote.observarServicosFornecedor(idFornecedor);
  }

  @override
  Future<List<FornecedorProdutoServico>> listarServicosPorEvento(
    String idEvento,
  ) {
    return UpdateOperations.run(() async {
      return remote.listarServicosPorEvento(idEvento);
    });
  }

  @override
  Future<List<FornecedorModel>> listarFornecedoresDoEvento(String idEvento) {
    return UpdateOperations.run(() async {
      return remote.listarFornecedoresDoEvento(idEvento);
    });
  }

  @override
  Future<List<CotacaoModel>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  ) {
    return UpdateOperations.run(() async {
      return remote.listarSolicitacoesPendentesDetalhadas(idFornecedor);
    });
  }

  @override
  Future<FornecedorEstatisticasModel> carregarEstatisticas(
    String idFornecedor,
  ) {
    return UpdateOperations.run(() async {
      return remote.carregarEstatisticas(idFornecedor);
    });
  }

  @override
  Future<void> atualizarFornecedor(Fornecedor fornecedor) {
    return UpdateOperations.run(() async {
      return remote.atualizarFornecedor(FornecedorModel.fromEntity(fornecedor));
    });
  }

  @override
  Future<void> atualizarDadosCadastrais({
    required String idFornecedor,
    required FornecedorDadosCadastrais dados,
  }) =>
      UpdateOperations.run(() => remote.atualizarDadosCadastrais(
          idFornecedor: idFornecedor, dados: dados));

  @override
  Future<void> salvarFornecedor(Fornecedor fornecedor) {
    return UpdateOperations.run(() async {
      return remote.salvarFornecedor(FornecedorModel.fromEntity(fornecedor));
    });
  }

  @override
  Future<void> salvarCategoriaFornecedor(FornecedorCategoria categoria) {
    return UpdateOperations.run(() async {
      return remote.salvarCategoriaFornecedor(
        FornecedorCategoriaModel.fromEntity(categoria),
      );
    });
  }

  @override
  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  }) {
    return UpdateOperations.run(() async {
      return remote.atualizarStatusAtivo(
        idFornecedor: idFornecedor,
        ativo: ativo,
      );
    });
  }

  @override
  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  }) {
    return UpdateOperations.run(() async {
      return remote.atualizarAptoParaOperar(
        idFornecedor: idFornecedor,
        apto: apto,
      );
    });
  }

  @override
  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  }) {
    return UpdateOperations.run(() async {
      return remote.atualizarFcmToken(
        idFornecedor: idFornecedor,
        token: token,
      );
    });
  }

  @override
  Future<String> uploadBanner({
    required List<int> bytes,
    required String nomeArquivo,
    required String uid,
  }) {
    return UpdateOperations.run(() async {
      return remote.uploadBanner(
        bytes: bytes,
        nomeArquivo: nomeArquivo,
        uid: uid,
      );
    });
  }

  @override
  Future<int> limparDuplicatasFornecedorCategoria() {
    return UpdateOperations.run(() async {
      return remote.limparDuplicatasFornecedorCategoria();
    });
  }
}
