import 'dart:io';
import 'dart:typed_data';

import '../../domain/repositories/inspiracao_repository.dart';
import '../datasources/remote/inspiracao_remote_datasource.dart';
import '../models/evento/inspiracao_model.dart';
import '../models/evento/inspiracao_snapshot_item.dart';
import '../models/fornecedor/fornecedor_model.dart';

class InspiracaoRepositoryImpl implements InspiracaoRepository {
  InspiracaoRepositoryImpl(this.remote);

  final InspiracaoRemoteDatasource remote;

  @override
  Stream<List<InspiracaoSnapshotItem>> observarInspiracoes() {
    return remote.observarInspiracoes();
  }

  @override
  String criarIdInspiracao() => remote.criarIdInspiracao();

  @override
  Future<int> popularCatalogoInicial({
    required List<Map<String, dynamic>> itens,
    required String operador,
  }) {
    return remote.popularCatalogoInicial(itens: itens, operador: operador);
  }

  @override
  Future<void> salvarInspiracaoAdmin({
    required String id,
    required Map<String, dynamic> payload,
    required String operador,
    required bool criar,
  }) {
    return remote.salvarInspiracaoAdmin(
      id: id,
      payload: payload,
      operador: operador,
      criar: criar,
    );
  }

  @override
  Future<void> atualizarCamposAdmin({
    required String id,
    required Map<String, dynamic> campos,
    required String operador,
  }) {
    return remote.atualizarCamposAdmin(
      id: id,
      campos: campos,
      operador: operador,
    );
  }

  @override
  Future<void> salvarUrlsAdmin({
    required String id,
    required String operador,
    String? imagemUrl,
    List<String>? galeriaUrls,
    required bool adicionarNaGaleria,
  }) {
    return remote.salvarUrlsAdmin(
      id: id,
      operador: operador,
      imagemUrl: imagemUrl,
      galeriaUrls: galeriaUrls,
      adicionarNaGaleria: adicionarNaGaleria,
    );
  }

  @override
  Future<void> removerImagemGaleriaAdmin({
    required String id,
    required String operador,
    required String url,
  }) {
    return remote.removerImagemGaleriaAdmin(
      id: id,
      operador: operador,
      url: url,
    );
  }

  @override
  Future<String> uploadImagemAdmin({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) {
    return remote.uploadImagemAdmin(
      path: path,
      bytes: bytes,
      contentType: contentType,
      customMetadata: customMetadata,
    );
  }

  @override
  Future<void> removerArquivoStoragePorPath(String path) {
    return remote.removerArquivoStoragePorPath(path);
  }

  @override
  Future<void> removerArquivoStoragePorUrl(String url) {
    return remote.removerArquivoStoragePorUrl(url);
  }

  @override
  Stream<List<ReferenciaEventoModel>> observarReferenciasEvento(
    String eventoId,
  ) {
    return remote.observarReferenciasEvento(eventoId);
  }

  @override
  Stream<List<Map<String, dynamic>>> observarTarefasEvento(String eventoId) {
    return remote.observarTarefasEvento(eventoId);
  }

  @override
  Stream<List<Map<String, dynamic>>> observarOrcamentoEvento(String eventoId) {
    return remote.observarOrcamentoEvento(eventoId);
  }

  @override
  Future<FornecedorModel?> buscarFornecedor(String idFornecedor) {
    return remote.buscarFornecedor(idFornecedor);
  }

  @override
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
    return remote.salvarReferenciaInspiracao(
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

  @override
  Future<bool> referenciaExiste({
    required String eventoId,
    required String referenciaId,
  }) {
    return remote.referenciaExiste(
      eventoId: eventoId,
      referenciaId: referenciaId,
    );
  }

  @override
  Future<void> atualizarFavoritoReferencia({
    required String eventoId,
    required String referenciaId,
    required bool favorito,
  }) {
    return remote.atualizarFavoritoReferencia(
      eventoId: eventoId,
      referenciaId: referenciaId,
      favorito: favorito,
    );
  }

  @override
  Future<void> adicionarReferenciaPessoal({
    required String eventoId,
    required String userId,
    required File imageFile,
  }) {
    return remote.adicionarReferenciaPessoal(
      eventoId: eventoId,
      userId: userId,
      imageFile: imageFile,
    );
  }

  @override
  Future<bool> existeDocumentoAtivoDaInspiracao({
    required String eventoId,
    required String subcolecao,
    required String inspiracaoId,
  }) {
    return remote.existeDocumentoAtivoDaInspiracao(
      eventoId: eventoId,
      subcolecao: subcolecao,
      inspiracaoId: inspiracaoId,
    );
  }

  @override
  Future<void> atualizarIndicadoresReferencia({
    required String eventoId,
    required String referenciaId,
    bool? checklistCriado,
    bool? orcamentoCriado,
  }) {
    return remote.atualizarIndicadoresReferencia(
      eventoId: eventoId,
      referenciaId: referenciaId,
      checklistCriado: checklistCriado,
      orcamentoCriado: orcamentoCriado,
    );
  }

  @override
  Future<void> criarChecklistDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<Map<String, dynamic>> tarefas,
  }) {
    return remote.criarChecklistDaInspiracao(
      eventoId: eventoId,
      userId: userId,
      inspiracao: inspiracao,
      tarefas: tarefas,
    );
  }

  @override
  Future<void> criarOrcamentoDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<Map<String, dynamic>> itens,
  }) {
    return remote.criarOrcamentoDaInspiracao(
      eventoId: eventoId,
      userId: userId,
      inspiracao: inspiracao,
      itens: itens,
    );
  }

  @override
  Future<void> atualizarReferenciaPlanejamento({
    required String eventoId,
    required String referenciaId,
    String? status,
    String? prioridade,
    String? anotacao,
    bool? favorito,
  }) {
    return remote.atualizarReferenciaPlanejamento(
      eventoId: eventoId,
      referenciaId: referenciaId,
      status: status,
      prioridade: prioridade,
      anotacao: anotacao,
      favorito: favorito,
    );
  }

  @override
  Future<String?> buscarInspiracaoIdDaReferencia({
    required String eventoId,
    required String referenciaId,
  }) {
    return remote.buscarInspiracaoIdDaReferencia(
      eventoId: eventoId,
      referenciaId: referenciaId,
    );
  }

  @override
  Future<void> removerReferenciaDoEvento({
    required String eventoId,
    required String userId,
    required String referenciaId,
    required bool removerPlanejamentoVinculado,
    required String motivo,
  }) {
    return remote.removerReferenciaDoEvento(
      eventoId: eventoId,
      userId: userId,
      referenciaId: referenciaId,
      removerPlanejamentoVinculado: removerPlanejamentoVinculado,
      motivo: motivo,
    );
  }
}
