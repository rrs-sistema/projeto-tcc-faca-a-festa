import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/orcamento/orcamento_model.dart';

class OrcamentoRemoteDatasource {
  OrcamentoRemoteDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<OrcamentoModel>> observarOrcamentosDoEvento(String idEvento) {
    return _db
        .collection('orcamento')
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrcamentoModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Stream<List<OrcamentoModel>> observarOrcamentosDoFornecedor(
    String idFornecedor,
  ) {
    return _db
        .collection('orcamento')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrcamentoModel.fromMap(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Future<void> criarOrcamento(OrcamentoModel model) {
    return _db
        .collection('orcamento')
        .doc(model.idOrcamento)
        .set(model.toMap());
  }

  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    required bool fechar,
  }) {
    final status = fechar ? 'fechado' : 'em_negociacao';

    return _db.collection('orcamento').doc(idOrcamento).update({
      'custo_estimado': custoEstimado,
      'anotacoes': anotacoes,
      'status': status,
      'orcamento_fechado': fechar,
      if (fechar) 'data_fechamento': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluirOrcamento(String idOrcamento) {
    return _db.collection('orcamento').doc(idOrcamento).delete();
  }
}
