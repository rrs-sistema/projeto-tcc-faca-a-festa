import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

import './../data/models/orcamento/orcamento_validacao_resultado.dart';
import './../data/models/orcamento/orcamento_gasto_model.dart';

class OrcamentoGastoController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxList<OrcamentoGastoModel> gastos = <OrcamentoGastoModel>[].obs;

  /// Escuta os gastos de um orçamento específico
  void escutarGastos(String idOrcamento) {
    _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto')
        .orderBy('data_cadastro', descending: true)
        .snapshots()
        .listen((snapshot) {
      gastos.assignAll(
        snapshot.docs.map((doc) => OrcamentoGastoModel.fromMap(doc.data())).toList(),
      );
    });
  }

  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) async {
    final refOrcamento = _db.collection('orcamento').doc(idOrcamento);

    // =====================================================
    // 🔹 VALIDACÕES IMEDIATAS (antes de acessar o Firestore)
    // =====================================================

    // 1. Custo não pode ser menor ou igual a zero
    if (custo <= 0) {
      return OrcamentoValidacaoResultado.erro(
        "O custo do item deve ser maior que zero.",
      );
    }

    // 2. Pago não pode ser maior que custo
    if (pago > custo) {
      return OrcamentoValidacaoResultado.erro(
        "O valor pago não pode ser maior que o custo total do item.",
      );
    }

    // 3. Pago não pode ser negativo
    if (pago < 0) {
      return OrcamentoValidacaoResultado.erro(
        "O valor pago não pode ser negativo.",
      );
    }

    // =====================================================
    // 🔹 BUSCA ORÇAMENTO
    // =====================================================
    final orcamentoSnap = await refOrcamento.get();
    if (!orcamentoSnap.exists) {
      return OrcamentoValidacaoResultado.erro("Orçamento não encontrado.");
    }

    final data = orcamentoSnap.data()!;
    final double limiteCategoria = (data['custo_estimado'] ?? 0).toDouble();
    final String idEvento = data['id_evento'];

    // =====================================================
    // 🔹 SOMA GASTOS DA CATEGORIA
    // =====================================================
    final gastosSnap = await refOrcamento.collection('orcamento_gasto').get();
    final totalAtual = gastosSnap.docs.fold(0.0, (s, d) => s + (d.data()['custo'] ?? 0.0));

    if (totalAtual + custo > limiteCategoria) {
      final excedente = (totalAtual + custo) - limiteCategoria;

      return OrcamentoValidacaoResultado.excedeuCategoria(
        excedente: excedente,
        limite: limiteCategoria,
      );
    }

    // =====================================================
    // 🔹 VALIDA ORÇAMENTO GERAL DO EVENTO
    // =====================================================
    final eventoSnap = await _db.collection('evento').doc(idEvento).get();
    final double limiteEvento = (eventoSnap.data()?['custo_estimado'] ?? 0).toDouble();

    // total gasto no evento
    double totalEvento = 0;
    final orcs = await _db.collection('orcamento').where("id_evento", isEqualTo: idEvento).get();

    for (var doc in orcs.docs) {
      final gastosCat = await doc.reference.collection('orcamento_gasto').get();
      for (var g in gastosCat.docs) {
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

    // =====================================================
    // 🔹 SE PASSOU NAS VALIDAÇÕES → SALVAR
    // =====================================================
    final idGasto = const Uuid().v4();
    final model = OrcamentoGastoModel(
      idGasto: idGasto,
      idOrcamento: idOrcamento,
      nome: nome,
      custo: custo,
      pago: pago,
    );

    await refOrcamento.collection('orcamento_gasto').doc(idGasto).set(model.toMap());

    return OrcamentoValidacaoResultado.ok();
  }

  Future<void> removerGasto(String idOrcamento, String idGasto) async {
    await _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto')
        .doc(idGasto)
        .delete();
  }

  /// Totalizadores
  double get totalPago => gastos.fold(0.0, (soma, g) => soma + g.pago);
  double get totalGasto => gastos.fold(0.0, (soma, g) => soma + g.custo);
}
