import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/models/orcamento/orcamento_gasto_model.dart';

class OrcamentoGastoController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxList<OrcamentoGastoModel> gastos = <OrcamentoGastoModel>[].obs;

  /// Calcula o total pago e restante
  double get totalPago => gastos.fold(0, (soma, g) => soma + (g.pago));
  double get totalGasto => gastos.fold(0, (soma, g) => soma + (g.custo));

  /// Escuta os gastos de um orçamento específico
  void escutarGastos(String idOrcamento) {
    _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto')
        .orderBy('data_cadastro', descending: true)
        .snapshots()
        .listen((snapshot) {
      gastos
          .assignAll(snapshot.docs.map((doc) => OrcamentoGastoModel.fromMap(doc.data())).toList());
    });
  }

  /// Adiciona um novo gasto
  Future<void> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) async {
    final idGasto = const Uuid().v4();

    final model = OrcamentoGastoModel(
      idGasto: idGasto,
      idOrcamento: idOrcamento,
      nome: nome,
      custo: custo,
      pago: pago,
    );

    await _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto')
        .doc(idGasto)
        .set(model.toMap());
  }

  /// Atualiza um gasto existente
  Future<void> atualizarGasto({
    required String idOrcamento,
    required String idGasto,
    required double pago,
  }) async {
    await _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto')
        .doc(idGasto)
        .update({'pago': pago});
  }

  /// Remove um gasto
  Future<void> removerGasto(String idOrcamento, String idGasto) async {
    await _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto')
        .doc(idGasto)
        .delete();
  }
}
