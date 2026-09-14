import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:app_faca_festa/domain/entities/inspiracao.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_admin_patch.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_sugestao.dart';

import '../../models/evento/inspiracao_evento_planejamento_model.dart';
import '../../models/evento/inspiracao_model.dart';
import '../../models/fornecedor/fornecedor_model.dart';
import '../../seeds/inspiracao_seed.dart';

class InspiracaoRemoteDatasource {
  InspiracaoRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _db = firestore,
        _storage = storage;

  static const _colecaoInspiracoes = 'inspiracoes';
  static const _colecaoEventos = 'evento';
  static const subReferencias = 'referencias';
  static const subTarefas = 'tarefas';
  static const subOrcamento = 'orcamento';

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  Stream<List<Inspiracao>> observarInspiracoes() {
    return _db.collection(_colecaoInspiracoes).snapshots().map((snapshot) {
      return snapshot.docs
          .map<Inspiracao>((doc) => InspiracaoModel.fromFirestore(doc))
          .toList();
    });
  }

  String criarIdInspiracao() {
    return _db.collection(_colecaoInspiracoes).doc().id;
  }

  Future<int> popularCatalogoInicial({required String operador}) async {
    final itens = CatalogoInspiracao.itens;
    final collection = _db.collection(_colecaoInspiracoes);
    final existentes = await collection.get();
    final idsExistentes = existentes.docs.map((d) => d.id).toSet();
    final agora = FieldValue.serverTimestamp();
    WriteBatch lote = _db.batch();
    var operacoes = 0;

    Future<void> commitSeCheio() async {
      if (operacoes >= 400) {
        await lote.commit();
        lote = _db.batch();
        operacoes = 0;
      }
    }

    for (final item in itens) {
      await commitSeCheio();
      if (item.id.isEmpty) continue;
      final payload = InspiracaoModel.fromEntity(item).toFirestore()
        ..remove('criadoEm')
        ..remove('atualizadoEm')
        ..['atualizadoEm'] = agora
        ..['atualizadoPor'] = operador
        ..['origem'] = 'catalogo_festas'
        ..['tipoEventoSlug'] = item.tipoEventoNormalizado
        ..['tipoEventoNome'] = item.tipoEvento;
      if (!idsExistentes.contains(item.id)) {
        payload['criadoEm'] = agora;
        payload['criadoPor'] = operador;
      } else {
        payload.remove('criadoEm');
        payload.remove('criadoPor');
      }
      lote.set(collection.doc(item.id), payload, SetOptions(merge: true));
      operacoes++;
    }

    if (operacoes > 0) {
      await lote.commit();
    }

    return itens.length;
  }

