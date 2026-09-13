import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/convite_link.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/convite_convidado_repository.dart';
import 'package:app_faca_festa/domain/services/abrir_convite_por_token.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_destino_rota.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';

class AppConviteController extends GetxController {
  AppConviteController({
    required AutenticacaoRepository autenticacao,
    required AbrirConvitePorToken abrirConvitePorToken,
    required ConviteConvidadoRepository convites,
    required EventoController eventos,
    required EventThemeController theme,
    required ConvidadoController convidados,
  })  : _autenticacao = autenticacao,
        _abrirConvitePorToken = abrirConvitePorToken,
        _convites = convites,
        _eventos = eventos,
        _theme = theme,
        _convidados = convidados;

  static const String _logTag = '[AppConvite]';

  final AutenticacaoRepository _autenticacao;
  final AbrirConvitePorToken _abrirConvitePorToken;
  final ConviteConvidadoRepository _convites;
  final EventoController _eventos;
  final EventThemeController _theme;
  final ConvidadoController _convidados;

  Future<Usuario?> Function(String id)? _obterUsuario;
  RxBool? _carregando;

  bool conviteProcessado = false;
  String conviteTokenProcessado = '';
  final RxString conviteToken = ''.obs;
  final RxBool acessoPorLink = false.obs;

  void vincular({
    required Future<Usuario?> Function(String id) obterUsuario,
    required RxBool carregando,
  }) {
    _obterUsuario = obterUsuario;
    _carregando = carregando;
  }

  void _setCarregando(bool value) {
    _carregando?.value = value;
  }

  String? obterTokenConvite() => ConviteLink.tokenDaUrl();

  /// Token do link `/convite/:token` (URL ou memória). Credencial do convidado.
  String? tokenConviteAtual() => _tokenConviteAtual();

  /// Há convite pendente: o login/cadastro Google deve criar tipo C, não O.
  bool get fluxoConviteAtivo {
    final token = _tokenConviteAtual();
    return token != null && token.isNotEmpty;
  }

  void guardarTokenConvite(String token) {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return;
    conviteToken.value = tokenLimpo;
  }

  void capturarTokenInicial() {
    final token = obterTokenConvite();
    if (token != null && token.isNotEmpty) {
      conviteToken.value = token;
      debugPrint('$_logTag Token de convite capturado no onInit: $token');
    }
  }

  void limpar() {
    conviteProcessado = false;
    conviteTokenProcessado = '';
    conviteToken.value = '';
    acessoPorLink.value = false;
  }

  String? _tokenConviteAtual() {
    final tokenUrl = obterTokenConvite();
    if (tokenUrl != null && tokenUrl.isNotEmpty) {
      conviteToken.value = tokenUrl;
      return tokenUrl;
    }

    final tokenMemoria = conviteToken.value.trim();
    return tokenMemoria.isEmpty ? null : tokenMemoria;
  }

  /// Abre o convite. Sem conta real, entra como visitante (auth anônimo).
  /// Conta tipo C vincula o token ao UID. Outros papéis são recusados.
  Future<void> abrirConvite(String token) async {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return;

    conviteToken.value = tokenLimpo;
    conviteProcessado = false;
    conviteTokenProcessado = '';

    final idUsuario = _autenticacao.idUsuarioAtual;
    final anonimo = _autenticacao.sessaoAnonima;

    if (idUsuario != null && !anonimo) {
      final usuario = await _obterUsuario?.call(idUsuario);
      if (usuario == null) {
        await _abrirConviteComoVisitante(tokenLimpo);
        return;
      }

      if (usuario.tipo != 'C') {
        Get.snackbar(
          'Convite de convidado',
          'Este link deve ser acessado por uma conta de convidado.',
          backgroundColor: Colors.orange.shade600,
          colorText: Colors.white,
        );
        return;
      }

      acessoPorLink.value = false;
      await redirecionarConvidadoAposLogin(usuario, token: tokenLimpo);
      return;
    }

    await _abrirConviteComoVisitante(tokenLimpo);
  }

