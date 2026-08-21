import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../models/orcamento/orcamento_gasto_model.dart';
import '../../models/orcamento/orcamento_validacao_resultado.dart';

class OrcamentoGastoRemoteDatasource {
  OrcamentoGastoRemoteDatasource({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final Uuid _uuid;

  Stream<List<OrcamentoGastoModel>> observarGastos(String idOrcamento) {
    return _gastosRef(idOrcamento)
        .orderBy('data_cadastro', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrcamentoGastoModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) async {
    final refOrcamento = _db.collection('orcamento').doc(idOrcamento);

    if (custo <= 0) {
      return OrcamentoValidacaoResultado.erro(
        'O custo do item deve ser maior que zero.',
      );
    }

    if (pago > custo) {
      return OrcamentoValidacaoResultado.erro(
        'O valor pago não pode ser maior que o custo total do item.',
      );
    }

    if (pago < 0) {
      return OrcamentoValidacaoResultado.erro(
        'O valor pago não pode ser negativo.',
      );
    }

    final orcamentoSnap = await refOrcamento.get();
    if (!orcamentoSnap.exists) {
      return OrcamentoValidacaoResultado.erro('Orçamento não encontrado.');
    }

    final data = orcamentoSnap.data()!;
    final double limiteCategoria = (data['custo_estimado'] ?? 0).toDouble();
    final String idEvento = data['id_evento'];

    final gastosSnap = await refOrcamento.collection('orcamento_gasto').get();
    final totalAtual = gastosSnap.docs.fold(
      0.0,
      (s, d) => s + (d.data()['custo'] ?? 0.0),
    );

    if (totalAtual + custo > limiteCategoria) {
      final excedente = (totalAtual + custo) - limiteCategoria;

      return OrcamentoValidacaoResultado.excedeuCategoria(
        excedente: excedente,
        limite: limiteCategoria,
      );
    }

    final eventoSnap = await _db.collection('evento').doc(idEvento).get();
    final double limiteEvento =
        (eventoSnap.data()?['custo_estimado'] ?? 0).toDouble();

    double totalEvento = 0;
    final orcs = await _db
        .collection('orcamento')
        .where('id_evento', isEqualTo: idEvento)
        .get();

    for (final doc in orcs.docs) {
      final gastosCat = await doc.reference.collection('orcamento_gasto').get();
      for (final g in gastosCat.docs) {
        totalEvento += (g.data()['custo'] ?? 0).toDouble();
      }
    }

    if (totalEvento + custo > limiteEvento) {
      final excedente = (totalEvento + custo) - limiteEvento;

      return OrcamentoValidacaoResultado.excedeuEvento(
        excedente: excedente,
        limite: limiteEvento,
      );
    }

    final idGasto = _uuid.v4();
    final model = OrcamentoGastoModel(
      idGasto: idGasto,
      idOrcamento: idOrcamento,
      nome: nome,
      custo: custo,
      pago: pago,
    );

    await _gastosRef(idOrcamento).doc(idGasto).set(model.toMap());

    return OrcamentoValidacaoResultado.ok();
  }

  Future<void> marcarComoPago({
    required String idOrcamento,
    required String idGasto,
    required double valorTotal,
  }) {
    return _gastosRef(idOrcamento).doc(idGasto).update({
      'pago': valorTotal,
    });
  }

  Future<void> removerGasto({
    required String idOrcamento,
    required String idGasto,
  }) {
    return _gastosRef(idOrcamento).doc(idGasto).delete();
  }

  CollectionReference<Map<String, dynamic>> _gastosRef(String idOrcamento) {
    return _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto');
  }
}
