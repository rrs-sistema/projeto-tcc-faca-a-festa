import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/model.dart';

class OrcamentoController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final RxList<OrcamentoModel> orcamentos = <OrcamentoModel>[].obs;

  final RxBool carregando = false.obs;
  StreamSubscription? _orcamentoSubscription;

  final RxInt fornecedorContatadoCount = 0.obs;
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;
  final RxDouble totalCustoEstimado = 0.0.obs;

  /// ===========================================================
  /// 🔹 Escuta orçamentos de um evento específico (organizador)
  /// ===========================================================
  Future<void> carregarOrcamentosDoEvento(String idEvento) async {
    try {
      carregando.value = true;
      await _orcamentoSubscription?.cancel();

      _orcamentoSubscription = _db
          .collection('orcamento')
          .where('id_evento', isEqualTo: idEvento)
          .snapshots()
          .listen((snapshot) {
        final lista =
            snapshot.docs.map((doc) => OrcamentoModel.fromMap(doc.data(), docId: doc.id)).toList();

        orcamentos.assignAll(lista);
        _atualizarContagens();
        carregando.value = false;
      }, onError: (e) {
        carregando.value = false;
        debugPrint('❌ Erro ao escutar orçamentos por evento: $e');
      });
    } catch (e, s) {
      carregando.value = false;
      debugPrint('❌ Erro geral em carregarOrcamentosDoEvento: $e\n$s');
    }
  }

  /// ===========================================================
  /// 🔹 Escuta orçamentos em tempo real de um fornecedor
  /// ===========================================================
  void escutarOrcamentos(String idFornecedor) {
    try {
      carregando.value = true;
      _orcamentoSubscription?.cancel();

      _orcamentoSubscription = _db
          .collection('orcamento')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .snapshots()
          .listen((snapshot) {
        final lista =
            snapshot.docs.map((doc) => OrcamentoModel.fromMap(doc.data(), docId: doc.id)).toList();

        orcamentos.assignAll(lista);
        _atualizarContagens();
        carregando.value = false;
      }, onError: (e) {
        carregando.value = false;
        debugPrint('❌ Erro ao escutar orçamentos do fornecedor: $e');
      });
    } catch (e, s) {
      carregando.value = false;
      debugPrint('❌ Erro geral em escutarOrcamentos: $e\n$s');
    }
  }

  /// ===========================================================
  /// 🔹 Atualiza métricas e somatórios
  /// ===========================================================
  void _atualizarContagens() {
    fornecedorContatadoCount.value = orcamentos.where((o) => o.idServicoFornecido != null).length;

    contratadosCount.value = orcamentos.where((o) => o.isFechado).length;

    totalCustoEstimado.value = orcamentos.fold(0.0, (soma, o) => soma + (o.custoEstimado ?? 0.0));

    totalCount.value = orcamentos.length;
  }

  /// ===========================================================
  /// 🔹 Cria um novo orçamento
  /// ===========================================================
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

  /// ===========================================================
  /// 🔹 Atualiza valor e observações no Firestore
  /// ===========================================================
  Future<void> responderOrcamento({
    required String idOrcamento,
    required double custoEstimado,
    String? anotacoes,
    bool fechar = false,
  }) async {
    try {
      final status = fechar ? 'fechado' : 'em_negociacao';
      await _db.collection('orcamento').doc(idOrcamento).update({
        'custo_estimado': custoEstimado,
        'anotacoes': anotacoes,
        'status': status,
        'orcamento_fechado': fechar,
        if (fechar) 'data_fechamento': FieldValue.serverTimestamp(),
      });

      if (fechar) {
        Get.snackbar(
          "Orçamento Fechado",
          "O contrato foi concluído e o faturamento será atualizado.",
          backgroundColor: Colors.teal.shade700,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao responder orçamento: $e');
      Get.snackbar(
        "Erro",
        "Falha ao atualizar orçamento: $e",
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
      );
    }
  }

  /// ===========================================================
  /// 🔹 Reset e ciclo de vida
  /// ===========================================================
  @override
  void onClose() {
    _orcamentoSubscription?.cancel();
    super.onClose();
  }

  void reset() {
    orcamentos.clear();
  }
}
