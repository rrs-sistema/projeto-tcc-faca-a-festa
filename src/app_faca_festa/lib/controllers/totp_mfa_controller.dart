import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../data/services/functions/callable_https_client.dart';
import 'app_controller.dart';

class TotpMfaController extends GetxController {
  TotpMfaController({
    this.gerarQrNoInicio = false,
    FirebaseFunctions? functions,
    CallableHttpsClient? httpsClient,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
        _httpsClient = httpsClient ?? CallableHttpsClient();

  final bool gerarQrNoInicio;
  final FirebaseFunctions _functions;
  final CallableHttpsClient _httpsClient;
  final AppController appController = Get.find<AppController>();

  static const etapaEscolha = 'escolha';
  static const etapaTotp = 'totp';
  static const etapaEmail = 'email';

  final etapa = etapaEscolha.obs;
  final metodoLogin = 'totp'.obs;
  final codigo = ''.obs;
  final secret = ''.obs;
  final otpauthUrl = ''.obs;
  final emailMascarado = ''.obs;
  final carregando = false.obs;
  final gerandoQr = false.obs;
  final enviandoEmail = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['metodo'] == 'email') {
      metodoLogin.value = etapaEmail;
      solicitarCodigoEmail();
      return;
    }
    if (gerarQrNoInicio) {
      escolherAutenticador();
    }
  }

  void escolherAutenticador() {
    etapa.value = etapaTotp;
    iniciarCadastro();
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
  }

  Future<void> iniciarCadastro() async {
    try {
      gerandoQr.value = true;
      final data = await _chamarFunction('iniciarTotpMfa');
      secret.value = (data['secret'] ?? '').toString();
      otpauthUrl.value = (data['otpauthUrl'] ?? '').toString();
      if (secret.value.isEmpty || otpauthUrl.value.isEmpty) {
        _mostrarErro('Não foi possível gerar o autenticador. Tente novamente.');
      }
    } on FirebaseFunctionsException catch (e) {
      _mostrarErro(_traduzErro(e.code, e.message));
    } on CallableHttpsException catch (e) {
      _mostrarErro(_traduzErro(e.code, e.message));
    } catch (_) {
      _mostrarErro('Não foi possível gerar o QR Code. Tente novamente.');
    } finally {
      gerandoQr.value = false;
    }
  }

  Future<void> solicitarCodigoEmail() async {
    try {
      enviandoEmail.value = true;
      EasyLoading.show(status: 'Enviando código...');
      final data = await _chamarFunction('solicitarCodigoEmailMfa');
      emailMascarado.value = (data['emailMascarado'] ?? '').toString();
      EasyLoading.dismiss();
      _mostrarSucesso(
        (data['message'] ?? 'Enviamos um código para o seu e-mail.').toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } on CallableHttpsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } catch (_) {
      EasyLoading.dismiss();
      _mostrarErro('Não foi possível enviar o código. Tente novamente.');
    } finally {
      enviandoEmail.value = false;
    }
  }

  Future<void> confirmarCadastro() async {
    if (etapa.value == etapaEmail) {
      await _confirmarEmail();
      return;
    }
    await _confirmarTotp();
  }

  Future<void> verificarLogin() async {
    if (metodoLogin.value == etapaEmail) {
      await _verificarEmail();
      return;
    }
    await _verificarTotp();
  }

  Future<void> _confirmarTotp() async {
    final codigoLimpo = _codigoLimpo();
    if (codigoLimpo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos do autenticador.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Confirmando autenticador...');
      await _chamarFunction('confirmarTotpMfa', {'codigo': codigoLimpo});
      EasyLoading.dismiss();
      appController.marcarTotpVerificado();
      Get.offAllNamed('/splash');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } on CallableHttpsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } catch (_) {
      EasyLoading.dismiss();
      _mostrarErro('Não foi possível confirmar o código. Tente novamente.');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _confirmarEmail() async {
    final codigoLimpo = _codigoLimpo();
    if (codigoLimpo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos enviado por e-mail.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Confirmando e-mail...');
      await _chamarFunction('confirmarEmailMfa', {'codigo': codigoLimpo});
      EasyLoading.dismiss();
      appController.marcarTotpVerificado();
      Get.offAllNamed('/splash');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } on CallableHttpsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } catch (_) {
      EasyLoading.dismiss();
      _mostrarErro('Não foi possível confirmar o código. Tente novamente.');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _verificarTotp() async {
    final codigoLimpo = _codigoLimpo();
    if (codigoLimpo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos do autenticador.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Validando código...');
      await _chamarFunction('verificarTotpMfa', {'codigo': codigoLimpo});
      EasyLoading.dismiss();
      appController.marcarTotpVerificado();
      Get.offAllNamed('/splash');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } on CallableHttpsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } catch (_) {
      EasyLoading.dismiss();
      _mostrarErro('Não foi possível validar o código. Tente novamente.');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _verificarEmail() async {
    final codigoLimpo = _codigoLimpo();
    if (codigoLimpo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos enviado por e-mail.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Validando código...');
      await _chamarFunction('verificarEmailMfa', {'codigo': codigoLimpo});
      EasyLoading.dismiss();
      appController.marcarTotpVerificado();
      Get.offAllNamed('/splash');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } on CallableHttpsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e.code, e.message));
    } catch (_) {
      EasyLoading.dismiss();
      _mostrarErro('Não foi possível validar o código. Tente novamente.');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> sair() async {
    await appController.logout();
  }

  String _codigoLimpo() => codigo.value.replaceAll(RegExp(r'\D'), '');

  Future<Map<String, dynamic>> _chamarFunction(
    String nome, [
    Map<String, dynamic>? data,
  ]) async {
    if (CallableHttpsClient.necessarioNaPlataformaAtual) {
      return _httpsClient.call(nome, data);
    }
    final callable = _functions.httpsCallable(nome);
    final resultado = await callable.call(data);
    final payload = resultado.data;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
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
