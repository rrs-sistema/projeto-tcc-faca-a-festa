import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/evento/tema_festa_model.dart';
import '../../services/functions/callable_https_client.dart';

class TemaFestaRemoteDatasource {
  TemaFestaRemoteDatasource({
    FirebaseFirestore? firestore,
    CallableHttpsClient? httpsClient,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _https = httpsClient ?? CallableHttpsClient();

  final FirebaseFirestore _db;
  final CallableHttpsClient _https;

  Future<List<TemaFestaModel>> carregar() async {
    final snapshot = await _colecao.get();
    return snapshot.docs
        .map((doc) => TemaFestaModel.fromMap(doc.data(), id: doc.id))
        .toList()
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
  }

  Future<TemaFestaModel?> buscarPorId(String idTema) async {
    final doc = await _colecao.doc(idTema).get();
    if (!doc.exists || doc.data() == null) return null;
    return TemaFestaModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<void> salvar(TemaFestaModel tema) {
    return _colecao.doc(tema.idTema).set(tema.toMap(), SetOptions(merge: true));
  }

  Future<void> excluir(String idTema) {
    return _colecao.doc(idTema).delete();
  }

  Future<String?> enviarCapa({
    required String idTema,
    required List<int> bytes,
  }) async {
    final resultado = await _https.call(
      'enviarCapaTemaFesta',
      {
        'idTema': idTema,
        'bytesBase64': base64Encode(bytes),
      },
      const Duration(seconds: 60),
    );

    final url = resultado['url']?.toString().trim() ?? '';
    return url.isEmpty ? null : url;
  }

  Future<void> removerCapaStorage({required String idTema}) {
    return _https.call('removerCapaTemaFesta', {'idTema': idTema});
  }

  Future<void> popularTemasIniciais({
    required List<TemaFestaModel> temasIniciais,
    required List<TemaFestaModel> temasExistentes,
  }) async {
    final batch = _db.batch();
    for (final tema in temasIniciais) {
      final existente = temasExistentes
          .firstWhereOrNull((item) => item.idTema == tema.idTema);
      final mapa = Map<String, dynamic>.from(tema.toMap());
      final capaAtual = (existente?.imagemCapaUrl ?? '').trim();
      if (capaAtual.isNotEmpty) {
        mapa['imagem_capa_url'] = capaAtual;
      }
      batch.set(_colecao.doc(tema.idTema), mapa, SetOptions(merge: true));
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> get _colecao {
    return _db.collection(TemaFestaModel.colecao);
  }
}
