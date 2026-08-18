import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'app_controller.dart';

class TotpMfaController extends GetxController {
  TotpMfaController({
    this.gerarQrNoInicio = false,
    FirebaseFunctions? functions,
  }) : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final bool gerarQrNoInicio;
  final FirebaseFunctions _functions;
  final AppController appController = Get.find<AppController>();

  final codigo = ''.obs;
  final secret = ''.obs;
  final otpauthUrl = ''.obs;
  final carregando = false.obs;
  final gerandoQr = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (gerarQrNoInicio) {
      iniciarCadastro();
    }
  }

  Future<void> iniciarCadastro() async {
    try {
      gerandoQr.value = true;
      final callable = _functions.httpsCallable('iniciarTotpMfa');
      final resultado = await callable.call();
      final data = Map<String, dynamic>.from(resultado.data as Map);
      secret.value = (data['secret'] ?? '').toString();
      otpauthUrl.value = (data['otpauthUrl'] ?? '').toString();
      if (secret.value.isEmpty || otpauthUrl.value.isEmpty) {
        _mostrarErro('Não foi possível gerar o autenticador. Tente novamente.');
      }
    } on FirebaseFunctionsException catch (e) {
      _mostrarErro(_traduzErro(e));
    } catch (_) {
      _mostrarErro('Não foi possível gerar o QR Code. Tente novamente.');
    } finally {
      gerandoQr.value = false;
    }
  }

  Future<void> confirmarCadastro() async {
    final codigoLimpo = _codigoLimpo();
    if (codigoLimpo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos do autenticador.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Confirmando autenticador...');
      final callable = _functions.httpsCallable('confirmarTotpMfa');
      await callable.call({'codigo': codigoLimpo});
      EasyLoading.dismiss();
      appController.marcarTotpVerificado();
      Get.offAllNamed('/splash');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e));
    } catch (_) {
      EasyLoading.dismiss();
      _mostrarErro('Não foi possível confirmar o código. Tente novamente.');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> verificarLogin() async {
    final codigoLimpo = _codigoLimpo();
    if (codigoLimpo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos do autenticador.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Validando código...');
      final callable = _functions.httpsCallable('verificarTotpMfa');
      await callable.call({'codigo': codigoLimpo});
      EasyLoading.dismiss();
      appController.marcarTotpVerificado();
      Get.offAllNamed('/splash');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      _mostrarErro(_traduzErro(e));
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

  String _traduzErro(FirebaseFunctionsException e) {
    final mensagem = e.message?.trim();
    if (mensagem != null && mensagem.isNotEmpty && e.code != 'internal') {
      return mensagem;
    }
    switch (e.code) {
      case 'unauthenticated':
        return 'Faça login para continuar.';
      case 'invalid-argument':
        return 'Informe o código de 6 dígitos.';
      case 'permission-denied':
        return 'Código incorreto.';
      case 'resource-exhausted':
        return 'Muitas tentativas. Aguarde e tente novamente.';
      case 'failed-precondition':
        return mensagem ?? 'Configure o autenticador para continuar.';
      default:
        return 'Não foi possível validar o autenticador.';
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
}
