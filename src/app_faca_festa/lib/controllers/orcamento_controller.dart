import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../core/services/whatsGw/whatsapp_service.dart';
import '../presentation/whatsapp/whatsapp_templates.dart';
import './../data/models/model.dart';
import 'evento_controller.dart';
import 'orcamento_gasto_controller.dart';

class OrcamentoController extends GetxController {
  final _db = FirebaseFirestore.instance;

  final RxList<OrcamentoModel> orcamentos = <OrcamentoModel>[].obs;
  final RxBool carregando = false.obs;
  StreamSubscription? _orcamentoSubscription;

  /// 🔥 Total geral (pago) usado no resumo financeiro
  final RxDouble totalPagoGeral = 0.0.obs;

  final RxInt fornecedorContatadoCount = 0.obs;
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;
  final RxDouble totalCustoEstimado = 0.0.obs;

  Future<void> notificarAtualizacaoOrcamento({
    required String categoria,
    required String item,
    required double valor,
    required String nomeOrganizador,
    required ConvidadoModel convidado,
  }) async {
    final whats = Get.find<WhatsAppService>();
    final templates = Get.find<WhatsAppTemplates>();

    final msg = templates.atualizacaoOrcamento(
      categoria: categoria,
      item: item,
      valor: valor,
      nomeOrganizador: nomeOrganizador,
    );

    await whats.sendText(
      phone: convidado.contato,
      message: msg,
    );
  }

  /// ===========================================================
  /// 🔹 Escuta orçamentos de um evento específico
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

        // 🔥 Recalcular o resumo geral sempre que orçamentos mudarem
        calcularTotalPagoGeral();

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
  /// 🔹 Escuta orçamentos por fornecedor (modo fornecedor)
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

        calcularTotalPagoGeral();

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
  /// 🔥 Recalcula o total GERAL de valores pagos (usado no resumo)
  /// ===========================================================
  Future<void> calcularTotalPagoGeral() async {
    double total = 0;

    // 🔹 Para cada orçamento, pegar seu controller de gastos
    for (var o in orcamentos) {
      if (Get.isRegistered<OrcamentoGastoController>(tag: o.idOrcamento)) {
        final gastoC = Get.find<OrcamentoGastoController>(tag: o.idOrcamento);
        total += gastoC.totalPago;
      }
      // 🔹 Caso orçamento tenha fornecedor e esteja fechado
      else if (o.isFechado) {
        total += (o.custoEstimado ?? 0.0);
      }
    }

    totalPagoGeral.value = total;
  }

  /// ===========================================================
  /// 🔹 Atualiza métricas e somatórios básicos
  /// ===========================================================
  void _atualizarContagens() {
    fornecedorContatadoCount.value = orcamentos.where((o) => o.idServicoFornecido != null).length;

    contratadosCount.value = orcamentos.where((o) => o.isFechado).length;

    totalCustoEstimado.value = orcamentos.fold(0.0, (soma, o) => soma + (o.custoEstimado ?? 0.0));

    totalCount.value = orcamentos.length;
  }

  /// ===========================================================
  /// 🔹 Valida criação de orçamento
  /// ===========================================================
  Future<(bool ok, String? mensagem, double? excedente, double? limite)> validarCriacaoOrcamento(
      double novoValor) async {
    final eventoController = Get.find<EventoController>();
    final double limiteEvento = eventoController.eventoAtual.value?.custoEstimado ?? 0;

    if (limiteEvento <= 0) {
      return (false, "O evento não possui orçamento estimado definido!", null, 0.0);
    }

    if (novoValor > limiteEvento) {
      final exced = novoValor - limiteEvento;
      return (false, "O valor informado excede o limite total do evento!", exced, limiteEvento);
    }

    final double totalAtual = orcamentos.fold(0, (s, o) => s + (o.custoEstimado ?? 0));
    final double totalPosInsercao = totalAtual + novoValor;

    if (totalPosInsercao > limiteEvento) {
      final exced = totalPosInsercao - limiteEvento;
      return (false, "A soma dos orçamentos excede o limite geral do evento!", exced, limiteEvento);
    }

    return (true, null, null, limiteEvento);
  }

  /// ===========================================================
  /// 🔹 Criar orçamento
  /// ===========================================================
  Future<void> criarOrcamento(OrcamentoModel model) async {
    try {
      await _db.collection('orcamento').doc(model.idOrcamento).set(model.toMap());
    } catch (e) {
      Get.snackbar(
        "Erro",
        "Falha ao salvar orçamento: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// ===========================================================
  /// 🔹 Atualizar orçamento (fornecedor respondendo)
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

      // Atualizar resumo ao fechar orçamento
      calcularTotalPagoGeral();
    } catch (e) {
      debugPrint('❌ Erro ao responder orçamento: $e');
    }
  }

  /// ===========================================================
  /// 🔹 Excluir orçamento
  /// ===========================================================
  Future<void> excluirOrcamento(String idOrcamento) async {
    try {
      await _db.collection('orcamento').doc(idOrcamento).delete();
      orcamentos.removeWhere((o) => o.idOrcamento == idOrcamento);

      calcularTotalPagoGeral();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Falha ao excluir o orçamento. Tente novamente.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  double totalPagoDoOrcamento(String idOrcamento) {
    try {
      final gastoC = Get.find<OrcamentoGastoController>(tag: idOrcamento);
      return gastoC.gastos.fold(0.0, (s, g) => s + g.pago);
    } catch (_) {
      return 0.0;
    }
  }

  /// ===========================================================
  /// 🔹 Ciclo de vida
  /// ===========================================================
  @override
  void onClose() {
    _orcamentoSubscription?.cancel();
    super.onClose();
  }

  void reset() {
    orcamentos.clear();
    totalPagoGeral.value = 0;
  }
}
