import '../entities/evento.dart';
import '../entities/fornecedor.dart';
import '../entities/fornecedor_admin_snapshot.dart';
import '../entities/fornecedor_categoria.dart';
import '../entities/fornecedor_estatisticas.dart';
import '../entities/fornecedor_produto_servico.dart';

abstract interface class FornecedorRepository {
  Future<FornecedorAdminSnapshot> carregarSnapshotAdmin({
    required bool incluirEnderecos,
  });

  Future<Fornecedor?> buscarPorUsuario(String idUsuario);

  Future<Fornecedor?> buscarPorIdUsuario(String idUsuario);

  Future<Evento?> buscarEventoPorId(String idEvento);

  Stream<Fornecedor?> observarFornecedorAtivo(String idFornecedor);

  Stream<int> observarMensagensNaoLidas(String idFornecedor);

  Stream<int> observarSolicitacoesPendentes(String idFornecedor);

  Stream<List<FornecedorProdutoServico>> observarServicosFornecedor(
    String idFornecedor,
  );

  Future<List<FornecedorProdutoServico>> listarServicosPorEvento(
    String idEvento,
  );

  Future<List<Fornecedor>> listarFornecedoresDoEvento(String idEvento);

  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  );

  Future<FornecedorEstatisticas> carregarEstatisticas(
    String idFornecedor,
  );

  Future<void> atualizarFornecedor(Fornecedor fornecedor);

  Future<void> salvarFornecedor(Fornecedor fornecedor);

  Future<void> salvarCategoriaFornecedor(FornecedorCategoria categoria);

  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  });

  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  });

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  });

  Future<String> uploadBanner({
    required List<int> bytes,
    required String nomeArquivo,
    required String uid,
  });

  Future<int> limparDuplicatasFornecedorCategoria();
}
