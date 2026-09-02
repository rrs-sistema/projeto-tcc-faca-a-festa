import 'dart:io';
import 'dart:typed_data';

import '../../data/models/evento/inspiracao_model.dart';
import '../../data/models/evento/inspiracao_snapshot_item.dart';
import '../../data/models/fornecedor/fornecedor_model.dart';
import '../repositories/inspiracao_repository.dart';

class GerenciarInspiracoes {
  GerenciarInspiracoes(this.repository);

  static const subcolecaoTarefas = 'tarefas';
  static const subcolecaoOrcamento = 'orcamento';

  final InspiracaoRepository repository;

  Stream<List<InspiracaoSnapshotItem>> observarInspiracoes() {
    return repository.observarInspiracoes();
  }

  String criarIdInspiracao() => repository.criarIdInspiracao();

  Future<int> popularCatalogoInicial({
    required List<Map<String, dynamic>> itens,
    required String operador,
  }) {
    return repository.popularCatalogoInicial(
      itens: itens,
      operador: operador,
    );
  }

  Future<void> salvarInspiracaoAdmin({
    required String id,
    required Map<String, dynamic> payload,
    required String operador,
    required bool criar,
  }) {
    return repository.salvarInspiracaoAdmin(
      id: id,
      payload: payload,
      operador: operador,
      criar: criar,
    );
  }

  Future<void> atualizarCamposAdmin({
    required String id,
    required Map<String, dynamic> campos,
    required String operador,
  }) {
    return repository.atualizarCamposAdmin(
      id: id,
      campos: campos,
      operador: operador,
    );
  }

  Future<void> salvarUrlsAdmin({
    required String id,
    required String operador,
    String? imagemUrl,
    List<String>? galeriaUrls,
    required bool adicionarNaGaleria,
  }) {
    return repository.salvarUrlsAdmin(
      id: id,
      operador: operador,
      imagemUrl: imagemUrl,
      galeriaUrls: galeriaUrls,
      adicionarNaGaleria: adicionarNaGaleria,
    );
  }

  Future<void> removerImagemGaleriaAdmin({
    required String id,
    required String operador,
    required String url,
  }) {
    return repository.removerImagemGaleriaAdmin(
      id: id,
      operador: operador,
      url: url,
    );
  }

  Future<String> uploadImagemAdmin({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) {
    return repository.uploadImagemAdmin(
      path: path,
      bytes: bytes,
      contentType: contentType,
      customMetadata: customMetadata,
    );
  }

  Future<void> removerArquivoStoragePorPath(String path) {
    return repository.removerArquivoStoragePorPath(path);
  }

  Future<void> removerArquivoStoragePorUrl(String url) {
    return repository.removerArquivoStoragePorUrl(url);
  }

  Stream<List<ReferenciaEventoModel>> observarReferenciasEvento(
    String eventoId,
  ) {
    return repository.observarReferenciasEvento(eventoId);
  }

  Stream<List<Map<String, dynamic>>> observarTarefasEvento(String eventoId) {
    return repository.observarTarefasEvento(eventoId);
  }

  Stream<List<Map<String, dynamic>>> observarOrcamentoEvento(String eventoId) {
    return repository.observarOrcamentoEvento(eventoId);
  }

  Future<FornecedorModel?> buscarFornecedor(String idFornecedor) {
    return repository.buscarFornecedor(idFornecedor);
  }

  Future<void> salvarReferenciaInspiracao({
    required String eventoId,
    required String userId,
    required String referenciaId,
    required InspiracaoModel inspiracao,
    required bool favorito,
    required String status,
    required String prioridade,
    required String anotacao,
  }) {
    return repository.salvarReferenciaInspiracao(
      eventoId: eventoId,
      userId: userId,
      referenciaId: referenciaId,
      inspiracao: inspiracao,
      favorito: favorito,
      status: status,
      prioridade: prioridade,
      anotacao: anotacao,
    );
  }

  Future<bool> referenciaExiste({
    required String eventoId,
    required String referenciaId,
  }) {
    return repository.referenciaExiste(
      eventoId: eventoId,
      referenciaId: referenciaId,
    );
  }

  Future<void> atualizarFavoritoReferencia({
    required String eventoId,
    required String referenciaId,
    required bool favorito,
  }) {
    return repository.atualizarFavoritoReferencia(
      eventoId: eventoId,
      referenciaId: referenciaId,
      favorito: favorito,
    );
  }

  Future<void> adicionarReferenciaPessoal({
    required String eventoId,
    required String userId,
    required File imageFile,
  }) {
    return repository.adicionarReferenciaPessoal(
      eventoId: eventoId,
      userId: userId,
      imageFile: imageFile,
    );
  }

  Future<bool> existeDocumentoAtivoDaInspiracao({
    required String eventoId,
    required String subcolecao,
    required String inspiracaoId,
  }) {
    return repository.existeDocumentoAtivoDaInspiracao(
      eventoId: eventoId,
      subcolecao: subcolecao,
      inspiracaoId: inspiracaoId,
    );
  }

  Future<void> atualizarIndicadoresReferencia({
    required String eventoId,
    required String referenciaId,
    bool? checklistCriado,
    bool? orcamentoCriado,
  }) {
    return repository.atualizarIndicadoresReferencia(
      eventoId: eventoId,
      referenciaId: referenciaId,
      checklistCriado: checklistCriado,
      orcamentoCriado: orcamentoCriado,
    );
  }

  Future<void> criarChecklistDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<Map<String, dynamic>> tarefas,
  }) {
    return repository.criarChecklistDaInspiracao(
      eventoId: eventoId,
      userId: userId,
      inspiracao: inspiracao,
      tarefas: tarefas,
    );
  }

  Future<void> criarOrcamentoDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<Map<String, dynamic>> itens,
  }) {
    return repository.criarOrcamentoDaInspiracao(
      eventoId: eventoId,
      userId: userId,
      inspiracao: inspiracao,
      itens: itens,
    );
  }

  Future<void> atualizarReferenciaPlanejamento({
    required String eventoId,
    required String referenciaId,
    String? status,
    String? prioridade,
    String? anotacao,
    bool? favorito,
  }) {
    return repository.atualizarReferenciaPlanejamento(
      eventoId: eventoId,
      referenciaId: referenciaId,
      status: status,
      prioridade: prioridade,
      anotacao: anotacao,
      favorito: favorito,
    );
  }

  Future<String?> buscarInspiracaoIdDaReferencia({
    required String eventoId,
    required String referenciaId,
  }) {
    return repository.buscarInspiracaoIdDaReferencia(
      eventoId: eventoId,
      referenciaId: referenciaId,
    );
  }

  Future<void> removerReferenciaDoEvento({
    required String eventoId,
    required String userId,
    required String referenciaId,
    required bool removerPlanejamentoVinculado,
    required String motivo,
  }) {
    return repository.removerReferenciaDoEvento(
      eventoId: eventoId,
      userId: userId,
      referenciaId: referenciaId,
      removerPlanejamentoVinculado: removerPlanejamentoVinculado,
      motivo: motivo,
    );
  }
}
