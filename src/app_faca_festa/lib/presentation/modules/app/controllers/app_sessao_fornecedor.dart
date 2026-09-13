import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/push_token_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_destino_rota.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

class AppSessaoFornecedor {
  AppSessaoFornecedor({
    required GerenciarFornecedores fornecedores,
    required FornecedorController fornecedorController,
    required EventThemeController theme,
    required OrcamentoController orcamentos,
    required AvaliacaoServicoController avaliacoes,
    required ServicoProdutoController servicos,
    required PushTokenRepository push,
  })  : _fornecedores = fornecedores,
        _fornecedorController = fornecedorController,
        _theme = theme,
        _orcamentos = orcamentos,
        _avaliacoes = avaliacoes,
        _servicos = servicos,
        _push = push;

  final GerenciarFornecedores _fornecedores;
  final FornecedorController _fornecedorController;
  final EventThemeController _theme;
  final OrcamentoController _orcamentos;
  final AvaliacaoServicoController _avaliacoes;
  final ServicoProdutoController _servicos;
  final PushTokenRepository _push;

  Usuario? Function()? _usuarioLogado;
  RxBool? _carregando;
  StreamSubscription<String>? _fcmTokenSub;

  void vincular({
    required Usuario? Function() usuarioLogado,
    required RxBool carregando,
  }) {
    _usuarioLogado = usuarioLogado;
    _carregando = carregando;
  }

  Future<AppDestinoRota> resolverDestino(String idUsuario) async {
    final fornecedor = await _fornecedores.buscarPorUsuario(idUsuario);

    if (fornecedor == null) {
      _fornecedorController.fornecedor.value = null;
      _fornecedorController.aptoParaOperar.value = false;
      return const AppDestinoRota('/fornecedor');
    }

    _fornecedorController.fornecedor.value = fornecedor;
    _fornecedorController.aptoParaOperar.value = fornecedor.aptoParaOperar;

    if (!fornecedor.aptoParaOperar) {
      return const AppDestinoRota('/fornecedor');
    }

    await iniciarPainel(fornecedor);
    _theme.aplicarTemaProduto();
    return const AppDestinoRota('/fornecedor');
  }

  Future<void> iniciarPainel(Fornecedor fornecedor) async {
    await atualizarFcmToken(fornecedor.idUsuario);

    _fornecedorController.ouvirMensagensNaoLidas(fornecedor.idUsuario);
    _fornecedorController.iniciarListenerFornecedor(fornecedor.idUsuario);
    _fornecedorController.escutarSolicitacoesPendentes(fornecedor.idUsuario);

    _orcamentos.escutarOrcamentos(fornecedor.idUsuario);
    _avaliacoes.carregarAvaliacoesFornecedor(fornecedor.idUsuario);
    _servicos.carregarServicosComDetalhesOtimizado(
      idFornecedor: fornecedor.idUsuario,
    );
  }

  /// Recarrega o cadastro do fornecedor logado. Se o admin já aprovou
  /// (`apto_para_operar`), abre a home operacional nesta sessão.
  Future<void> verificarAprovacaoPendente() async {
    final usuario = _usuarioLogado?.call();
    final carregando = _carregando;
    if (usuario == null || usuario.tipo != 'F') return;
    if (carregando == null || carregando.value) return;

    carregando.value = true;
    try {
      final destino = await resolverDestino(usuario.idUsuario);
      if (_fornecedorController.aptoParaOperar.value) {
        Get.offAllNamed(destino.nome, arguments: destino.argumentos);
        return;
      }

      Get.snackbar(
        'Em análise',
        'Seu cadastro ainda não foi aprovado pelo administrador.',
        backgroundColor: Colors.orange.shade400,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> atualizarFcmToken(String idFornecedor) async {
    if (!_push.suportaTokenPush) {
      if (kDebugMode) {
        print('ℹ️ FCM não suportado nesta plataforma para fornecedor.');
      }
      return;
    }

    try {
      await _push.solicitarPermissao();

      final token = await _push.obterTokenAtual();
      if (token == null || token.isEmpty) return;

      await _fornecedores.atualizarFcmToken(
        idFornecedor: idFornecedor,
        token: token,
      );

      await _fcmTokenSub?.cancel();
      _fcmTokenSub = _push.observarAtualizacoesToken().listen((newToken) async {
        if (newToken.isEmpty) return;

        await _fornecedores.atualizarFcmToken(
          idFornecedor: idFornecedor,
          token: newToken,
        );
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar FCM token do fornecedor: $e');
      }
    }
  }

  Future<void> encerrar() async {
    await _fcmTokenSub?.cancel();
    _fcmTokenSub = null;
  }
}