  Future<void> salvarInspiracaoAdmin({
    required Inspiracao inspiracao,
    required String operador,
    required bool criar,
  }) {
    final data = InspiracaoModel.fromEntity(inspiracao).toFirestore()
      ..remove('criadoEm')
      ..remove('atualizadoEm')
      ..['atualizadoPor'] = operador
      ..['atualizadoEm'] = FieldValue.serverTimestamp();
    if (criar) {
      data['criadoPor'] = operador;
      data['criadoEm'] = FieldValue.serverTimestamp();
    }
    return _db
        .collection(_colecaoInspiracoes)
        .doc(inspiracao.id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> atualizarCamposAdmin({
    required String id,
    required InspiracaoAdminPatch patch,
    required String operador,
  }) {
    return _db.collection(_colecaoInspiracoes).doc(id).set(
      {
        ..._patchAdminToMap(patch),
        'atualizadoPor': operador,
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> salvarUrlsAdmin({
    required String id,
    required String operador,
    String? imagemUrl,
    List<String>? galeriaUrls,
    required bool adicionarNaGaleria,
  }) {
    final data = <String, dynamic>{
      'atualizadoPor': operador,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
    final capa = imagemUrl?.trim();
    if (capa != null && capa.isNotEmpty) data['imagemUrl'] = capa;
    final galeria = (galeriaUrls ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (galeria.isNotEmpty) {
      data['galeriaUrls'] =
          adicionarNaGaleria ? FieldValue.arrayUnion(galeria) : galeria;
    }
    if (data.length <= 2) return Future<void>.value();
    return _db
        .collection(_colecaoInspiracoes)
        .doc(id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> removerImagemGaleriaAdmin({
    required String id,
    required String operador,
    required String url,
  }) {
    return _db.collection(_colecaoInspiracoes).doc(id).set(
      {
        'galeriaUrls': FieldValue.arrayRemove(<String>[url]),
        'atualizadoPor': operador,
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String> uploadImagemAdmin({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(
      contentType: contentType,
      customMetadata: customMetadata,
      cacheControl: 'public,max-age=3600',
    );
    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  Future<void> removerArquivoStoragePorPath(String path) {
    return _storage.ref().child(path).delete();
  }

  Future<void> removerArquivoStoragePorUrl(String url) {
    return _storage.refFromURL(url).delete();
  }

  Stream<List<ReferenciaEventoModel>> observarReferenciasEvento(
    String eventoId,
  ) {
    return _subcolecao(eventoId, subReferencias).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ReferenciaEventoModel.fromFirestore(doc))
          .toList();
    });
  }

  Stream<List<TarefaInspiracaoEventoModel>> observarTarefasEvento(
    String eventoId,
  ) {
    return _subcolecao(eventoId, subTarefas).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => TarefaInspiracaoEventoModel.fromMap(
              doc.data(),
              documentId: doc.id,
            ),
          )
          .toList();
    });
  }

  Stream<List<ItemOrcamentoInspiracaoEventoModel>> observarOrcamentoEvento(
    String eventoId,
  ) {
    return _subcolecao(eventoId, subOrcamento).snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => ItemOrcamentoInspiracaoEventoModel.fromMap(
              doc.data(),
              documentId: doc.id,
            ),
          )
          .toList();
    });
  }

  Future<FornecedorModel?> buscarFornecedor(String idFornecedor) async {
    final doc = await _db.collection('fornecedor').doc(idFornecedor).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return FornecedorModel.fromMap(data, documentId: doc.id);
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
    return _subcolecao(eventoId, subReferencias).doc(referenciaId).set(
          inspiracao.toReferenciaEventoMap(
            eventoId: eventoId,
            userId: userId,
            favorito: favorito,
            status: status,
            prioridade: prioridade,
            anotacao: anotacao,
            origem: 'inspiracao_app',
          ),
          SetOptions(merge: true),
        );
  }

  Future<bool> referenciaExiste({
    required String eventoId,
    required String referenciaId,
  }) async {
    final doc =
        await _subcolecao(eventoId, subReferencias).doc(referenciaId).get();
    return doc.exists;
  }

  Future<void> atualizarFavoritoReferencia({
    required String eventoId,
    required String referenciaId,
    required bool favorito,
  }) {
    return _subcolecao(eventoId, subReferencias).doc(referenciaId).set(
      {
        'favorito': favorito,
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> adicionarReferenciaPessoal({
    required String eventoId,
    required String userId,
    required List<int> bytes,
    required String nomeArquivo,
  }) async {
    final fileName = nomeArquivo.trim().isEmpty
        ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
        : nomeArquivo;
    final storageRef = _storage.ref().child(
          'eventos/$eventoId/referencias/$userId/$fileName',
        );
    await storageRef.putData(Uint8List.fromList(bytes));
    final url = await storageRef.getDownloadURL();

    final docRef = _subcolecao(eventoId, subReferencias).doc();
    await docRef.set({
      'id': docRef.id,
      'eventoId': eventoId,
      'idEvento': eventoId,
      'userId': userId,
      'idUsuario': userId,
      'inspiracaoId': '',
      'titulo': 'Minha referência pessoal',
      'descricao': '',
      'imagemUrl': url,
      'categoria': 'Pessoal',
      'categoriaId': 'pessoal',
      'tags': ['pessoal'],
      'galeriaUrls': <String>[],
      'paletaCores': <String>[],
      'favorito': false,
      'status': 'salva',
      'prioridade': 'media',
      'origem': 'galeria_usuario',
      'anotacao': '',
      'ativo': true,
      'deletado': false,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> existeDocumentoAtivoDaInspiracao({
    required String eventoId,
    required String subcolecao,
    required String inspiracaoId,
  }) async {
    final id = inspiracaoId.trim();
    if (id.isEmpty) return false;

    final snapshot = await _subcolecao(eventoId, subcolecao)
        .where('inspiracaoId', isEqualTo: id)
        .limit(20)
        .get();

    return snapshot.docs.any((doc) {
      final data = doc.data();
      final origem = (data['origem'] ?? '').toString().trim().toLowerCase();
      final ativo = data['ativo'] != false;
      final deletado = data['deletado'] == true || data['deleted'] == true;
      final origemValida = origem.isEmpty || origem.contains('inspiracao');
      return origemValida && ativo && !deletado;
    });
  }

  Future<void> atualizarIndicadoresReferencia({
    required String eventoId,
    required String referenciaId,
    bool? checklistCriado,
    bool? orcamentoCriado,
  }) {
    final dados = <String, dynamic>{
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
    if (checklistCriado != null) {
      dados['checklistCriado'] = checklistCriado;
      if (checklistCriado) {
        dados['checklistCriadoEm'] = FieldValue.serverTimestamp();
      }
    }
    if (orcamentoCriado != null) {
      dados['orcamentoCriado'] = orcamentoCriado;
      if (orcamentoCriado) {
        dados['orcamentoCriadoEm'] = FieldValue.serverTimestamp();
      }
    }
    return _subcolecao(eventoId, subReferencias)
        .doc(referenciaId)
        .set(dados, SetOptions(merge: true));
  }

  Future<void> criarChecklistDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<TarefaInspiracaoSugerida> tarefas,
  }) async {
    final batch = _db.batch();
    final collection = _subcolecao(eventoId, subTarefas);
    for (final tarefa in tarefas) {
      final docRef = collection.doc();
      final categoria = tarefa.categoria.isNotEmpty
          ? tarefa.categoria
          : (inspiracao.categoria ?? '');
      batch.set(docRef, {
        'id': docRef.id,
        'eventoId': eventoId,
        'idEvento': eventoId,
        'userId': userId,
        'idUsuario': userId,
        'nome': tarefa.titulo,
        'titulo': tarefa.titulo,
        'descricao': tarefa.descricao,
        'categoria': categoria,
        'statusConclusao': false,
        'concluida': false,
        'origem': 'inspiracao',
        'inspiracaoId': inspiracao.id,
        'referenciaImagemUrl': inspiracao.imagemUrl,
        'ativo': true,
        'deletado': false,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> criarOrcamentoDaInspiracao({
    required String eventoId,
    required String userId,
    required InspiracaoModel inspiracao,
    required List<ItemOrcamentoInspiracaoSugerido> itens,
  }) async {
    final batch = _db.batch();
    final collection = _subcolecao(eventoId, subOrcamento);
    for (final item in itens) {
      final docRef = collection.doc();
      final categoria = item.categoria.isNotEmpty
          ? item.categoria
          : (inspiracao.categoria ?? '');
      final nomeItem = item.item.isNotEmpty ? item.item : inspiracao.titulo;
      batch.set(docRef, {
        'id': docRef.id,
        'eventoId': eventoId,
        'idEvento': eventoId,
        'userId': userId,
        'idUsuario': userId,
        'categoria': categoria,
        'item': nomeItem,
        'descricao': item.descricao,
        'custoEstimado': item.custoEstimado,
        'custoReal': item.custoReal,
        'valorPago': 0.0,
        'formaPagamento': '',
        'statusPagamento': 'pendente',
        'pago': false,
        'origem': 'inspiracao',
        'inspiracaoId': inspiracao.id,
        'referenciaImagemUrl': inspiracao.imagemUrl,
        'ativo': true,
        'deletado': false,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> atualizarReferenciaPlanejamento({
    required String eventoId,
    required String referenciaId,
    String? status,
    String? prioridade,
    String? anotacao,
    bool? favorito,
  }) {
    final dados = <String, dynamic>{
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
    if (status != null) dados['status'] = status;
    if (prioridade != null) dados['prioridade'] = prioridade;
    if (anotacao != null) dados['anotacao'] = anotacao;
    if (favorito != null) dados['favorito'] = favorito;
    return _subcolecao(eventoId, subReferencias)
        .doc(referenciaId)
        .set(dados, SetOptions(merge: true));
  }

  Future<String?> buscarInspiracaoIdDaReferencia({
    required String eventoId,
    required String referenciaId,
  }) async {
    final snapshot =
        await _subcolecao(eventoId, subReferencias).doc(referenciaId).get();
    if (!snapshot.exists) return null;
    return (snapshot.data()?['inspiracaoId'] ?? '').toString().trim();
  }

  Future<void> removerReferenciaDoEvento({
    required String eventoId,
    required String userId,
    required String referenciaId,
    required bool removerPlanejamentoVinculado,
    required String motivo,
  }) async {
    final refDoc = _subcolecao(eventoId, subReferencias).doc(referenciaId);
    final snapshot = await refDoc.get();
    if (!snapshot.exists) {
      throw StateError('Referência não encontrada.');
    }
    final data = snapshot.data() ?? <String, dynamic>{};
    final inspiracaoId = (data['inspiracaoId'] ?? '').toString().trim();
    final batch = _db.batch();

    batch.set(
      refDoc,
      {
        'ativo': false,
        'deletado': true,
        'status': 'descartada',
        'motivoRemocao':
            motivo.trim().isEmpty ? 'removida_pelo_organizador' : motivo.trim(),
        'removidaEm': FieldValue.serverTimestamp(),
        'removidaPor': userId,
        'planejamentoMantido': !removerPlanejamentoVinculado,
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (removerPlanejamentoVinculado && inspiracaoId.isNotEmpty) {
      final tarefas = await _subcolecao(eventoId, subTarefas)
          .where('inspiracaoId', isEqualTo: inspiracaoId)
          .get();
      for (final tarefa in tarefas.docs) {
        batch.set(
          tarefa.reference,
          {
            'ativo': false,
            'deletado': true,
            'status': 'descartada',
            'motivoRemocao': 'referencia_removida',
            'removidaEm': FieldValue.serverTimestamp(),
            'removidaPor': userId,
            'atualizadoEm': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      final orcamentos = await _subcolecao(eventoId, subOrcamento)
          .where('inspiracaoId', isEqualTo: inspiracaoId)
          .get();
      for (final orcamento in orcamentos.docs) {
        batch.set(
          orcamento.reference,
          {
            'ativo': false,
            'deletado': true,
            'statusPagamento': 'descartado',
            'status': 'descartado',
            'motivoRemocao': 'referencia_removida',
            'removidoEm': FieldValue.serverTimestamp(),
            'removidoPor': userId,
            'atualizadoEm': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _subcolecao(
    String eventoId,
    String subcolecao,
  ) {
    return _db.collection(_colecaoEventos).doc(eventoId).collection(subcolecao);
  }

  Map<String, dynamic> _patchAdminToMap(InspiracaoAdminPatch patch) {
    return <String, dynamic>{
      if (patch.ativo != null) 'ativo': patch.ativo,
      if (patch.publicado != null) 'publicado': patch.publicado,
      if (patch.deletado != null) 'deletado': patch.deletado,
      if (patch.destaque != null) 'destaque': patch.destaque,
      if (patch.ordem != null) 'ordem': patch.ordem,
      if (patch.imagemUrl != null) 'imagemUrl': patch.imagemUrl,
    };
  }
}
