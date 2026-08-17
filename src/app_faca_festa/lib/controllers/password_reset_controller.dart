import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class PasswordResetController extends GetxController {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final email = ''.obs;
  final codigo = ''.obs;
  final novaSenha = ''.obs;
  final confirmarSenha = ''.obs;
  final etapa = 0.obs;
  final carregando = false.obs;
  final exibirSenha = false.obs;

  Future<void> solicitarCodigo() async {
    final emailLimpo = email.value.trim().toLowerCase();
    if (!_emailValido(emailLimpo)) {
      _mostrarErro('Digite um e-mail válido.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Enviando código...');
      final callable =
          _functions.httpsCallable('solicitarCodigoRedefinicaoSenha');
      await callable.call({'email': emailLimpo});
      EasyLoading.dismiss();
      etapa.value = 1;
      _mostrarSucesso('Enviamos um código para o e-mail informado.');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      debugPrint(
          '[PasswordResetController] solicitarCodigo: ${e.code} | ${e.message}');
      _mostrarErro(_traduzErroSolicitarCodigo(e));
    } catch (e, s) {
      EasyLoading.dismiss();
      debugPrint('[PasswordResetController] solicitarCodigo erro: $e');
      debugPrint('$s');
      _mostrarErro('Não foi possível enviar o código. Tente novamente.');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> redefinirSenha() async {
    final emailLimpo = email.value.trim().toLowerCase();
    final codigoLimpo = codigo.value.replaceAll(RegExp(r'\D'), '');
    final senhaLimpa = novaSenha.value.trim();
    final confirmacaoLimpa = confirmarSenha.value.trim();

    if (!_emailValido(emailLimpo)) {
      _mostrarErro('Digite um e-mail válido.');
      return;
    }

    if (codigoLimpo.length != 6) {
      _mostrarErro('Informe o código de 6 dígitos.');
      return;
    }

    if (senhaLimpa.length < 6) {
      _mostrarErro('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }

    if (senhaLimpa != confirmacaoLimpa) {
      _mostrarErro('As senhas não conferem.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Redefinindo senha...');
      final callable = _functions.httpsCallable('redefinirSenhaComCodigo');
      await callable.call({
        'email': emailLimpo,
        'codigo': codigoLimpo,
        'novaSenha': senhaLimpa,
      });
      EasyLoading.dismiss();
      etapa.value = 2;
      _mostrarSucesso('Senha redefinida com sucesso.');
    } on FirebaseFunctionsException catch (e) {
      EasyLoading.dismiss();
      debugPrint(
          '[PasswordResetController] redefinirSenha: ${e.code} | ${e.message}');
      _mostrarErro(_traduzErroFunctions(e));
    } catch (e, s) {
      EasyLoading.dismiss();
      debugPrint('[PasswordResetController] redefinirSenha erro: $e');
      debugPrint('$s');
      _mostrarErro('Não foi possível redefinir a senha. Tente novamente.');
    } finally {
      carregando.value = false;
    }
  }

  void voltarEtapaEmail() {
    etapa.value = 0;
    codigo.value = '';
    novaSenha.value = '';
    confirmarSenha.value = '';
  }

  bool _emailValido(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _traduzErroFunctions(FirebaseFunctionsException e) {
    final mensagem = e.message?.trim();
    if (mensagem != null && mensagem.isNotEmpty) return mensagem;

    switch (e.code) {
      case 'invalid-argument':
        return 'Confira os dados informados.';
      case 'not-found':
        return 'Serviço de redefinição de senha não publicado no Firebase.';
      case 'failed-precondition':
        return 'Solicite um novo código.';
      case 'deadline-exceeded':
        return 'Código expirado. Solicite um novo código.';
      case 'resource-exhausted':
        return 'Muitas tentativas. Solicite um novo código.';
      case 'permission-denied':
        return 'Código incorreto.';
      default:
        return 'Não foi possível concluir a solicitação.';
    }
  }

  String _traduzErroSolicitarCodigo(FirebaseFunctionsException e) {
    final mensagem = e.message?.trim();
    if (mensagem != null && mensagem.isNotEmpty && e.code != 'not-found') {
      return mensagem;
    }

    if (e.code == 'not-found') {
      return 'Serviço de redefinição de senha não publicado no Firebase.';
    }

    return _traduzErroFunctions(e);
  }

  void _mostrarErro(String mensagem) {
    EasyLoading.showError(mensagem);
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
      duration: const Duration(seconds: 4),
    );
  }
}
