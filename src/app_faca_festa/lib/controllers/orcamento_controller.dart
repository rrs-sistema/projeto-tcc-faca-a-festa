import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import './../data/models/model.dart';
import './../data/services/auditoria/auditoria_app.dart';
import './../domain/entities/auditoria_evento.dart';
import './../domain/usecases/gerenciar_orcamentos.dart';
import 'evento_controller.dart';
import 'orcamento_gasto_controller.dart';

class OrcamentoController extends GetxController {
  OrcamentoController({required GerenciarOrcamentos orcamentos})
      : _orcamentos = orcamentos;

  final GerenciarOrcamentos _orcamentos;

  final RxList<OrcamentoModel> orcamentos = <OrcamentoModel>[].obs;
  final RxBool carregando = false.obs;
  StreamSubscription<List<OrcamentoModel>>? _orcamentoSubscription;

  /// 🔥 Total geral (pago) usado no resumo financeiro
  final RxDouble totalPagoGeral = 0.0.obs;

  final RxInt fornecedorContatadoCount = 0.obs;
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;
  final RxDouble totalCustoEstimado = 0.0.obs;

  /// ===========================================================
  /// 🔹 Escuta orçamentos de um evento específico
  /// ===========================================================
  Future<void> carregarOrcamentosDoEvento(String idEvento) async {
    try {
      carregando.value = true;
      await _orcamentoSubscription?.cancel();

      _orcamentoSubscription =
          _orcamentos.observarOrcamentosDoEvento(idEvento).listen((lista) {
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

      _orcamentoSubscription = _orcamentos
          .observarOrcamentosDoFornecedor(idFornecedor)
          .listen((lista) {
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
    fornecedorContatadoCount.value =
        orcamentos.where((o) => o.idServicoFornecido != null).length;

    contratadosCount.value = orcamentos.where((o) => o.isFechado).length;

    totalCustoEstimado.value =
        orcamentos.fold(0.0, (soma, o) => soma + (o.custoEstimado ?? 0.0));

    totalCount.value = orcamentos.length;
  }

  /// ===========================================================
  /// 🔹 Valida criação de orçamento
  /// ===========================================================
  Future<(bool ok, String? mensagem, double? excedente, double? limite)>
      validarCriacaoOrcamento(double novoValor) async {
    final eventoController = Get.find<EventoController>();
    final double limiteEvento =
        eventoController.eventoAtualEntidade?.custoEstimado ?? 0;

    if (limiteEvento <= 0) {
      return (
        false,
        "O evento não possui orçamento estimado definido!",
        null,
        0.0
      );
    }

    if (novoValor > limiteEvento) {
      final exced = novoValor - limiteEvento;
      return (
        false,
        "O valor informado excede o limite total do evento!",
        exced,
        limiteEvento
      );
    }

    final double totalAtual =
        orcamentos.fold(0, (s, o) => s + (o.custoEstimado ?? 0));
    final double totalPosInsercao = totalAtual + novoValor;

    if (totalPosInsercao > limiteEvento) {
      final exced = totalPosInsercao - limiteEvento;
      return (
        false,
        "A soma dos orçamentos excede o limite geral do evento!",
        exced,
        limiteEvento
      );
    }

    return (true, null, null, limiteEvento);
  }

  /// ===========================================================
  /// 🔹 Criar orçamento
  /// ===========================================================
  Future<void> criarOrcamento(OrcamentoModel model) async {
    try {
      await _orcamentos.criarOrcamento(model);
    } catch (e) {
      _mostrarSnackbar(
        "Erro",
        "Falha ao salvar orçamento: $e",
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
      await _orcamentos.responderOrcamento(
        idOrcamento: idOrcamento,
        custoEstimado: custoEstimado,
        anotacoes: anotacoes,
        fechar: fechar,
      );

      final atual = orcamentos.firstWhereOrNull((o) => o.idOrcamento == idOrcamento);
      AuditoriaApp.registrar(
        acao: 'ORCAMENTO_RESPONDIDO',
        resumo: fechar
            ? 'Orçamento respondido e fechado.'
            : 'Proposta de orçamento atualizada.',
        entidadeTipo: 'orcamento',
        entidadeId: idOrcamento,
        entidadeNome: atual?.nomeFornecedor,
        idFornecedor: atual?.idFornecedor,
        idEvento: atual?.idEvento,
        idOrcamento: idOrcamento,
        mudancas: [
          AuditoriaMudanca(
            campo: 'Custo estimado',
            para: custoEstimado.toStringAsFixed(2),
          ),
          if (fechar)
            const AuditoriaMudanca(campo: 'Status', para: 'fechado'),
        ],
      );

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
      await _orcamentos.excluirOrcamento(idOrcamento);
      final atual = orcamentos.firstWhereOrNull((o) => o.idOrcamento == idOrcamento);
      orcamentos.removeWhere((o) => o.idOrcamento == idOrcamento);
      AuditoriaApp.registrar(
        acao: 'ORCAMENTO_EXCLUIDO',
        resumo: 'Orçamento excluído.',
        entidadeTipo: 'orcamento',
        entidadeId: idOrcamento,
        entidadeNome: atual?.nomeFornecedor,
        idFornecedor: atual?.idFornecedor,
        idEvento: atual?.idEvento,
        idOrcamento: idOrcamento,
      );

      calcularTotalPagoGeral();
    } catch (e) {
      _mostrarSnackbar(
        'Erro',
        'Falha ao excluir o orçamento. Tente novamente.',
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
    unawaited(encerrarEscutas());
    super.onClose();
  }

  Future<void> encerrarEscutas() async {
    await _orcamentoSubscription?.cancel();
    _orcamentoSubscription = null;
  }

  void reset() {
    unawaited(encerrarEscutas());
    orcamentos.clear();
    totalPagoGeral.value = 0;
    fornecedorContatadoCount.value = 0;
    totalCount.value = 0;
    contratadosCount.value = 0;
    totalCustoEstimado.value = 0;
  }

  void _mostrarSnackbar(String titulo, String mensagem) {
    if (Get.testMode) return;
    if (Get.context == null && Get.overlayContext == null) return;

    Get.snackbar(
      titulo,
      mensagem,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }
}
