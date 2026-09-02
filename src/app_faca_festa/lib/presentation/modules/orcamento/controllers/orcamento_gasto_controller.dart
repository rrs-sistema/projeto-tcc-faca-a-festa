import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/data/models/orcamento/orcamento_gasto_model.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_validacao_resultado.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamento_gastos.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/orcamento_controller.dart';

class OrcamentoGastoController extends GetxController {
  OrcamentoGastoController({required GerenciarOrcamentoGastos gastosOrcamento})
      : _gastosOrcamento = gastosOrcamento;

  final GerenciarOrcamentoGastos _gastosOrcamento;

  final RxList<OrcamentoGastoModel> gastos = <OrcamentoGastoModel>[].obs;
  StreamSubscription<List<OrcamentoGastoModel>>? _gastosSub;

  /// Escuta os gastos de um orçamento específico
  void escutarGastos(String idOrcamento) {
    unawaited(_gastosSub?.cancel());
    _gastosSub = _gastosOrcamento.observarGastos(idOrcamento).listen((lista) {
      gastos.assignAll(lista);

      _atualizarResumoGeral();
    }, onError: (e) {
      debugPrint('❌ Erro ao escutar gastos do orçamento: $e');
    });
  }

  Future<void> encerrarEscutas() async {
    await _gastosSub?.cancel();
    _gastosSub = null;
    gastos.clear();
  }

  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) async {
    final resultado = await _gastosOrcamento.adicionarGasto(
      idOrcamento: idOrcamento,
      nome: nome,
      custo: custo,
      pago: pago,
    );

    // 🔥 Atualiza total geral
    _atualizarResumoGeral();

    return resultado;
  }

  Future<void> marcarComoPago(
    String idOrcamento,
    String idGasto,
    double valorTotal,
  ) async {
    await _gastosOrcamento.marcarComoPago(
      idOrcamento: idOrcamento,
      idGasto: idGasto,
      valorTotal: valorTotal,
    );

    // 🔥 Atualiza total geral
    _atualizarResumoGeral();
  }

  Future<void> removerGasto(String idOrcamento, String idGasto) async {
    await _gastosOrcamento.removerGasto(
      idOrcamento: idOrcamento,
      idGasto: idGasto,
    );

    // 🔥 Atualiza total geral
    _atualizarResumoGeral();
  }

  /// Totalizadores por categoria
  double get totalPago => gastos.fold(0.0, (soma, g) => soma + g.pago);
  double get totalGasto => gastos.fold(0.0, (soma, g) => soma + g.custo);

  /// ==========================================================
  /// 🔥 NOVO: Atualiza RESUMO DO EVENTO automaticamente
  /// ==========================================================
  void _atualizarResumoGeral() {
    if (Get.isRegistered<OrcamentoController>()) {
      final c = Get.find<OrcamentoController>();
      c.calcularTotalPagoGeral(); // método já existente no OrcamentoController
    }
  }
}
