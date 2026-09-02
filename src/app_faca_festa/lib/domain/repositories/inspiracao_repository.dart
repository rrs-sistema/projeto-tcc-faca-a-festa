import 'dart:io';
import 'dart:typed_data';

import '../../data/models/evento/inspiracao_model.dart';
import '../../data/models/evento/inspiracao_snapshot_item.dart';
import '../../data/models/fornecedor/fornecedor_model.dart';

abstract interface class InspiracaoRepository {
  Stream<List<InspiracaoSnapshotItem>> observarInspiracoes();

  String criarIdInspiracao();

  Future<int> popularCatalogoInicial({
    required List<Map<String, dynamic>> itens,
    required String operador,
  });

  Future<void> salvarInspiracaoAdmin({
    required String id,
    required Map<String, dynamic> payload,
    required String operador,
    required bool criar,
  });

  Future<void> atualizarCamposAdmin({
    required String id,
    required Map<String, dynamic> campos,
    required String operador,
  });

  Future<void> salvarUrlsAdmin({
    required String id,
    required String operador,
    String? imagemUrl,
    List<String>? galeriaUrls,
    required bool adicionarNaGaleria,
  });

  Future<void> removerImagemGaleriaAdmin({
    required String id,
    required String operador,
    required String url,
  });

  Future<String> uploadImagemAdmin({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  });

  Future<void> removerArquivoStoragePorPath(String path);

  Future<void> removerArquivoStoragePorUrl(String url);

  Stream<List<ReferenciaEventoModel>> observarReferenciasEvento(
    String eventoId,
  );

  Stream<List<Map<String, dynamic>>> observarTarefasEvento(String eventoId);

  Stream<List<Map<String, dynamic>>> observarOrcamentoEvento(String eventoId);

  Future<FornecedorModel?> buscarFornecedor(String idFornecedor);

  Future<void> salvarReferenciaInspiracao({
    required String eventoId,
    required String userId,
    required String referenciaId,
    required InspiracaoModel inspiracao,
    required bool favorito,
    required String status,
    required String prioridade,
    required String anotacao,
  });

  Future<bool> referenciaExiste({
    required String eventoId,
    required String referenciaId,
  });

  Future<void> atualizarFavoritoReferencia({
    required String eventoId,
    required String referenciaId,
    required bool favorito,
  });

  Future<void> adicionarReferenciaPessoal({
    required String eventoId,
    required String userId,
    required File imageFile,
  });

  Future<bool> existeDocumentoAtivoDaInspiracao({
    required String eventoId,
    required String subcolecao,
    required String inspiracaoId,
  });

  Future<void> atualizarIndicadoresReferencia({
    required String eventoId,
    required String referenciaId,
    bool? checklistCriado,
    bool? orcamentoCriado,
  });

  Future<void> criarChecklistDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<Map<String, dynamic>> tarefas,
  });

  Future<void> criarOrcamentoDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<Map<String, dynamic>> itens,
  });

  Future<void> atualizarReferenciaPlanejamento({
    required String eventoId,
    required String referenciaId,
    String? status,
    String? prioridade,
    String? anotacao,
    bool? favorito,
  });

  Future<String?> buscarInspiracaoIdDaReferencia({
    required String eventoId,
    required String referenciaId,
  });

  Future<void> removerReferenciaDoEvento({
    required String eventoId,
    required String userId,
    required String referenciaId,
    required bool removerPlanejamentoVinculado,
    required String motivo,
  });
}
