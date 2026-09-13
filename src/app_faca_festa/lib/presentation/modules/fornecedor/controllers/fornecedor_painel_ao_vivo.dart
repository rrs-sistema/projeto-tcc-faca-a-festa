import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';

/// Escutas em tempo real e estatísticas do painel do fornecedor.
class FornecedorPainelAoVivo {
  FornecedorPainelAoVivo({
    required this.fornecedor,
    required this.aptoParaOperar,
    required this.solicitacoesPendentes,
    required this.mensagensNaoLidas,
    required this.avaliacaoMedia,
    required this.servicosFornecedor,
    required RxString erro,
    required GerenciarFornecedores Function() usecase,
    required bool Function() usuarioEhFornecedor,
    required void Function(Fornecedor atualizado) aoAtualizar,
    required void Function() aoLimpar,
  })  : _erro = erro,
        _usecase = usecase,
        _usuarioEhFornecedor = usuarioEhFornecedor,
        _aoAtualizar = aoAtualizar,
        _aoLimpar = aoLimpar;

  final Rx<Fornecedor?> fornecedor;
  final RxBool aptoParaOperar;
  final RxInt solicitacoesPendentes;
  final RxInt mensagensNaoLidas;
  final RxDouble avaliacaoMedia;
  final RxList<FornecedorProdutoServico> servicosFornecedor;

  final RxString _erro;
  final GerenciarFornecedores Function() _usecase;
  final bool Function() _usuarioEhFornecedor;
  final void Function(Fornecedor atualizado) _aoAtualizar;
  final void Function() _aoLimpar;

  StreamSubscription<Fornecedor?>? _fornecedorSub;
  StreamSubscription? _solicitacoesSub;
  StreamSubscription<int>? _mensagensSub;
  final List<StreamSubscription> _mensagemListeners = [];
  final Map<String, int> _mensagensNaoLidasPorCotacao = {};

  Future<void> ouvirMensagensNaoLidas(String idFornecedor) async {
    if (idFornecedor.trim().isEmpty) return;
    if (!_usuarioEhFornecedor()) return;

    debugPrint(
        '\n📡 [MSG] Iniciando listener de mensagens NÃO lidas para $idFornecedor');

    await _mensagensSub?.cancel();
    for (final listener in _mensagemListeners) {
      await listener.cancel();
    }
    _mensagemListeners.clear();
    _mensagensNaoLidasPorCotacao.clear();
    mensagensNaoLidas.value = 0;

    _mensagensSub =
        _usecase().observarMensagensNaoLidas(idFornecedor).listen((total) {
      mensagensNaoLidas.value = total;
    }, onError: (e) {
      debugPrint('❌ Erro ao escutar cotações do fornecedor para mensagens: $e');
    });
  }

  void iniciarListenerFornecedor(String idFornecedor) {
    debugPrint('📡 Iniciando listener para fornecedor $idFornecedor...');

    _fornecedorSub?.cancel();

    _fornecedorSub =
        _usecase().observarFornecedorAtivo(idFornecedor).listen((atualizado) {
      if (atualizado != null) {
        fornecedor.value = atualizado;
        aptoParaOperar.value = atualizado.aptoParaOperar;
        debugPrint('✅ Fornecedor atualizado: ${atualizado.razaoSocial}');
        _aoAtualizar(atualizado);
      } else {
        debugPrint('⚠️ Nenhum fornecedor ativo encontrado.');
        fornecedor.value = null;
      }
    }, onError: (e) {
      debugPrint('❌ Erro ao escutar fornecedor: $e');
    });
  }

  Future<void> pararListenerFornecedor() async {
    debugPrint('🛑 Parando listener de fornecedor...');
    await _fornecedorSub?.cancel();
    _fornecedorSub = null;
    fornecedor.value = null;
    _aoLimpar();
  }

  Future<void> escutarSolicitacoesPendentes(String? idFornecedor) async {
    if (idFornecedor == null) return;
    if (!_usuarioEhFornecedor()) return;

    await _solicitacoesSub?.cancel();

    try {
      _erro.value = '';

      _solicitacoesSub = _usecase()
          .observarSolicitacoesPendentes(idFornecedor)
          .listen((total) {
        solicitacoesPendentes.value = total;
      }, onError: (e) {
        debugPrint('❌ Erro ao escutar solicitações pendentes: $e');
      });
    } catch (e, s) {
      debugPrint('❌ Erro ao escutar solicitações pendentes: $e\n$s');
      _erro.value = 'Erro ao escutar solicitações pendentes';
    }
  }

  Future<void> atualizarEstatisticas() async {
    final f = fornecedor.value;
    if (f == null) return;

    try {
      final estatisticas = await _usecase().carregarEstatisticas(f.idFornecedor);
      solicitacoesPendentes.value = estatisticas.solicitacoesPendentes;
      servicosFornecedor.assignAll(estatisticas.servicosAtivos);
      mensagensNaoLidas.value = estatisticas.mensagensNaoLidas;
      avaliacaoMedia.value = estatisticas.avaliacaoMedia;
    } catch (e, s) {
      debugPrint('❌ Erro ao atualizar estatísticas: $e\n$s');
    }
  }

  Future<List<Cotacao>> listarSolicitacoesPendentesDetalhadas() {
    final f = fornecedor.value;
    if (f == null) return Future.value(const []);
    return _usecase().listarSolicitacoesPendentesDetalhadas(f.idFornecedor);
  }

  Future<void> cancelarEscutas() async {
    await _fornecedorSub?.cancel();
    _fornecedorSub = null;
    await _solicitacoesSub?.cancel();
    _solicitacoesSub = null;
    await _mensagensSub?.cancel();
    _mensagensSub = null;
    for (final listener in _mensagemListeners) {
      await listener.cancel();
    }
    _mensagemListeners.clear();
    _mensagensNaoLidasPorCotacao.clear();
    mensagensNaoLidas.value = 0;
  }
}
