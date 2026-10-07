import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../models/orcamento/orcamento_gasto_model.dart';
import 'package:app_faca_festa/domain/entities/orcamento_validacao_resultado.dart';
import 'package:app_faca_festa/domain/services/validar_limite_gasto.dart';

class OrcamentoGastoRemoteDatasource {
  OrcamentoGastoRemoteDatasource({
    required FirebaseFirestore firestore,
    Uuid? uuid,
  })  : _db = firestore,
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
    final double limiteCategoria = _comoDouble(data['custo_estimado']);
    final String idEvento = data['id_evento'];

    final gastosSnap = await refOrcamento.collection('orcamento_gasto').get();
    final totalPagoCategoria = gastosSnap.docs.fold<double>(
      0,
      (soma, doc) => soma + _comoDouble(doc.data()['pago']),
    );

    final eventoSnap = await _db.collection('evento').doc(idEvento).get();
    final double limiteEvento =
        _comoDouble(eventoSnap.data()?['custo_estimado']);

    var totalPagoEvento = 0.0;
    final orcs = await _db
        .collection('orcamento')
        .where('id_evento', isEqualTo: idEvento)
        .get();

    for (final doc in orcs.docs) {
      final gastosCat = await doc.reference.collection('orcamento_gasto').get();
      for (final gasto in gastosCat.docs) {
        totalPagoEvento += _comoDouble(gasto.data()['pago']);
      }
    }

    final limite = ValidarLimiteGasto.avaliar(
      custo: custo,
      pago: pago,
      limiteCategoria: limiteCategoria,
      totalPagoCategoria: totalPagoCategoria,
      limiteEvento: limiteEvento,
      totalPagoEvento: totalPagoEvento,
    );
    if (limite != null) return limite;

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

  double _comoDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  CollectionReference<Map<String, dynamic>> _gastosRef(String idOrcamento) {
    return _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto');
  }
}
