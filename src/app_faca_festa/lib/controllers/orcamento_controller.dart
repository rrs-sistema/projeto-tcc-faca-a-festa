import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/model.dart';
import 'evento_controller.dart';

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
  /// 🔹 Valida se é permitido criar um novo orçamento
  /// ===========================================================
  Future<(bool ok, String? mensagem, double? excedente, double? limite)> validarCriacaoOrcamento(
      double novoValor) async {
    final eventoController = Get.find<EventoController>();

    final double limiteEvento = eventoController.eventoAtual.value?.custoEstimado ?? 0;

    // 🔥 1) O valor do evento é zero → não permitir
    if (limiteEvento <= 0) {
      return (false, "O evento não possui orçamento estimado definido!", null, 0.0);
    }

    // 🔥 2) O novo orçamento sozinho já excede o valor total permitido
    if (novoValor > limiteEvento) {
      final exced = novoValor - limiteEvento;
      return (false, "O valor informado excede o limite total do evento!", exced, limiteEvento);
    }

    // 🔥 3) Soma total dos orçamentos existentes + novo
    final double totalAtual = orcamentos.fold(0, (s, o) => s + (o.custoEstimado ?? 0));
    final double totalPosInsercao = totalAtual + novoValor;

    if (totalPosInsercao > limiteEvento) {
      final exced = totalPosInsercao - limiteEvento;
      return (false, "A soma dos orçamentos excede o limite geral do evento!", exced, limiteEvento);
    }

    // 🔥 OK!
    return (true, null, null, limiteEvento);
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

  Future<void> excluirOrcamento(String idOrcamento) async {
    try {
      await _db.collection('orcamento').doc(idOrcamento).delete();
      orcamentos.removeWhere((o) => o.idOrcamento == idOrcamento);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Falha ao excluir o orçamento. Tente novamente.',
        backgroundColor: Colors.redAccent,
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
