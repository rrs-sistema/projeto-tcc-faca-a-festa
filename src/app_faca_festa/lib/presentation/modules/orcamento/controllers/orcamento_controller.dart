import 'package:app_faca_festa/domain/repositories/financeiro_evento_repository.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_evento_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/entities/orcamento.dart';
import 'package:app_faca_festa/domain/services/auditoria_registrar.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamentos.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';

class OrcamentoController extends GetxController {
  OrcamentoController({
    required GerenciarOrcamentos orcamentos,
    AuditoriaRegistrar? auditoria,
    String? Function()? usuarioAtual,
    EventoController? eventoController,
    OrcamentoGastoController? Function(String idOrcamento)? gastoControllerOf,
  })  : _usuarioAtual = usuarioAtual,
        _orcamentos = orcamentos,
        _eventoController = eventoController,
        _gastoControllerOf = gastoControllerOf,
        _auditoria = auditoria ?? const AuditoriaRegistrarVazio();

  final String? Function()? _usuarioAtual;
  StreamSubscription<List<Map<String, dynamic>>>? _financeiroSubscription;
  int _geracao = 0;
  final resumoFinanceiro = const ResumoFinanceiroEvento().obs;
  final compromissosFinanceiros = <Map<String, dynamic>>[].obs;
  final carregandoFinanceiro = false.obs, erroFinanceiro = ''.obs;
  double get totalCotado => resumoFinanceiro.value.cotado;
  double get totalContratado => resumoFinanceiro.value.contratado;
  double get totalEstimadoConciliado => resumoFinanceiro.value.estimado;
  double get totalPagoLiquido => resumoFinanceiro.value.pagoLiquido;
  double get saldoDevido => resumoFinanceiro.value.saldoDevido;
  void _observarFinanceiro(String evento, int geracao, String? usuario) {
    final repo = _orcamentos.repository;
    if (repo is! FinanceiroEventoRepository) return;
    carregandoFinanceiro.value = true;
    _financeiroSubscription = (repo as FinanceiroEventoRepository)
        .observarFinanceiroEvento(evento)
        .listen((itens) {
      if (geracao != _geracao || usuario != _usuarioAtual?.call()) return;
      final limite =
          _resolverEventoController()?.eventoAtualEntidade?.custoEstimado;
      final resumo = const ResumoFinanceiroEventoService()
          .calcular(itens, limiteConfirmado: limite);
      compromissosFinanceiros.assignAll(itens);
      resumoFinanceiro.value = resumo;
      totalPagoGeral.value = resumo.pagoLiquido;
      if (resumo.estimado > 0) {
        totalCustoEstimado.value = resumo.estimado;
      }
      erroFinanceiro.value = resumo.completo
          ? ''
          : 'Há valores financeiros pendentes de conferência.';
      carregandoFinanceiro.value = false;
    }, onError: (Object e) {
      if (geracao != _geracao || usuario != _usuarioAtual?.call()) return;
      erroFinanceiro.value =
          'Não foi possível atualizar pagamentos e contratos.';
      carregandoFinanceiro.value = false;
    });
  }

  final GerenciarOrcamentos _orcamentos;
  final AuditoriaRegistrar _auditoria;
  final EventoController? _eventoController;
  final OrcamentoGastoController? Function(String idOrcamento)?
      _gastoControllerOf;

  final RxList<Orcamento> orcamentos = <Orcamento>[].obs;
  final RxBool carregando = false.obs;
  StreamSubscription<List<Orcamento>>? _orcamentoSubscription;

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
      carregandoFinanceiro.value = true;
      orcamentos.clear();
      resumoFinanceiro.value = const ResumoFinanceiroEvento();
      totalPagoGeral.value = 0;
      totalCustoEstimado.value = 0;
      final versao = ++_geracao, usuario = _usuarioAtual?.call();
      await _orcamentoSubscription?.cancel();
      await _financeiroSubscription?.cancel();
      if (versao != _geracao || usuario != _usuarioAtual?.call()) return;
      orcamentos.clear();
      totalPagoGeral.value = 0;
      resumoFinanceiro.value = const ResumoFinanceiroEvento();
      erroFinanceiro.value = '';
      _observarFinanceiro(idEvento, versao, usuario);

