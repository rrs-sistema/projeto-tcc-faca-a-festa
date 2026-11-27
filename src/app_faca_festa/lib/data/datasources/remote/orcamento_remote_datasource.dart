import 'compromissos_evento_remote.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/orcamento/orcamento_model.dart';
import 'package:app_faca_festa/core/conectividade/escrita_local_primeiro.dart';
import 'package:app_faca_festa/core/conectividade/exigir_conexao.dart';
import 'package:app_faca_festa/domain/entities/orcamento.dart';

class OrcamentoRemoteDatasource {
  OrcamentoRemoteDatasource({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _db = firestore,
        _auth = auth;

  Stream<List<Map<String, dynamic>>> observarFinanceiroEvento(String evento) =>
      CompromissosEventoRemote(_db).observarCompromissosDoEvento(evento);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<OrcamentoModel?> buscarPorId(String idOrcamento) async {
    final doc = await _db.collection('orcamento').doc(idOrcamento).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return OrcamentoModel.fromMap(data, docId: doc.id);
  }

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
    final dados = model.toMap();
    dados['id_solicitante'] ??= _auth.currentUser?.uid;

    return escritaLocalPrimeiro(
      _db
          .collection('orcamento')
          .doc(model.idOrcamento)
          .set(dados, SetOptions(merge: true)),
      descricao: 'item do orçamento',
      chave: model.idOrcamento,
    );
  }

  Future<void> confirmarReserva({
    required String idOrcamento,
    required double? custoEstimado,
    required String? anotacoes,
    required DateTime? dataReserva,
    required StatusOrcamento status,
  }) async {
    // Fecha negócio com o fornecedor: não pode ficar na fila do aparelho.
    garantirConexao('Confirmar a reserva com o fornecedor');
    return _db.collection('orcamento').doc(idOrcamento).update({
      'anotacoes': anotacoes,
      'custo_estimado': custoEstimado,
      'data_reserva':
          dataReserva != null ? Timestamp.fromDate(dataReserva) : null,
      'status': status.firestoreValue,
      'data_fechamento': FieldValue.serverTimestamp(),
    });
  }

  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    required bool fechar,
  }) async {
    final status = fechar ? 'fechado' : 'em_negociacao';
    garantirConexao('Responder o orçamento');

    return _db.collection('orcamento').doc(idOrcamento).update({
      'custo_estimado': custoEstimado,
      'anotacoes': anotacoes,
      'status': status,
      'orcamento_fechado': fechar,
      if (fechar) 'data_fechamento': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizarOrcamento({
    required String idOrcamento,
    required String anotacoes,
    required double custoEstimado,
  }) {
    return escritaLocalPrimeiro(
      _db.collection('orcamento').doc(idOrcamento).update({
        'anotacoes': anotacoes,
        'custo_estimado': custoEstimado,
      }),
      descricao: 'item do orçamento',
      chave: idOrcamento,
    );
  }

  Future<void> excluirOrcamento(String idOrcamento) {
    return escritaLocalPrimeiro(
      _db.collection('orcamento').doc(idOrcamento).delete(),
      descricao: 'exclusão de um item do orçamento',
      chave: idOrcamento,
    );
  }
}
