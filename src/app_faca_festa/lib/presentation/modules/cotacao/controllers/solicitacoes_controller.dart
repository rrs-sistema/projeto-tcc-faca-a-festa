import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/repositories/solicitacoes_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_solicitacoes.dart';

class SolicitacoesController extends GetxController {
  SolicitacoesController({
    required GerenciarSolicitacoes solicitacoesFornecedor,
    String Function()? nomeUsuarioAtual,
  })  : _solicitacoesFornecedor = solicitacoesFornecedor,
        _nomeUsuarioAtual = nomeUsuarioAtual;

  final GerenciarSolicitacoes _solicitacoesFornecedor;
  final String Function()? _nomeUsuarioAtual;

  final solicitacoes = <Cotacao>[].obs;
  final carregando = false.obs;
  final erro = ''.obs;

  String? _fornecedor;
  int _geracao = 0;
  StreamSubscription<List<Cotacao>>? _solicitacoesSub;

  void inicializar(String idFornecedor) {
    if (_fornecedor == idFornecedor && _solicitacoesSub != null) return;
    _fornecedor = idFornecedor;
    final g = ++_geracao;
    solicitacoes.clear();
    erro.value = '';

    carregando.value = true;
    _solicitacoesSub?.cancel();
    _solicitacoesSub = _solicitacoesFornecedor
        .observarSolicitacoesFornecedor(idFornecedor)
        .listen((lista) {
      if (g != _geracao) return;
      erro.value = '';
      solicitacoes.assignAll(lista);
      carregando.value = false;
    }, onError: (e) {
      if (g != _geracao) return;
      solicitacoes.clear();
      erro.value = 'Não foi possível consultar os atendimentos.';
      carregando.value = false;
    }, onDone: () {
      if (g == _geracao) {
        _fornecedor = null;
        _solicitacoesSub = null;
        solicitacoes.clear();
        carregando.value = false;
      }
    });
  }

  Future<void> cancelarCotacao(String idCotacao) async {
    try {
      final canceladoPor = _nomeUsuarioAtual?.call() ?? 'Desconhecido';

      await _solicitacoesFornecedor.cancelarCotacao(
        idCotacao: idCotacao,
        canceladoPor: canceladoPor,
      );

      debugPrint('Encerramento comercial registrado para $idCotacao.');

      _mostrarSnackbar(
        'Cotação cancelada',
        'Seu encerramento comercial foi registrado. Isso não confirma entrega nem cancela contrato aceito.',
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
    ++_geracao;
    _solicitacoesSub?.cancel();
    super.onClose();
  }
}
