import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_cotacoes.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';

class CotacaoController extends GetxController {
  CotacaoController({
    required GerenciarCotacoes gerenciarCotacoes,
    AppController? appController,
    AppController? Function()? appControllerResolver,
  })  : _gerenciarCotacoes = gerenciarCotacoes,
        _appController = appController,
        _appControllerResolver = appControllerResolver;

  final GerenciarCotacoes _gerenciarCotacoes;
  final AppController? _appController;
  final AppController? Function()? _appControllerResolver;
  final cotacoes = <Cotacao>[].obs;
  final carregando = false.obs;
  final erroEscuta = ''.obs;

  StreamSubscription? _cotacaoStream;
  final Map<String, StreamSubscription> _subStreams = {};
  final RxInt totalCount = 0.obs;
  final RxInt contratadosCount = 0.obs;

  GerenciarCotacoes get gerenciarCotacoes => _gerenciarCotacoes;

  /// A consulta da conta inclui vários eventos; telas de uma festa devem
  /// usar esta seleção para a lista e para todos os seus indicadores.
  List<Cotacao> cotacoesDoEvento(String? idEvento) {
    final id = idEvento?.trim() ?? '';
    if (id.isEmpty) return const [];
    return cotacoes.where((cotacao) => cotacao.idEvento == id).toList();
  }

  int totalDoEvento(String? idEvento) => cotacoesDoEvento(idEvento).length;

  void _atualizarContagens() {
    contratadosCount.value =
        cotacoes.where((o) => o.status == StatusCotacao.concluida).length;
    totalCount.value = cotacoes.length;
  }

  // ============================================================
  // 🔹 Escuta todas as cotações do organizador logado
  // ============================================================
  void ouvirMinhasCotacoes() async {
    final idUsuario = _resolverAppController()?.usuarioLogado.value?.idUsuario;
    if (idUsuario == null) return;

    carregando.value = true;
    erroEscuta.value = '';
    _cotacaoStream?.cancel();
    _cancelarSubStreams();

    _cotacaoStream =
        _gerenciarCotacoes.observarMinhasCotacoes(idUsuario).listen((lista) {
      try {
        cotacoes.assignAll(lista);
        erroEscuta.value = '';
        for (final cotacao in lista) {
          if (!_subStreams.containsKey(cotacao.id)) {
            _ouvirFornecedoresDaCotacao(cotacao.id);
          }
        }
        _atualizarContagens();
      } catch (e, s) {
        erroEscuta.value =
            'Não foi possível montar a lista de pedidos. Tente novamente.';
        debugPrint('❌ Erro ao processar cotações: $e\n$s');
      } finally {
        carregando.value = false;
      }
    }, onError: (e) {
      carregando.value = false;
      erroEscuta.value =
          'Não foi possível carregar seus pedidos de preço. Verifique a conexão e tente de novo.';
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
        // Só promove pendente → parcial (não força respondida: o pai no
        // Firestore é a fonte da verdade via stream principal).
        if (temResposta && cotacao.status == StatusCotacao.pendente) {
          cotacoes[cotacaoIndex] =
              cotacao.copyWith(status: StatusCotacao.parcial);
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

  Future<void> abrirRevisaoProposta(
      String idFornecedor, String idCotacao) async {
    try {
      await Get.toNamed(
        '/jornada-atendimento',
        arguments: {'idCotacao': idCotacao, 'idFornecedor': idFornecedor},
      );
    } catch (e, s) {
      debugPrint('Erro ao abrir a revisão da proposta: $e\n$s');
      Get.snackbar(
        'Erro',
        'Não foi possível abrir a proposta. Tente novamente.',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  AppController? _resolverAppController() {
    if (_appController != null) return _appController;
    return _appControllerResolver?.call();
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
    erroEscuta.value = '';
    _atualizarContagens();
    carregando.value = false;
  }

  @override
  void onClose() {
    unawaited(encerrarEscutas());
    super.onClose();
  }
}
