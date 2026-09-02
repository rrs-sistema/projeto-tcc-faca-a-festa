import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/orcamento_controller.dart';

class CotacaoController extends GetxController {
  CotacaoController({GerenciarCotacoes? gerenciarCotacoes})
      : _gerenciarCotacoes = gerenciarCotacoes ?? Get.find<GerenciarCotacoes>();

  final GerenciarCotacoes _gerenciarCotacoes;
  final cotacoes = <CotacaoModel>[].obs;
  final carregando = false.obs;

  StreamSubscription? _cotacaoStream;
  final Map<String, StreamSubscription> _subStreams = {};
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;

  void _atualizarContagens() {
    contratadosCount.value =
        cotacoes.where((o) => o.status == StatusCotacao.concluida).length;
    totalCount.value = cotacoes.length;
  }

  // ============================================================
  // 🔹 Escuta todas as cotações do organizador logado
  // ============================================================
  void ouvirMinhasCotacoes() async {
    final idUsuario = Get.find<AppController>().usuarioLogado.value?.idUsuario;
    if (idUsuario == null) return;

    carregando.value = true;
    _cotacaoStream?.cancel();
    _cancelarSubStreams();

    _cotacaoStream =
        _gerenciarCotacoes.observarMinhasCotacoes(idUsuario).listen((lista) {
      try {
        cotacoes.assignAll(lista);
        for (final cotacao in lista) {
          if (!_subStreams.containsKey(cotacao.id)) {
            _ouvirFornecedoresDaCotacao(cotacao.id);
          }
        }
        _atualizarContagens();
      } catch (e, s) {
        debugPrint('❌ Erro ao processar cotações: $e\n$s');
      } finally {
        carregando.value = false;
      }
    }, onError: (e) {
      carregando.value = false;
      debugPrint('❌ Erro ao escutar cotações: $e');
    });
  }

  // ============================================================
  // 🔹 Escuta em tempo real os fornecedores dentro de cada cotação
  // ============================================================
  void _ouvirFornecedoresDaCotacao(String idCotacao) {
    final stream = _gerenciarCotacoes
        .observarCotacaoTemResposta(idCotacao)
        .listen((temResposta) {
      final cotacaoIndex = cotacoes.indexWhere((c) => c.id == idCotacao);
      if (cotacaoIndex != -1) {
        final cotacao = cotacoes[cotacaoIndex];
        if (temResposta && cotacao.status != StatusCotacao.respondida) {
          cotacoes[cotacaoIndex] =
              cotacao.copyWith(status: StatusCotacao.respondida);
          cotacoes.refresh();

          Get.snackbar(
            'Nova resposta recebida!',
            'Um fornecedor respondeu à cotação "${cotacao.categoriaNome}".',
            backgroundColor: Colors.blueAccent,
            colorText: Colors.white,
            icon: const Icon(Icons.mark_chat_read_rounded, color: Colors.white),
            duration: const Duration(seconds: 3),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(12),
          );
        }
      }
    }, onError: (e) {
      debugPrint('❌ Erro ao ouvir fornecedores da cotação $idCotacao: $e');
    });

    _subStreams[idCotacao] = stream;
  }

  Future<void> confirmarFornecedorEscolhido(
      String idFornecedor, String idCotacao) async {
    final fornecedorController = Get.find<FornecedorController>();
    final appController = Get.find<AppController>();
    final fornecedor = fornecedorController.fornecedores
        .firstWhere((f) => f.idFornecedor == idFornecedor);

    try {
      EasyLoading.show(status: 'Fechando negócio... 🔒');

      final idEvento = await _gerenciarCotacoes.confirmarFornecedorEscolhido(
        idCotacao: idCotacao,
        idFornecedor: idFornecedor,
        nomeFornecedor: fornecedor.razaoSocial,
        idSolicitante: appController.usuarioLogado.value?.idUsuario ?? '',
        nomeSolicitante: appController.usuarioLogado.value?.nome ?? '',
      );

      // ===============================================================
      // 🔹 Finalização de UX
      // ===============================================================
      EasyLoading.dismiss();
      HapticFeedback.mediumImpact();

      Get.snackbar(
        'Negócio fechado! 🎉',
        'Orçamento criado e gasto inicial registrado.',
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Atualizar listas
      ouvirMinhasCotacoes();
      Get.find<OrcamentoController>().carregarOrcamentosDoEvento(idEvento);
    } catch (e) {
      EasyLoading.dismiss();
      Get.snackbar(
        'Erro',
        'Não foi possível fechar o negócio.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _cancelarSubStreams() {
    for (final sub in _subStreams.values) {
      sub.cancel();
    }
    _subStreams.clear();
  }

  Future<void> encerrarEscutas() async {
    await _cotacaoStream?.cancel();
    _cotacaoStream = null;
    _cancelarSubStreams();
    cotacoes.clear();
    carregando.value = false;
  }

  @override
  void onClose() {
    unawaited(encerrarEscutas());
    super.onClose();
  }
}
