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
    String? Function()? usuarioAtual,
    required void Function(Fornecedor atualizado) aoAtualizar,
    required void Function() aoLimpar,
  })  : _erro = erro,
        _usecase = usecase,
        _usuarioEhFornecedor = usuarioEhFornecedor,
        _usuarioAtual = usuarioAtual,
        _aoAtualizar = aoAtualizar,
        _aoLimpar = aoLimpar;

  final Rx<Fornecedor?> fornecedor;
  final RxBool aptoParaOperar;
  final RxInt solicitacoesPendentes;
  final RxnInt mensagensNaoLidas;
  final RxDouble avaliacaoMedia;
  final RxList<FornecedorProdutoServico> servicosFornecedor;

  final RxString _erro;
  final GerenciarFornecedores Function() _usecase;
  final bool Function() _usuarioEhFornecedor;
  final String? Function()? _usuarioAtual;
  int _msg = 0, _forn = 0, _sol = 0, _estat = 0;
  bool _conta(String id) =>
      _usuarioEhFornecedor() &&
      (_usuarioAtual == null || _usuarioAtual() == id);
  final void Function(Fornecedor atualizado) _aoAtualizar;
  final void Function() _aoLimpar;

  StreamSubscription<Fornecedor?>? _fornecedorSub;
  StreamSubscription? _solicitacoesSub;
  StreamSubscription<int>? _mensagensSub;
  Future<void> ouvirMensagensNaoLidas(String idFornecedor) async {
    if (idFornecedor.trim().isEmpty || !_conta(idFornecedor)) return;
    final versao = ++_msg;
    final anterior = _mensagensSub;
    _mensagensSub = null;
    mensagensNaoLidas.value = null;
    await anterior?.cancel();
    if (versao != _msg || !_conta(idFornecedor)) return;

    _mensagensSub =
        _usecase().observarMensagensNaoLidas(idFornecedor).listen((total) {
      if (versao != _msg || !_conta(idFornecedor)) return;
      mensagensNaoLidas.value = total;
    }, onError: (e) {
      if (versao != _msg || !_conta(idFornecedor)) return;
      mensagensNaoLidas.value = null;
      debugPrint('❌ Erro ao escutar cotações do fornecedor para mensagens: $e');
    });
  }

  void iniciarListenerFornecedor(String idFornecedor) {
    final versao = ++_forn;
    debugPrint('📡 Iniciando listener para fornecedor $idFornecedor...');

    _fornecedorSub?.cancel();

    _fornecedorSub =
        _usecase().observarFornecedorAtivo(idFornecedor).listen((atualizado) {
      if (versao != _forn) return;
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
    ++_forn;
    ++_estat;
    debugPrint('🛑 Parando listener de fornecedor...');
    await _fornecedorSub?.cancel();
    _fornecedorSub = null;
    fornecedor.value = null;
    _aoLimpar();
  }

  Future<void> escutarSolicitacoesPendentes(String? idFornecedor) async {
    final versao = ++_sol;
    if (idFornecedor == null) return;
    if (!_usuarioEhFornecedor()) return;

    await _solicitacoesSub?.cancel();

    try {
      _erro.value = '';

      _solicitacoesSub = _usecase()
          .observarSolicitacoesPendentes(idFornecedor)
          .listen((total) {
        if (versao != _sol || !_conta(idFornecedor)) return;
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
    final versao = ++_estat;
    final f = fornecedor.value;
    if (f == null) return;

    try {
      final estatisticas =
          await _usecase().carregarEstatisticas(f.idFornecedor);
      if (versao != _estat ||
          !_conta(f.idFornecedor) ||
          fornecedor.value?.idFornecedor != f.idFornecedor) {
        return;
      }
      solicitacoesPendentes.value = estatisticas.solicitacoesPendentes;
      servicosFornecedor.assignAll(estatisticas.servicosAtivos);
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
    ++_msg;
    ++_forn;
    ++_sol;
    ++_estat;
    final mensagensCanceladas = _mensagensSub?.cancel();
    _mensagensSub = null;
    mensagensNaoLidas.value = null;
    await _fornecedorSub?.cancel();
    _fornecedorSub = null;
    await _solicitacoesSub?.cancel();
    _solicitacoesSub = null;
    await mensagensCanceladas;
  }
}
