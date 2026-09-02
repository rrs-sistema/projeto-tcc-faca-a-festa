import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../models/fornecedor/fornecedor_recomendacao_model.dart';

class FornecedorRecomendacaoRemoteDatasource {
  FornecedorRecomendacaoRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _db = firestore,
        _functions = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<List<FornecedorRecomendacaoModel>> carregarRecomendacoesSalvas({
    required String idEvento,
    required String idUsuario,
    required int limite,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _colecao
          .where('id_evento', isEqualTo: idEvento)
          .where('id_usuario', isEqualTo: idUsuario)
          .orderBy('score', descending: true)
          .limit(limite)
          .get();
    } catch (e) {
      debugPrint(
        '⚠️ [FornecedorRecomendacao] Falha na consulta com orderBy. '
        'Tentando sem ordenação no servidor. Erro: $e',
      );

      snapshot = await _colecao
          .where('id_evento', isEqualTo: idEvento)
          .where('id_usuario', isEqualTo: idUsuario)
          .limit(limite)
          .get();
    }

    final lista = snapshot.docs
        .map(
          (doc) => FornecedorRecomendacaoModel.fromMap(
            doc.data(),
            documentId: doc.id,
          ),
        )
        .toList();

    lista.sort((a, b) => b.score.compareTo(a.score));

    return lista;
  }

  Future<List<FornecedorRecomendacaoModel>> gerarRecomendacoes({
    required String idEvento,
    required int limite,
    required bool modoDemo,
  }) async {
    final callable = _functions.httpsCallable(
      'recomendarFornecedoresParaEvento',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 60),
      ),
    );

    final result = await callable.call({
      'idEvento': idEvento,
      'limite': limite,
      'modoDemo': modoDemo,
    });

    final data = Map<String, dynamic>.from(result.data as Map);
    final listaRaw = data['recomendacoes'] as List? ?? const [];

    return listaRaw
        .map(
          (item) => FornecedorRecomendacaoModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> registrarInteracao({
    required String idEvento,
    required String idFornecedor,
    required String acao,
    String? tipoEventoId,
    String? tipoEventoNome,
    String? cidade,
  }) async {
    final callable = _functions.httpsCallable(
      'registrarInteracaoFornecedor',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 30),
      ),
    );

    await callable.call({
      'idEvento': idEvento,
      'idFornecedor': idFornecedor,
      'acao': acao,
      'tipoEventoId': tipoEventoId,
      'tipoEventoNome': tipoEventoNome,
      'cidade': cidade,
    });
  }

  CollectionReference<Map<String, dynamic>> get _colecao {
    return _db.collection('fornecedor_recomendacoes');
  }
}
