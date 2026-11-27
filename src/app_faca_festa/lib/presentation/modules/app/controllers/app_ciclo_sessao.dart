import 'dart:async';
import 'chat_notifications_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/data/local/convite_co_organizador_pendente.dart';
import 'package:app_faca_festa/app/routes/app_route_args.dart';
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
  bool _loginEmAndamento = false;
  bool _processandoSessao = false;
  Completer<void>? _sessaoPendente;
  bool _liberarSaidaSplash = false;
  DateTime? _splashAte;

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

  Future<void> processarLogin(Future<bool> Function() preparar) async {
    if (_loginEmAndamento) return;
    _loginEmAndamento = true;
    try {
      if (!await preparar()) return;
    } finally {
      _loginEmAndamento = false;
    }
    await revalidar();
  }

  void reterNaSplash({Duration minimo = const Duration(milliseconds: 4500)}) {
    _liberarSaidaSplash = false;
    _splashAte = DateTime.now().add(minimo);
  }

  bool _deveReterSplash() {
    final ate = _splashAte;
    if (ate != null && DateTime.now().isBefore(ate)) return true;
    if (_liberarSaidaSplash) return false;
    final rota = Get.currentRoute;
    return rota.isEmpty ||
        rota == '/' ||
        rota == '/splash' ||
        rota == '/notfound';
  }

  void iniciar() {
    _liberarSaidaSplash = true;
    _splashAte = null;
    if (_sessaoSub == null) {
      monitorar();
    }

    unawaited(revalidar());
  }

  Future<void> revalidar() {
    final idUsuario = _autenticacao.idUsuarioAtual;
    return processar(idUsuario == null
        ? null
        : SessaoUsuario(
            idUsuario: idUsuario,
            email: _autenticacao.emailUsuarioAtual,
          ));
  }

  // O Firebase pode emitir a sessão antes de o formulário preparar o perfil.
  bool _podeProcessar(SessaoUsuario? user) =>
      !_loginEmAndamento &&
      _encerrandoSessao?.value != true &&
      user?.idUsuario == _autenticacao.idUsuarioAtual;

  Future<void> processar(SessaoUsuario? user) async {
    if (!_podeProcessar(user)) return;
    if (_processandoSessao) {
      final pendente = _sessaoPendente ??= Completer<void>();
      debugPrint(
        '$_logTag Validação de sessão já em andamento. Nova tentativa será reprocessada.',
      );
      return pendente.future;
    }
    _processandoSessao = true;

    try {
      if (_deveReterSplash()) {
        debugPrint('$_logTag Splash ainda em tela; adiando navegação.');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      if (!_podeProcessar(user)) return;
      if (_deveReterSplash()) {
        debugPrint('$_logTag Splash ainda em tela; adiando navegação.');
        return;
      }
      final token = _convite.tokenConviteAtual();
      final visitaConvite = user != null &&
          (_autenticacao.sessaoAnonima || _autenticacao.sessaoVisitanteConvite);

      if (_convite.acessoPorLink.value && user != null && !visitaConvite) {
        _convite.acessoPorLink.value = false;
      }

      if (token != null &&
          token.isNotEmpty &&
          (user == null || visitaConvite)) {
        _abrirTelaConvite(token);
        return;
      }

      if (user == null) {
        _totp.limpar();
        _usuarioLogado?.value = null;
        _enderecoPrincipal?.value = null;
        _eventos.limparSessaoAtual();

        if (Get.currentRoute != '/role') Get.offAllNamed('/role');
        return;
      }

      if (visitaConvite) {
        debugPrint('$_logTag Sessão de convite sem token; voltando ao início.');
        if (!AppRotasSessao.ehConvite(Get.currentRoute) &&
            Get.currentRoute != '/role') {
          Get.offAllNamed('/role');
        }
        return;
      }

      _carregando?.value = true;

      try {
        final perfil = await carregarPerfilComTentativas(user.idUsuario);
        if (!_podeProcessar(user)) return;

        if (perfil == null) {
          throw Exception('Usuário não encontrado no Firestore.');
        }

        final usuarioTotp = perfil.usuario;
        if (usuarioTotp.ativo == false) {
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

        if (AppRotasSessao.ehTotp(Get.currentRoute) &&
            Get.isDialogOpen == true) {
          return;
        }

        if (_totp.deveExigir(usuarioTotp) &&
            await _autenticacao.sessaoMfaVerificada()) {
          if (!_podeProcessar(user)) return;
          _totp.marcarVerificado(user.idUsuario);
        }
        if (_totp.deveExigir(usuarioTotp)) {
          final totpAtivo = usuarioTotp.mfaTotpAtivo;
          final emailAtivo = usuarioTotp.mfaEmailAtivo;
          final temMetodo = totpAtivo || emailAtivo;
          final rota = temMetodo ? '/loginTotp' : '/loginTotpSetup';
          final rotaAtual = Get.currentRoute;
          if (rotaAtual != rota) {
            Get.offAllNamed(
              rota,
              arguments: temMetodo
                  ? TotpMfaArgs(
                      metodo: totpAtivo ? 'totp' : 'email',
                      totpAtivo: totpAtivo,
                      emailAtivo: emailAtivo,
                    )
                  : null,
            );
          }
          return;
        }

        final usuario = aplicarPerfil(perfil);
        if (Get.isRegistered<ChatNotificationsController>()) {
          unawaited(Get.find<ChatNotificationsController>().iniciar(usuario));
        }
        _theme.definirPapelSessao(usuario.tipo);

        AppDestinoRota destino;

        switch (usuario.tipo) {
          case 'F':
            destino =
                await _sessaoFornecedor.resolverDestino(usuario.idUsuario);
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
            final temEventoGerido = _eventos.temEventoGerido;
            final tokenCoOrg = TokenConviteCoOrganizador.ler();

            // Convite de co-organizador pendente tem prioridade sobre /welcome.
            if (tokenCoOrg != null && tokenCoOrg.isNotEmpty) {
              destino = AppDestinoRota(
                TokenConviteCoOrganizador.rotaAceite(tokenCoOrg),
              );
            } else if (temEventoGerido) {
              // Dono ou co-organizador: Home (lista unida já resolvida).
              if (evento != null) {
                debugPrint(
                  '🔹 Evento ativo: ${evento.nomeEvento} (${evento.idEvento})'
                  '${evento.ehCoOrganizador(usuario.idUsuario) ? ' [co-org]' : ''}',
                );
              } else {
                debugPrint(
                  '🔹 Eventos geridos: ${_eventos.eventosGeridos.length} '
                  '(seleção pendente).',
                );
              }
              _contaIncompleta?.value = false;
              _cotacoes.ouvirMinhasCotacoes();
              _validarDependenciasHomeEvent?.call();
              destino = const AppDestinoRota('/HomeEventScreen');
            } else {
              _contaIncompleta?.value = true;
              destino = const AppDestinoRota('/welcome');
            }
            break;
        }

        if (!_podeProcessar(user)) return;
        final rotaDepois = Get.currentRoute;

        // /welcome é provisório: se já há evento gerido (ex.: co-org que
        // chegou após a 1ª emissão), sobe para a Home em vez de ficar preso.
        if (rotaDepois == '/welcome' &&
            destino.nome == '/HomeEventScreen' &&
            _eventos.temEventoGerido) {
          Get.offAllNamed(destino.nome, arguments: destino.argumentos);
          return;
        }

        if (AppRotasSessao.destinoEstavel(rotaDepois) ||
            AppRotasSessao.usuarioJaNavegando(
              rotaDepois,
              temUsuario: _usuarioLogado?.value != null,
            )) {
          return;
        }
        Get.offAllNamed(destino.nome, arguments: destino.argumentos);
      } catch (e, s) {
        if (!_podeProcessar(user)) return;
        debugPrint('❌ Erro ao validar sessão: $e\n$s');
        final semInternet = ConectividadeService.offlineAgora;
        Get.snackbar(
          semInternet ? 'Sem internet' : 'Erro de sessão',
          semInternet
              ? 'Seus dados ainda não estão neste aparelho. Conecte-se uma vez para usar sem internet depois.'
              : 'Não foi possível validar sua conta. Tente novamente.',
          backgroundColor: semInternet ? const Color(0xFF37474F) : Colors.redAccent,
          colorText: Colors.white,
        );
        Get.offAllNamed('/role');
      } finally {
        _carregando?.value = false;
      }
    } finally {
      _processandoSessao = false;
      if (_usuarioLogado?.value != null &&
          Get.isRegistered<ChatNotificationsController>()) {
        Get.find<ChatNotificationsController>().abrirPendente();
      }
      final pendente = _sessaoPendente;
      if (pendente != null) {
        _sessaoPendente = null;
        pendente.complete(revalidar());
      }
    }
  }

  void _abrirTelaConvite(String token) {
    _convite.guardarTokenConvite(token);
    final rotaAtual = Get.currentRoute;
    if (AppRotasSessao.ehConvite(rotaAtual) &&
        rotaAtual != '/conviteNaoEncontrado') {
      debugPrint('$_logTag Convite já em tela: $rotaAtual');
      return;
    }

    final rota = ConviteLink.rotaConvite(token);
    debugPrint('$_logTag Abrindo tela do convite: $rota');
    Get.offAllNamed(rota);
  }

  Future<PerfilUsuario?> carregarPerfilComTentativas(String idUsuario) async {
    for (var tentativa = 1; tentativa <= 8; tentativa++) {
      final perfil = await _perfil.carregarPerfil(idUsuario);
      if (perfil != null) return perfil;
      // As tentativas esperam o cadastro chegar ao servidor; offline o
      // cache não vai mudar.
      if (ConectividadeService.offlineAgora) return null;

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

    final principal = enderecoPrincipalOuPrimeiro(enderecos);
    _enderecoPrincipal?.value = principal;
    final usuarioComEndereco = usuario.copyWith(
      cidade: principal.nomeCidade,
      uf: principal.uf,
    );
    _usuarioLogado?.value = usuarioComEndereco;
    _sincronizarUsuarioController?.call(usuarioComEndereco);
    return usuarioComEndereco;
  }

  /// Encerra a sessão. Se [preservarTokenConvite] vier preenchido, o link de
  /// convidado sobrevive ao logout (conta de fornecedor/organizador não se
  /// mistura com o convite) e a navegação reabre `/convite/:token`.
  Future<void> encerrar({
    bool limparFornecedorAntes = false,
    String? preservarTokenConvite,
  }) async {
    if (_encerrandoSessao?.value == true) return;
    _encerrandoSessao?.value = true;
    final iniciadoEm = DateTime.now();
    final tokenPreservar = (preservarTokenConvite ?? '').trim();
    try {
      await _sessaoSub?.cancel();
      _sessaoSub = null;

      // Escutas e catálogo não podem prender a navegação.
      unawaited(_pararEscutasDaSessao(
        limparFornecedorAntes: limparFornecedorAntes,
      ));

      // A callable de auditoria exige o token atual, mas logout não
      // deve esperar cold start / rede lenta da function.
      await _registrarLogoutAuditoria().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('$_logTag Auditoria de logout excedeu 2s; seguindo.');
        },
      );

      if (Get.isRegistered<ChatNotificationsController>()) {
        await Get.find<ChatNotificationsController>().encerrar();
      }
      await _autenticacao.sair();
      _usuarioLogado?.value = null;
      _enderecoPrincipal?.value = null;
      _enderecosUsuario?.clear();
      _carrinho.limpar();
      _convite.limpar();
      if (tokenPreservar.isNotEmpty) {
        _convite.guardarTokenConvite(tokenPreservar);
      }
      _totp.limpar();
      _theme.definirPapelSessao(null);
      _theme.aplicarTemaProduto();
      if (tokenPreservar.isNotEmpty) {
        Get.offAllNamed(ConviteLink.rotaConvite(tokenPreservar));
      } else {
        Get.offAllNamed('/role');
      }
      monitorar();
    } finally {
      _encerrandoSessao?.value = false;
      debugPrint(
        '$_logTag Sessão encerrada em '
        '${DateTime.now().difference(iniciadoEm).inMilliseconds}ms.',
      );
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
          detalhe: AuditoriaDetalhe(
            tipo: usuario?.tipo,
            email: usuario?.email ?? _autenticacao.emailUsuarioAtual,
          ),
          rota: Get.currentRoute,
        ),
      );
    } catch (_) {
      // Auditoria de logout não pode impedir o encerramento da sessão.
    }
  }

  Future<void> _pararEscutasDaSessao({
    bool limparFornecedorAntes = false,
  }) async {
    try {
      if (limparFornecedorAntes) {
        await _fornecedor.logoutFornecedor();
      }
      await _eventos.encerrarEscutas();
      await _orcamentos.encerrarEscutas();
      await _tarefas.encerrarEscutas();
      await _cotacoes.encerrarEscutas();
      if (!limparFornecedorAntes) {
        await _fornecedor.logoutFornecedor();
      }
      await _sessaoFornecedor.encerrar();
      await _pararEscutasOpcionais?.call();
    } catch (erro, stack) {
      debugPrint('$_logTag Falha ao parar escutas no logout: $erro\n$stack');
    }
  }

  Future<void> cancelarEscuta() async {
    await _sessaoSub?.cancel();
    _sessaoSub = null;
  }
}
