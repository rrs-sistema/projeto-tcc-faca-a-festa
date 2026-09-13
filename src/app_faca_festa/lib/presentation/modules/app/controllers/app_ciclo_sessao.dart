import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_carrinho_cotacao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_convite_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_destino_rota.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_rotas_sessao.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_sessao_fornecedor.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_totp_sessao.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/cotacao/controllers/cotacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

/// Observa Auth, decide a rota inicial e encerra a sessão.
class AppCicloSessao {
  AppCicloSessao({
    required AutenticacaoRepository autenticacao,
    required PerfilUsuarioRepository perfil,
    required AppConviteController convite,
    required AppTotpSessao totp,
    required AppCarrinhoCotacao carrinho,
    required AppSessaoFornecedor sessaoFornecedor,
    required EventoController eventos,
    required OrcamentoController orcamentos,
    required CotacaoController cotacoes,
    required FornecedorController fornecedor,
    required TarefaController tarefas,
    required ServicoProdutoController servicos,
    required EventThemeController theme,
    GerenciarAuditoria? auditoria,
    GerenciarAuditoria? Function()? auditoriaResolver,
  })  : _autenticacao = autenticacao,
        _perfil = perfil,
        _convite = convite,
        _totp = totp,
        _carrinho = carrinho,
        _sessaoFornecedor = sessaoFornecedor,
        _eventos = eventos,
        _orcamentos = orcamentos,
        _cotacoes = cotacoes,
        _fornecedor = fornecedor,
        _tarefas = tarefas,
        _servicos = servicos,
        _theme = theme,
        _auditoria = auditoria,
        _auditoriaResolver = auditoriaResolver;

  static const String _logTag = '[AppCicloSessao]';

  final AutenticacaoRepository _autenticacao;
  final PerfilUsuarioRepository _perfil;
  final AppConviteController _convite;
  final AppTotpSessao _totp;
  final AppCarrinhoCotacao _carrinho;
  final AppSessaoFornecedor _sessaoFornecedor;
  final EventoController _eventos;
  final OrcamentoController _orcamentos;
  final CotacaoController _cotacoes;
  final FornecedorController _fornecedor;
  final TarefaController _tarefas;
  final ServicoProdutoController _servicos;
  final EventThemeController _theme;
  final GerenciarAuditoria? _auditoria;
  final GerenciarAuditoria? Function()? _auditoriaResolver;

  Rx<Usuario?>? _usuarioLogado;
  Rx<EnderecoUsuario?>? _enderecoPrincipal;
  RxList<EnderecoUsuario>? _enderecosUsuario;
  RxBool? _carregando;
  RxBool? _encerrandoSessao;
  RxBool? _contaIncompleta;
  void Function(Usuario usuario)? _sincronizarUsuarioController;
  void Function()? _validarDependenciasHomeEvent;
  void Function()? _validarDependenciasAdminDashboard;
  Future<void> Function()? _pararEscutasOpcionais;

  StreamSubscription<SessaoUsuario?>? _sessaoSub;
  bool _processandoSessao = false;
  bool _sessaoPendente = false;

  void vincular({
    required Rx<Usuario?> usuarioLogado,
    required Rx<EnderecoUsuario?> enderecoPrincipal,
    required RxList<EnderecoUsuario> enderecosUsuario,
    required RxBool carregando,
    required RxBool encerrandoSessao,
    required RxBool contaIncompleta,
    required void Function(Usuario usuario) sincronizarUsuarioController,
    required void Function() validarDependenciasHomeEvent,
    required void Function() validarDependenciasAdminDashboard,
    required Future<void> Function() pararEscutasOpcionais,
  }) {
    _usuarioLogado = usuarioLogado;
    _enderecoPrincipal = enderecoPrincipal;
    _enderecosUsuario = enderecosUsuario;
    _carregando = carregando;
    _encerrandoSessao = encerrandoSessao;
    _contaIncompleta = contaIncompleta;
    _sincronizarUsuarioController = sincronizarUsuarioController;
    _validarDependenciasHomeEvent = validarDependenciasHomeEvent;
    _validarDependenciasAdminDashboard = validarDependenciasAdminDashboard;
    _pararEscutasOpcionais = pararEscutasOpcionais;
  }

  void monitorar() {
    _sessaoSub?.cancel();
    _sessaoSub = _autenticacao.observarSessao().listen((user) {
      unawaited(processar(user));
    });
  }

  void iniciar() {
    if (_sessaoSub == null) {
      monitorar();
      return;
    }

    final idUsuario = _autenticacao.idUsuarioAtual;
    if (idUsuario == null) {
      unawaited(processar(null));
      return;
    }

    unawaited(processar(SessaoUsuario(
      idUsuario: idUsuario,
      email: _autenticacao.emailUsuarioAtual,
    )));
  }

