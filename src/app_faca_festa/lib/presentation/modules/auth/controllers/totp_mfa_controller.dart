import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/app/routes/app_route_args.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/mfa_opcoes_dialog.dart';

class TotpMfaController extends GetxController {
  TotpMfaController({
    this.gerarQrNoInicio = false,
    required AutenticacaoRepository autenticacaoRepository,
    required this.appController,
  }) : _autenticacaoRepository = autenticacaoRepository;

  final bool gerarQrNoInicio;
  final AutenticacaoRepository _autenticacaoRepository;
  final AppController appController;

  static const etapaEscolha = 'escolha';
  static const etapaTotp = 'totp';
  static const etapaEmail = 'email';
  static const etapaRecuperacao = 'recuperacao';

  final etapa = etapaEscolha.obs;
  final metodoLogin = 'totp'.obs;
  final codigo = ''.obs;
  final secret = ''.obs;
  final otpauthUrl = ''.obs;
  final emailMascarado = ''.obs;
  final carregando = false.obs;
  final gerandoQr = false.obs;
  final falhouQr = false.obs;
  final enviandoEmail = false.obs;
  final gerenciarAoConfirmar = false.obs;
  bool emailAtivo = false;
  bool totpAtivo = false;
  bool _metodosCarregados = false;
  bool _gerandoQrPedido = false;

  @override
  void onInit() {
    super.onInit();
    final args = TotpMfaArgs.maybeOf(Get.arguments);
    if (args != null) {
      _metodosCarregados = true;
      emailAtivo = args.emailAtivo || args.ehEmail;
      totpAtivo = args.totpAtivo || !args.ehEmail;
      if (args.ehEmail) {
        unawaited(trocarMetodoLogin(etapaEmail));
      }
      return;
    }
    if (gerarQrNoInicio) {
      escolherAutenticador();
    }
  }

  Future<void> carregarMetodosDoDesafio() async {
    if (_metodosCarregados) return;
    final uid = _autenticacaoRepository.idUsuarioAtual;
    if (uid == null) return;
    carregando.value = true;
    try {
      final perfil = await appController.obterUsuario(uid);
      if (perfil == null ||
          isClosed ||
          uid != _autenticacaoRepository.idUsuarioAtual) {
        return;
      }
      _metodosCarregados = true;
      emailAtivo = perfil.mfaEmailAtivo;
      totpAtivo = perfil.mfaTotpAtivo;
      if (emailAtivo && !totpAtivo) {
        metodoLogin.value = etapaEmail;
        unawaited(solicitarCodigoEmail(silencioso: true));
      }
    } catch (_) {
      _mostrarErro('Não foi possível carregar seus métodos de verificação.');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> trocarMetodoLogin(String metodo) async {
    if (carregando.value || metodoLogin.value == metodo) return;
    codigo.value = '';
    metodoLogin.value = metodo;
    if (metodo == etapaEmail) await solicitarCodigoEmail(silencioso: true);
  }

  void escolherAutenticador() {
    gerandoQr.value = true;
    falhouQr.value = false;
    etapa.value = etapaTotp;
    unawaited(iniciarCadastro());
  }

  Future<void> escolherEmail() async {
    etapa.value = etapaEmail;
    await solicitarCodigoEmail();
  }

  void voltarEscolha() {
    etapa.value = etapaEscolha;
    codigo.value = '';
    secret.value = '';
    otpauthUrl.value = '';
    gerandoQr.value = false;
    falhouQr.value = false;
  }

  Future<void> iniciarCadastro() async {
    if (_gerandoQrPedido) return;
    _gerandoQrPedido = true;
    try {
      gerandoQr.value = true;
      falhouQr.value = false;
      final data = await _autenticacaoRepository.iniciarTotpMfa().timeout(
            const Duration(seconds: 25),
          );
      secret.value = data.secret;
      otpauthUrl.value = data.otpauthUrl;
      if (secret.value.isEmpty || otpauthUrl.value.isEmpty) {
        falhouQr.value = true;
        _mostrarErro('Não foi possível gerar o autenticador. Tente novamente.');
      }
    } on TimeoutException {
      falhouQr.value = true;
      _mostrarErro('A geração do QR demorou demais. Tente novamente.');
    } on AutenticacaoException catch (e) {
      falhouQr.value = true;
      _mostrarErro(
        e.codigo == 'deadline-exceeded'
            ? 'A geração do QR demorou demais. Tente novamente.'
            : _traduzErroQr(e.codigo, e.mensagem),
      );
    } catch (_) {
      falhouQr.value = true;
      _mostrarErro('Não foi possível gerar o QR Code. Tente novamente.');
    } finally {
      _gerandoQrPedido = false;
      gerandoQr.value = false;
    }
  }

  Future<void> solicitarCodigoEmail({bool silencioso = false}) async {
    if (enviandoEmail.value) return;
    try {
      enviandoEmail.value = true;
      if (!silencioso) {
        EasyLoading.show(status: 'Enviando código...');
      }
      final data = await _autenticacaoRepository.solicitarCodigoEmailMfa();
      emailMascarado.value = data.emailMascarado;
      if (!silencioso) {
        EasyLoading.dismiss();
        _mostrarSucesso(
          data.mensagem.isEmpty
              ? 'Enviamos um código para o seu e-mail.'
              : data.mensagem,
        );
      }
    } on AutenticacaoException catch (e) {
      if (!silencioso) EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.codigo, e.mensagem));
    } catch (_) {
      if (!silencioso) EasyLoading.dismiss();
      _mostrarErro('Não foi possível enviar o código. Tente novamente.');
    } finally {
      enviandoEmail.value = false;
    }
  }

