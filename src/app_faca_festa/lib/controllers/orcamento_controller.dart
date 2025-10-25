import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/model.dart';

class OrcamentoController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxList<OrcamentoModel> orcamentos = <OrcamentoModel>[].obs;

  RxBool carregando = false.obs;
  StreamSubscription? _orcamentoSubscription;
  final RxInt fornecedorContatadoCount = 0.obs;
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;
  final RxDouble totalCustoEstimado = 0.0.obs;

  Future<void> carregarOrcamentosDoEvento(String idEvento) async {
    try {
      await _orcamentoSubscription?.cancel();

      _orcamentoSubscription = _db
          .collection('orcamento')
          .where('id_evento', isEqualTo: idEvento)
          .snapshots()
          .listen((snapshot) async {
        final lista = snapshot.docs.map((d) => OrcamentoModel.fromMap(d.data())).toList();
        orcamentos.assignAll(lista);
        _atualizarContagens(); // ✅ sempre recalcula
      });
    } catch (e, s) {
      debugPrint('❌ Erro ao escutar orçamentos: $e\n$s');
    }
  }

  void _atualizarContagens() {
    fornecedorContatadoCount.value = orcamentos.where((o) => o.idServicoFornecido != null).length;
    contratadosCount.value = orcamentos.where((o) => o.status == StatusOrcamento.fechado).length;
    totalCustoEstimado.value = orcamentos.fold(0.0, (soma, o) => soma + (o.custoEstimado ?? 0.0));
    totalCount.value = orcamentos.where((o) => o.idServicoFornecido != null).length;
  }

  /// 🔹 Cria um novo orçamento
  Future<void> criarOrcamento(OrcamentoModel model) async {
    try {
      await _db.collection('orcamento').doc(model.idOrcamento).set(model.toMap());
      Get.snackbar(
        "Orçamento enviado",
        "O fornecedor será notificado.",
        backgroundColor: const Color(0xFF388E3C),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        "Erro",
        "Falha ao salvar orçamento: $e",
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    }
  }

  void escutarOrcamentosPorEvento(String idEvento) {
    _db
        .collection('orcamento')
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .listen((snapshot) {
      orcamentos.assignAll(
        snapshot.docs.map((doc) => OrcamentoModel.fromMap(doc.data())).toList(),
      );
    });
  }

  /// 🔹 Escuta os orçamentos de um fornecedor em tempo real
  void escutarOrcamentos(String idFornecedor) {
    _db
        .collection('orcamento')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .listen((snapshot) {
      orcamentos.assignAll(
        snapshot.docs.map((doc) => OrcamentoModel.fromMap(doc.data())).toList(),
      );
    });
  }

  /// 🔹 Atualiza valor e observações no Firestore
  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    bool fechar = false,
  }) async {
    final status = fechar ? 'fechado' : 'em_negociacao';

    await _db.collection('orcamento').doc(idOrcamento).update({
      'custo_estimado': custoEstimado,
      'anotacoes': anotacoes,
      'status': status,
      'orcamento_fechado': fechar,
      if (fechar) 'data_fechamento': FieldValue.serverTimestamp(),
    });
  }

  @override
  void onClose() {
    _orcamentoSubscription?.cancel();
    super.onClose();
  }

  void reset() {
    orcamentos.clear();
  }
}
