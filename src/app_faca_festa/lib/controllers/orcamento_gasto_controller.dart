import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/models/model.dart';
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

    final refOrcamento = _db.collection('orcamento').doc(idOrcamento);
    final refGasto = refOrcamento.collection('orcamento_gasto').doc(idGasto);

    // 🔹 1. Adiciona o gasto
    await refGasto.set(model.toMap());

    // 🔹 2. Recarrega todos os gastos do orçamento
    final snapshot = await refOrcamento.collection('orcamento_gasto').get();

    final todosGastos = snapshot.docs.map((d) => OrcamentoGastoModel.fromMap(d.data())).toList();

    // 🔹 3. Verifica se todos os gastos estão totalmente pagos
    final todosPagos =
        todosGastos.isNotEmpty && todosGastos.every((g) => (g.pago >= g.custo && g.custo > 0));

    // 🔹 4. Atualiza o status do orçamento se estiver tudo pago
    if (todosPagos) {
      await refOrcamento.update({
        'status': StatusOrcamento.fechado.firestoreValue,
      });
      Get.snackbar(
        'Orçamento fechado 🎉',
        'Todos os gastos foram pagos com sucesso!',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      // 🔸 Caso contrário, mantém o status em aberto/pendente
      await refOrcamento.update({'status': StatusOrcamento.pendente.firestoreValue});
    }
  }

  /// Atualiza um gasto existente
  Future<void> atualizarGasto01({
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