  Future<void> confirmarCadastro() {
    final porEmail = etapa.value == etapaEmail;
    return _validarCodigo(
      validar: porEmail
          ? _autenticacaoRepository.confirmarEmailMfa
          : _autenticacaoRepository.confirmarTotpMfa,
      porEmail: porEmail,
      status:
          porEmail ? 'Confirmando e-mail...' : 'Confirmando autenticador...',
      mensagemFalha: 'Não foi possível confirmar o código. Tente novamente.',
      cadastrar: true,
    );
  }

  Future<void> verificarLogin() {
    final porEmail = metodoLogin.value == etapaEmail;
    final recuperacao = metodoLogin.value == etapaRecuperacao;
    return _validarCodigo(
      validar: recuperacao
          ? _autenticacaoRepository.verificarCodigoRecuperacaoMfa
          : porEmail
              ? _autenticacaoRepository.verificarEmailMfa
              : _autenticacaoRepository.verificarTotpMfa,
      porEmail: porEmail,
      recuperacao: recuperacao,
      status: 'Validando código...',
      mensagemFalha: 'Não foi possível validar o código. Tente novamente.',
    );
  }

  Future<void> _validarCodigo({
    required Future<String> Function(String) validar,
    required bool porEmail,
    required String status,
    required String mensagemFalha,
    bool cadastrar = false,
    bool recuperacao = false,
  }) async {
    if (carregando.value) return;
    final codigoLimpo = recuperacao ? codigo.value.trim() : _codigoLimpo();
    if (recuperacao
        ? !RegExp(r'^[a-fA-F0-9]{32}$')
            .hasMatch(codigoLimpo.replaceAll('-', ''))
        : codigoLimpo.length != 6) {
      _mostrarErro(recuperacao
          ? 'Informe um código de recuperação completo.'
          : porEmail
              ? 'Informe o código de 6 dígitos enviado por e-mail.'
              : 'Informe o código de 6 dígitos do autenticador.');
      return;
    }

    try {
      carregando.value = true;
      final idUsuario = _autenticacaoRepository.idUsuarioAtual;
      final solicitouOpcoes = recuperacao || gerenciarAoConfirmar.value;
      EasyLoading.show(status: status);
      final autorizacao = (await validar(codigoLimpo)).trim();
      if (isClosed || _autenticacaoRepository.idUsuarioAtual != idUsuario) {
        return;
      }
      if (solicitouOpcoes || (cadastrar && autorizacao.isNotEmpty)) {
        await EasyLoading.dismiss();
        await Get.dialog<void>(
          MfaOpcoesDialog(
            autenticacao: _autenticacaoRepository,
            autorizacao: autorizacao,
            emailAtivo: emailAtivo || porEmail,
            totpAtivo: totpAtivo || (cadastrar && !porEmail),
          ),
          barrierDismissible: false,
        );
      }
      await appController.concluirMfa(idUsuario);
    } on AutenticacaoException catch (e) {
      _mostrarErro(_traduzErro(e.codigo, e.mensagem));
    } catch (_) {
      _mostrarErro(mensagemFalha);
    } finally {
      EasyLoading.dismiss();
      carregando.value = false;
    }
  }

  Future<void> sair() async {
    await appController.logout();
  }

  String _codigoLimpo() => codigo.value.replaceAll(RegExp(r'\D'), '');

  String _traduzErroQr(String code, String? message) {
    final mensagem = message?.trim();
    if (mensagem != null && mensagem.isNotEmpty && code != 'internal') {
      return mensagem;
    }
    switch (code) {
      case 'unauthenticated':
        return 'Faça login para continuar.';
      case 'failed-precondition':
        return mensagem ?? 'Autenticador ainda não configurado no servidor.';
      default:
        return 'Não foi possível gerar o QR Code. Tente novamente.';
    }
  }

  String _traduzErro(String code, String? message) {
    final mensagem = message?.trim();
    if (mensagem != null && mensagem.isNotEmpty && code != 'internal') {
      return mensagem;
    }
    switch (code) {
      case 'unauthenticated':
        return 'Faça login para continuar.';
      case 'invalid-argument':
        return 'Informe o código de 6 dígitos.';
      case 'permission-denied':
        return 'Código incorreto.';
      case 'resource-exhausted':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      case 'deadline-exceeded':
        return 'Código expirado. Solicite um novo código.';
      case 'failed-precondition':
        return mensagem ?? 'Configure a verificação para continuar.';
      default:
        return 'Não foi possível validar o código.';
    }
  }

  void _mostrarErro(String mensagem) {
    Get.rawSnackbar(
      title: 'Atenção',
      message: mensagem,
      titleText: const Text(
        'Atenção',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      messageText: Text(
        mensagem,
        style: const TextStyle(color: Colors.white),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade700,
      margin: const EdgeInsets.all(14),
      borderRadius: 12,
      duration: const Duration(seconds: 4),
    );
  }

  void _mostrarSucesso(String mensagem) {
    Get.rawSnackbar(
      title: 'Tudo certo',
      message: mensagem,
      titleText: const Text(
        'Tudo certo',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      messageText: Text(
        mensagem,
        style: const TextStyle(color: Colors.white),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade700,
      margin: const EdgeInsets.all(14),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }
}