  Future<void> processar(SessaoUsuario? user) async {
    if (_processandoSessao) {
      _sessaoPendente = true;
      debugPrint(
        '$_logTag Validação de sessão já em andamento. Nova tentativa será reprocessada.',
      );
      return;
    }
    _processandoSessao = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final token = _convite.tokenConviteAtual();

      if (_convite.acessoPorLink.value &&
          (user == null ||
              _autenticacao.sessaoAnonima ||
              _autenticacao.sessaoVisitanteConvite)) {
        debugPrint(
            '$_logTag Visita por convite em andamento. Sem redirecionar.');
        return;
      }

      if (_convite.acessoPorLink.value &&
          user != null &&
          !_autenticacao.sessaoAnonima &&
          !_autenticacao.sessaoVisitanteConvite) {
        _convite.acessoPorLink.value = false;
      }

      if (user == null) {
        _totp.limpar();
        if (token != null && token.isNotEmpty) {
          _convite.guardarTokenConvite(token);
          debugPrint(
              '$_logTag Token de convite pendente; a tela de convite conduz: $token');
          return;
        }

        _usuarioLogado?.value = null;
        _enderecoPrincipal?.value = null;
        _eventos.limparSessaoAtual();

        if (Get.currentRoute != '/role') Get.offAllNamed('/role');
        return;
      }

      if (_autenticacao.sessaoAnonima ||
          _autenticacao.sessaoVisitanteConvite) {
        debugPrint('$_logTag Sessão de convite; aguardando área do convidado.');
        return;
      }

      final rotaAtual = Get.currentRoute;
      final noConvite = rotaAtual.startsWith('/convite');
      if (!noConvite &&
          !AppRotasSessao.ehTotp(rotaAtual) &&
          !AppRotasSessao.destinoEstavel(rotaAtual) &&
          !AppRotasSessao.usuarioJaNavegando(
            rotaAtual,
            temUsuario: _usuarioLogado?.value != null,
          ) &&
          (rotaAtual.isEmpty || rotaAtual != '/splash')) {
        Future.microtask(() {
          if (AppRotasSessao.ehTotp(Get.currentRoute)) return;
          if (Get.currentRoute.startsWith('/convite')) return;
          if (AppRotasSessao.destinoEstavel(Get.currentRoute)) return;
          if (AppRotasSessao.usuarioJaNavegando(
            Get.currentRoute,
            temUsuario: _usuarioLogado?.value != null,
          )) {
            return;
          }
          Get.offAllNamed('/splash');
        });
      }

      _carregando?.value = true;

      try {
        final perfil = await carregarPerfilComTentativas(user.idUsuario);

        if (perfil == null) {
          throw Exception('Usuário não encontrado no Firestore.');
        }

        final usuarioTotp = perfil.usuario;
        if (usuarioTotp.ativo == false) {
          _carregando?.value = false;
          Get.snackbar(
            'Conta desativada',
            'Entre em contato com o suporte para reativar o acesso.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          await _autenticacao.sair();
          _usuarioLogado?.value = null;
          _eventos.limparSessaoAtual();
          Get.offAllNamed('/role');
          return;
        }

        if (_totp.deveExigir()) {
          _carregando?.value = false;
          final metodoEmail = usuarioTotp.mfaMetodo == 'email' ||
              (usuarioTotp.mfaEmailAtivo && !usuarioTotp.mfaTotpAtivo);
          final rota = (usuarioTotp.mfaTotpAtivo || usuarioTotp.mfaEmailAtivo)
              ? '/loginTotp'
              : '/loginTotpSetup';
          if (Get.currentRoute != rota) {
            Get.offAllNamed(
              rota,
              arguments: metodoEmail ? {'metodo': 'email'} : {'metodo': 'totp'},
            );
          }
          return;
        }

        final usuario = aplicarPerfil(perfil);
        _theme.definirPapelSessao(usuario.tipo);

        AppDestinoRota destino;

        switch (usuario.tipo) {
          case 'F':
            destino = await _sessaoFornecedor.resolverDestino(usuario.idUsuario);
            break;

          case 'C':
            destino =
                await _convite.resolverDestinoConvidado(usuario, token: token);
            break;

          case 'A':
            _theme.aplicarTemaProduto();
            _servicos.carregarServicosComDetalhesOtimizado();
            _validarDependenciasAdminDashboard?.call();
            destino = const AppDestinoRota('/admin');
            break;

          default:
            await _eventos.carregarEventosDoUsuario(usuario.idUsuario);
            final evento = _eventos.eventoAtualEntidade;

            if (evento != null) {
              debugPrint(
                  '🔹 Evento ativo: ${evento.nomeEvento} (${evento.idEvento})');
              _cotacoes.ouvirMinhasCotacoes();
              _validarDependenciasHomeEvent?.call();
              destino = const AppDestinoRota('/HomeEventScreen');
            } else {
              _contaIncompleta?.value = true;
              if (Get.currentRoute == '/welcome') {
                _carregando?.value = false;
                return;
              }
              destino = const AppDestinoRota('/welcome');
            }
            break;
        }

        _carregando?.value = false;
        final rotaDepois = Get.currentRoute;
        if (AppRotasSessao.destinoEstavel(rotaDepois) ||
            AppRotasSessao.usuarioJaNavegando(
              rotaDepois,
              temUsuario: _usuarioLogado?.value != null,
            )) {
          return;
        }
        Get.offAllNamed(destino.nome, arguments: destino.argumentos);
      } catch (e, s) {
        _carregando?.value = false;
        debugPrint('❌ Erro ao validar sessão: $e\n$s');
        Get.snackbar(
          'Erro de sessão',
          'Não foi possível validar sua conta. Tente novamente.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        Get.offAllNamed('/role');
      }
    } finally {
      _processandoSessao = false;
      if (_sessaoPendente) {
        _sessaoPendente = false;
        final idUsuario = _autenticacao.idUsuarioAtual;
        unawaited(processar(idUsuario == null
            ? null
            : SessaoUsuario(
                idUsuario: idUsuario,
                email: _autenticacao.emailUsuarioAtual,
              )));
      }
    }
  }

  Future<PerfilUsuario?> carregarPerfilComTentativas(String idUsuario) async {
    for (var tentativa = 1; tentativa <= 8; tentativa++) {
      final perfil = await _perfil.carregarPerfil(idUsuario);
      if (perfil != null) return perfil;

      debugPrint(
        '$_logTag Perfil $idUsuario ainda não disponível no Firestore. '
        'Tentativa $tentativa/8.',
      );
      await Future.delayed(const Duration(milliseconds: 350));
    }

    return null;
  }

  Usuario aplicarPerfil(PerfilUsuario perfil) {
    final usuario = perfil.usuario;
    final enderecos = perfil.enderecos;

    _enderecosUsuario?.assignAll(enderecos);
    if (enderecos.isEmpty) {
      _enderecoPrincipal?.value = null;
      _usuarioLogado?.value = usuario;
      _sincronizarUsuarioController?.call(usuario);
      return usuario;
    }

    final principal = enderecos.firstWhere(
      (endereco) => endereco.principal,
      orElse: () => enderecos.first,
    );
    _enderecoPrincipal?.value = principal;
    final usuarioComEndereco = usuario.copyWith(
      cidade: principal.nomeCidade,
      uf: principal.uf,
    );
    _usuarioLogado?.value = usuarioComEndereco;
    _sincronizarUsuarioController?.call(usuarioComEndereco);
    return usuarioComEndereco;
  }

  Future<void> encerrar({bool limparFornecedorAntes = false}) async {
    if (_encerrandoSessao?.value == true) return;
    _encerrandoSessao?.value = true;
    try {
      if (limparFornecedorAntes) {
        _fornecedor.logoutFornecedor();
      }

      await _sessaoSub?.cancel();
      _sessaoSub = null;

      await _pararEscutasDaSessao();
      await _registrarLogoutAuditoria();

      await _autenticacao.sair();
      _usuarioLogado?.value = null;
      _enderecoPrincipal?.value = null;
      _enderecosUsuario?.clear();
      _carrinho.limpar();
      _convite.limpar();
      _totp.limpar();
      _theme.definirPapelSessao(null);
      _theme.aplicarTemaProduto();
      Get.offAllNamed('/role');
      monitorar();
    } finally {
      _encerrandoSessao?.value = false;
    }
  }

  Future<void> _registrarLogoutAuditoria() async {
    try {
      final auditoria = _auditoria ?? _auditoriaResolver?.call();
      if (auditoria == null) return;

      final usuario = _usuarioLogado?.value;
      await auditoria.registrar(
        RegistroAuditoria(
          acao: 'LOGOUT_REALIZADO',
          resumo: 'Logout realizado pelo usuário.',
          entidadeTipo: 'sessao',
          entidadeId: _autenticacao.idUsuarioAtual,
          entidadeNome: usuario?.email ?? _autenticacao.emailUsuarioAtual,
          detalhe: {
            'tipo': usuario?.tipo,
            'email': usuario?.email ?? _autenticacao.emailUsuarioAtual,
          },
          rota: Get.currentRoute,
        ),
      );
    } catch (_) {
      // Auditoria de logout não pode impedir o encerramento da sessão.
    }
  }

  Future<void> _pararEscutasDaSessao() async {
    await _eventos.encerrarEscutas();
    await _orcamentos.encerrarEscutas();
    await _tarefas.encerrarEscutas();
    await _cotacoes.encerrarEscutas();
    _fornecedor.logoutFornecedor();
    await _sessaoFornecedor.encerrar();
    await _pararEscutasOpcionais?.call();
  }

  Future<void> cancelarEscuta() async {
    await _sessaoSub?.cancel();
    _sessaoSub = null;
  }
}