      _orcamentoSubscription =
          _orcamentos.observarOrcamentosDoEvento(idEvento).listen((lista) {
        if (versao != _geracao || usuario != _usuarioAtual?.call()) return;
        orcamentos.assignAll(lista);
        _atualizarContagens();

        // 🔥 Recalcular o resumo geral sempre que orçamentos mudarem
        calcularTotalPagoGeral();

        carregando.value = false;
      }, onError: (e) {
        if (versao != _geracao || usuario != _usuarioAtual?.call()) return;
        erroFinanceiro.value = 'Não foi possível atualizar o orçamento.';
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
      carregandoFinanceiro.value = true;
      orcamentos.clear();
      resumoFinanceiro.value = const ResumoFinanceiroEvento();
      totalPagoGeral.value = 0;
      totalCustoEstimado.value = 0;
      final versao = ++_geracao, usuario = _usuarioAtual?.call();
      final anteriorFinanceiro = _financeiroSubscription;
      _financeiroSubscription = null;
      unawaited(anteriorFinanceiro?.cancel());
      _orcamentoSubscription?.cancel();

      _orcamentoSubscription = _orcamentos
          .observarOrcamentosDoFornecedor(idFornecedor)
          .listen((lista) {
        if (versao != _geracao || usuario != _usuarioAtual?.call()) return;
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
    if (_financeiroSubscription != null &&
        _orcamentos.repository is FinanceiroEventoRepository) {
      return;
    }
    double total = 0;

    // 🔹 Para cada orçamento, pegar seu controller de gastos
    for (var o in orcamentos) {
      final gastoC = _resolverGastoController(o.idOrcamento);
      if (gastoC != null) {
        total += gastoC.totalPago;
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
    final eventoController = _resolverEventoController();
    final double limiteEvento =
        eventoController?.eventoAtualEntidade?.custoEstimado ?? 0;

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
  Future<void> criarOrcamento(Orcamento model) async {
    try {
      await _orcamentos.criarOrcamento(model);
    } catch (e) {
      _mostrarSnackbar(
        "Erro",
        "Falha ao salvar orçamento: $e",
      );
      rethrow;
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

      final atual =
          orcamentos.firstWhereOrNull((o) => o.idOrcamento == idOrcamento);
      _auditoria.registrar(
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
          if (fechar) const AuditoriaMudanca(campo: 'Status', para: 'fechado'),
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
      final atual =
          orcamentos.firstWhereOrNull((o) => o.idOrcamento == idOrcamento);
      orcamentos.removeWhere((o) => o.idOrcamento == idOrcamento);
      _auditoria.registrar(
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
      final gastoC = _resolverGastoController(idOrcamento);
      if (gastoC == null) return 0.0;
      return gastoC.gastos.fold(0.0, (s, g) => s + g.pago);
    } catch (_) {
      return 0.0;
    }
  }

  OrcamentoGastoController gastoController(String idOrcamento) {
    final controller = _gastoControllerOf?.call(idOrcamento);
    if (controller == null) {
      throw StateError(
        'OrcamentoGastoController não configurado para $idOrcamento.',
      );
    }
    return controller;
  }

  EventoController? _resolverEventoController() {
    if (_eventoController != null) return _eventoController;
    return null;
  }

  OrcamentoGastoController? _resolverGastoController(String idOrcamento) {
    return _gastoControllerOf?.call(idOrcamento);
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
    ++_geracao;
    await _orcamentoSubscription?.cancel();
    await _financeiroSubscription?.cancel();
    _financeiroSubscription = null;
    _orcamentoSubscription = null;
  }

  void reset() {
    unawaited(encerrarEscutas());
    orcamentos.clear();
    compromissosFinanceiros.clear();
    resumoFinanceiro.value = const ResumoFinanceiroEvento();
    carregandoFinanceiro.value = false;
    erroFinanceiro.value = '';
    totalPagoGeral.value = 0;
    fornecedorContatadoCount.value = 0;
    totalCount.value = 0;
    contratadosCount.value = 0;
    totalCustoEstimado.value = 0;
  }

  /// Abre os registros que explicam um total do resumo (conferência).
  List<Map<String, dynamic>> registrosDaConferencia({
    required String fato,
  }) {
    switch (fato) {
      case 'contratado':
        return compromissosFinanceiros
            .where((c) => c['contratado'] == true)
            .toList();
      case 'pago':
        return compromissosFinanceiros
            .where((c) => (c['pago'] is num) && (c['pago'] as num) > 0)
            .toList();
      case 'cotado':
        return compromissosFinanceiros
            .where((c) => (c['cotado'] is num) && (c['cotado'] as num) > 0)
            .toList();
      case 'estimado':
        return compromissosFinanceiros
            .where((c) => (c['estimado'] is num) && (c['estimado'] as num) > 0)
            .toList();
      case 'saldo':
        return compromissosFinanceiros
            .where((c) =>
                c['contratado'] == true &&
                (c['saldo_devido'] is num) &&
                (c['saldo_devido'] as num) != 0)
            .toList();
      default:
        return List<Map<String, dynamic>>.from(compromissosFinanceiros);
    }
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
