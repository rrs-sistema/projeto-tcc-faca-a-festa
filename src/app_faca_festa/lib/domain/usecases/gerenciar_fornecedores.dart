import 'dart:io';
import 'dart:typed_data';

import '../../data/models/evento/evento_model.dart';
import '../../data/models/fornecedor/fornecedor_admin_snapshot.dart';
import '../../data/models/fornecedor/fornecedor_estatisticas_model.dart';
import '../../data/models/fornecedor/fornecedor_model.dart';
import '../../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../../data/models/servico_produto/fornecedor_produto_servico_model.dart';
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

  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) {
    return repository.buscarPorUsuario(idUsuario);
  }

  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario) {
    return repository.buscarPorIdUsuario(idUsuario);
  }

  Future<EventoModel?> buscarEventoPorId(String idEvento) {
    return repository.buscarEventoPorId(idEvento);
  }

  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor) {
    return repository.observarFornecedorAtivo(idFornecedor);
  }

  Stream<int> observarMensagensNaoLidas(String idFornecedor) {
    return repository.observarMensagensNaoLidas(idFornecedor);
  }

  Stream<int> observarSolicitacoesPendentes(String idFornecedor) {
    return repository.observarSolicitacoesPendentes(idFornecedor);
  }

  Stream<List<FornecedorProdutoServicoModel>> observarServicosFornecedor(
    String idFornecedor,
  ) {
    return repository.observarServicosFornecedor(idFornecedor);
  }

  Future<List<FornecedorProdutoServicoModel>> listarServicosPorEvento(
    String idEvento,
  ) {
    return repository.listarServicosPorEvento(idEvento);
  }

  Future<List<FornecedorModel>> listarFornecedoresDoEvento(String idEvento) {
    return repository.listarFornecedoresDoEvento(idEvento);
  }

  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentesDetalhadas(
    String idFornecedor,
  ) {
    return repository.listarSolicitacoesPendentesDetalhadas(idFornecedor);
  }

  Future<FornecedorEstatisticasModel> carregarEstatisticas(
    String idFornecedor,
  ) {
    return repository.carregarEstatisticas(idFornecedor);
  }

  Future<void> atualizarFornecedor(FornecedorModel fornecedor) {
    return repository.atualizarFornecedor(fornecedor);
  }

  Future<void> salvarFornecedor(FornecedorModel fornecedor) {
    return repository.salvarFornecedor(fornecedor);
  }

  Future<void> salvarCategoriaFornecedor(FornecedorCategoriaModel categoria) {
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
    required File imageFile,
    Uint8List? bytesWeb,
    required String uid,
  }) {
    return repository.uploadBanner(
      imageFile: imageFile,
      bytesWeb: bytesWeb,
      uid: uid,
    );
  }

  Future<int> limparDuplicatasFornecedorCategoria() {
    return repository.limparDuplicatasFornecedorCategoria();
  }
}
