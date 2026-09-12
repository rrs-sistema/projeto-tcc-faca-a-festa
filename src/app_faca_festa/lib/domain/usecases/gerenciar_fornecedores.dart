import '../entities/evento.dart';
import '../entities/fornecedor.dart';
import '../entities/fornecedor_admin_snapshot.dart';
import '../entities/fornecedor_categoria.dart';
import '../entities/fornecedor_estatisticas.dart';
import '../entities/fornecedor_produto_servico.dart';
import '../repositories/fornecedor_repository.dart';

class GerenciarFornecedores {
  GerenciarFornecedores(this.repository);

  final FornecedorRepository repository;

  Future<FornecedorAdminSnapshot> carregarSnapshotAdmin({
    required bool incluirEnderecos,
  }) {
    return repository.carregarSnapshotAdmin(
      incluirEnderecos: incluirEnderecos,
    );
  }

  Future<Fornecedor?> buscarPorUsuario(String idUsuario) {
    return repository.buscarPorUsuario(idUsuario);
  }

  Future<Fornecedor?> buscarPorIdUsuario(String idUsuario) {
    return repository.buscarPorIdUsuario(idUsuario);
  }

  Future<Evento?> buscarEventoPorId(String idEvento) {
    return repository.buscarEventoPorId(idEvento);
  }

  Stream<Fornecedor?> observarFornecedorAtivo(String idFornecedor) {
    return repository.observarFornecedorAtivo(idFornecedor);
  }

  Stream<int> observarMensagensNaoLidas(String idFornecedor) {
    return repository.observarMensagensNaoLidas(idFornecedor);
  }

  Stream<int> observarSolicitacoesPendentes(String idFornecedor) {
    return repository.observarSolicitacoesPendentes(idFornecedor);
  }

  Stream<List<FornecedorProdutoServico>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    return repository.observarServicosFornecedor(idFornecedor);
  }

  Future<List<FornecedorProdutoServico>> listarServicosPorEvento(
    String idEvento,
  ) {
    return repository.listarServicosPorEvento(idEvento);
  }

  Future<List<Fornecedor>> listarFornecedoresDoEvento(String idEvento) {
    return repository.listarFornecedoresDoEvento(idEvento);
  }

  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  ) {
    return repository.listarSolicitacoesPendentesDetalhadas(idFornecedor);
  }

  Future<FornecedorEstatisticas> carregarEstatisticas(
    String idFornecedor,
  ) {
    return repository.carregarEstatisticas(idFornecedor);
  }

  Future<void> atualizarFornecedor(Fornecedor fornecedor) {
    return repository.atualizarFornecedor(fornecedor);
  }

  Future<void> salvarFornecedor(Fornecedor fornecedor) {
    return repository.salvarFornecedor(fornecedor);
  }

  Future<void> salvarCategoriaFornecedor(FornecedorCategoria categoria) {
    return repository.salvarCategoriaFornecedor(categoria);
  }

  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  }) {
    return repository.atualizarStatusAtivo(
      idFornecedor: idFornecedor,
      ativo: ativo,
    );
  }

  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  }) {
    return repository.atualizarAptoParaOperar(
      idFornecedor: idFornecedor,
      apto: apto,
    );
  }

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  }) {
    return repository.atualizarFcmToken(
      idFornecedor: idFornecedor,
      token: token,
    );
  }

  Future<String> uploadBanner({
    required List<int> bytes,
    required String nomeArquivo,
    required String uid,
  }) {
    return repository.uploadBanner(
      bytes: bytes,
      nomeArquivo: nomeArquivo,
      uid: uid,
    );
  }

  Future<int> limparDuplicatasFornecedorCategoria() {
    return repository.limparDuplicatasFornecedorCategoria();
  }
}
