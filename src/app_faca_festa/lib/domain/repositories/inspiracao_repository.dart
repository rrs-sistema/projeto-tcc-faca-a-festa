import 'dart:typed_data';

import '../entities/fornecedor.dart';
import '../entities/inspiracao.dart';
import '../entities/inspiracao_evento_planejamento.dart';
import '../entities/inspiracao_sugestao.dart';
import '../entities/referencia_evento.dart';

abstract interface class InspiracaoRepository {
  Stream<List<Inspiracao>> observarInspiracoes();

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

  Stream<List<ReferenciaEvento>> observarReferenciasEvento(
    String eventoId,
  );

  Stream<List<TarefaInspiracaoEvento>> observarTarefasEvento(String eventoId);

  Stream<List<ItemOrcamentoInspiracaoEvento>> observarOrcamentoEvento(
    String eventoId,
  );

  Future<Fornecedor?> buscarFornecedor(String idFornecedor);

  Future<void> salvarReferenciaInspiracao({
    required String eventoId,
    required String userId,
    required String referenciaId,
    required Inspiracao inspiracao,
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
    required List<int> bytes,
    required String nomeArquivo,
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
    required Inspiracao inspiracao,
    required List<TarefaInspiracaoSugerida> tarefas,
  });

  Future<void> criarOrcamentoDaInspiracao({
    required String eventoId,
    required String userId,
    required Inspiracao inspiracao,
    required List<ItemOrcamentoInspiracaoSugerido> itens,
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