  Future<void> _abrirConviteComoVisitante(String token) async {
    acessoPorLink.value = true;
    try {
      if (_autenticacao.idUsuarioAtual == null) {
        await _autenticacao.entrarAnonimamente();
      }

      final resultado = await _abrirConvitePorToken.abrir(token);
      final convidado = resultado.convidado;
      final evento = resultado.evento;

      _eventos.eventoAtual.value = evento;
      await _eventos.buscarTipoEvento(evento.idTipoEvento);
      await _theme.aplicarParaEvento(
        evento,
        fallbackNomeTipo: _eventos.tipoEventoAtualEntidade?.nome,
      );

      conviteProcessado = true;
      conviteTokenProcessado = token;
      _convidados.convidadoAtual.value = convidado;

      Get.offAllNamed(
        '/areaconvidado',
        arguments: {
          'convidado': convidado,
          'evento': evento,
        },
      );
    } on AutenticacaoException catch (e) {
      acessoPorLink.value = false;
      debugPrint('$_logTag Auth ao abrir convite: ${e.codigo}');
      Get.snackbar(
        'Convite',
        e.codigo == 'operation-not-allowed' ||
                e.codigo == 'admin-restricted-operation'
            ? 'Acesso pelo link está temporariamente indisponível.'
            : 'Não foi possível abrir o convite. Tente novamente.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      Get.offAllNamed('/conviteNaoEncontrado');
    } catch (e, s) {
      acessoPorLink.value = false;
      debugPrint('$_logTag Erro ao abrir convite como visitante: $e\n$s');
      Get.offAllNamed('/conviteNaoEncontrado');
    }
  }

  /// Usado também pelo cadastro: depois de criar uma conta do tipo convidado,
  /// vincula convites pendentes pelo token e/ou pelo e-mail do usuário.
  Future<void> redirecionarConvidadoAposLogin(
    Usuario usuario, {
    String? token,
  }) async {
    _setCarregando(true);
    try {
      final destino = await resolverDestinoConvidado(usuario, token: token);
      _setCarregando(false);
      Get.offAllNamed(destino.nome, arguments: destino.argumentos);
    } catch (e, s) {
      _setCarregando(false);
      debugPrint('$_logTag Erro ao redirecionar convidado: $e\n$s');
      Get.offAllNamed('/conviteNaoEncontrado');
    }
  }

  Future<AppDestinoRota> resolverDestinoConvidado(
    Usuario usuario, {
    String? token,
  }) async {
    final tokenLimpo = (token ?? _tokenConviteAtual() ?? '').trim();
    final email = usuario.email.trim();

    debugPrint(
      '$_logTag Resolvendo destino do convidado | uid=${usuario.idUsuario} | '
      "email=$email | token=${tokenLimpo.isEmpty ? 'sem token' : tokenLimpo}",
    );

    Convidado? convidado;

    if (tokenLimpo.isNotEmpty && conviteTokenProcessado != tokenLimpo) {
      convidado = await _vincularConvitePorToken(
        token: tokenLimpo,
        uid: usuario.idUsuario,
        email: email,
      );
      conviteProcessado = convidado != null;
      if (convidado != null) conviteTokenProcessado = tokenLimpo;
    }

    convidado ??= await _buscarOuVincularConvitePorUsuario(
      uid: usuario.idUsuario,
      email: email,
    );

    if (convidado == null) {
      debugPrint('$_logTag Nenhum convite encontrado para ${usuario.email}.');
      return const AppDestinoRota('/conviteNaoEncontrado');
    }

    final evento = await _eventos.buscarEventoPeloIdEvento(convidado.idEvento);
    if (evento == null) {
      debugPrint(
        '$_logTag Convite encontrado, mas evento não existe: ${convidado.idEvento}.',
      );
      return const AppDestinoRota('/conviteNaoEncontrado');
    }

    _eventos.eventoAtual.value = evento;
    await _eventos.buscarTipoEvento(evento.idTipoEvento);
    await _theme.aplicarParaEvento(
      evento,
      fallbackNomeTipo: _eventos.tipoEventoAtualEntidade?.nome,
    );

    return AppDestinoRota(
      '/areaconvidado',
      {
        'convidado': convidado,
        'evento': evento,
      },
    );
  }

  Future<Convidado?> _vincularConvitePorToken({
    required String token,
    required String uid,
    required String email,
  }) async {
    try {
      return await _convites.vincularPorToken(
        token: token,
        uid: uid,
        email: email,
      );
    } on ConviteJaVinculadoException {
      _mostrarConviteJaVinculado();
      return null;
    } catch (e, s) {
      debugPrint('$_logTag Erro ao vincular convite por token: $e\n$s');
      return null;
    }
  }

  Future<Convidado?> _buscarOuVincularConvitePorUsuario({
    required String uid,
    required String email,
  }) async {
    try {
      return await _convites.buscarOuVincularPorUsuario(
        uid: uid,
        email: email,
      );
    } on ConviteJaVinculadoException {
      _mostrarConviteJaVinculado();
      return null;
    } catch (e, s) {
      debugPrint(
        '$_logTag Erro ao buscar/vincular convite por usuário: $e\n$s',
      );
      return null;
    }
  }

  void _mostrarConviteJaVinculado() {
    Get.snackbar(
      'Convite já vinculado',
      'Este convite já está associado a outra conta.',
      backgroundColor: Colors.orange.shade600,
      colorText: Colors.white,
    );
  }
}
