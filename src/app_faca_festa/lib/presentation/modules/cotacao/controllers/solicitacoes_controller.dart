import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/domain/repositories/solicitacoes_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_solicitacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';

class SolicitacoesController extends GetxController {
  SolicitacoesController({
    required GerenciarSolicitacoes solicitacoesFornecedor,
    String Function()? nomeUsuarioAtual,
  })  : _solicitacoesFornecedor = solicitacoesFornecedor,
        _nomeUsuarioAtual = nomeUsuarioAtual;

  final GerenciarSolicitacoes _solicitacoesFornecedor;
  final String Function()? _nomeUsuarioAtual;

  final solicitacoes = <CotacaoModel>[].obs;
  final carregando = false.obs;
  final erro = ''.obs;

  bool _streamAtiva = false;
  StreamSubscription<List<CotacaoModel>>? _solicitacoesSub;

  void inicializar(String idFornecedor) {
    if (_streamAtiva) return; // evita múltiplas ligações
    _streamAtiva = true;

    carregando.value = true;
    _solicitacoesSub?.cancel();
    _solicitacoesSub = _solicitacoesFornecedor
        .observarSolicitacoesFornecedor(idFornecedor)
        .listen((lista) {
      solicitacoes.assignAll(lista);
      carregando.value = false;
    }, onError: (e) {
      erro.value = 'Erro no stream: $e';
      carregando.value = false;
    });
  }

  Future<void> cancelarCotacao(String idCotacao) async {
    try {
      final canceladoPor = _nomeUsuarioAtual?.call() ??
          Get.find<AppController>().usuarioLogado.value?.nome ??
          'Desconhecido';

      await _solicitacoesFornecedor.cancelarCotacao(
        idCotacao: idCotacao,
        canceladoPor: canceladoPor,
      );

      debugPrint('🟥 Cotação $idCotacao cancelada completamente.');

      _mostrarSnackbar(
        'Cotação cancelada',
        'A cotação e todos os fornecedores vinculados foram cancelados.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    } on SolicitacaoNaoEncontradaException {
      erro.value = 'Cotação não encontrada.';
    } on SolicitacaoNaoCancelavelException catch (e) {
      erro.value = 'A cotação não pode ser cancelada, pois já foi ${e.status}.';
    } on SolicitacaoSemFornecedorException {
      erro.value = 'Nenhum fornecedor encontrado para esta cotação.';
    } catch (e, s) {
      erro.value = 'Erro ao cancelar cotação.';
      debugPrint('❌ Erro ao cancelar cotação: $e\n$s');
      _mostrarSnackbar(
        'Erro',
        'Não foi possível cancelar a cotação.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  String formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  void _mostrarSnackbar(
    String titulo,
    String mensagem, {
    SnackPosition? snackPosition,
    Color? backgroundColor,
    Color? colorText,
  }) {
    if (Get.testMode) return;
    if (Get.context == null && Get.overlayContext == null) return;

    Get.snackbar(
      titulo,
      mensagem,
      snackPosition: snackPosition,
      backgroundColor: backgroundColor,
      colorText: colorText,
    );
  }

  @override
  void onClose() {
    _solicitacoesSub?.cancel();
    super.onClose();
  }
}
