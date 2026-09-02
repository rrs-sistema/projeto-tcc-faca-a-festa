import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/core/utils/form_validators.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';

class PasswordResetController extends GetxController {
  PasswordResetController({
    AutenticacaoRepository? autenticacaoRepository,
  }) : _autenticacaoRepository =
            autenticacaoRepository ?? Get.find<AutenticacaoRepository>();

  final AutenticacaoRepository _autenticacaoRepository;

  final email = ''.obs;
  final codigo = ''.obs;
  final novaSenha = ''.obs;
  final confirmarSenha = ''.obs;
  final etapa = 0.obs;
  final carregando = false.obs;
  final exibirSenha = false.obs;

  Future<void> solicitarCodigo() async {
    final emailLimpo = email.value.trim().toLowerCase();
    final erroEmail = FormValidators.email(emailLimpo);
    if (erroEmail != null) {
      _mostrarErro(erroEmail);
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Enviando código...');
      await _autenticacaoRepository.solicitarCodigoRedefinicaoSenha(
        email: emailLimpo,
      );
      EasyLoading.dismiss();
      etapa.value = 1;
      _mostrarSucesso('Enviamos um código para o e-mail informado.');
    } on AutenticacaoException catch (e) {
      EasyLoading.dismiss();
      debugPrint(
          '[PasswordResetController] solicitarCodigo: ${e.codigo} | ${e.mensagem}');
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

    final erroEmail = FormValidators.email(emailLimpo);
    if (erroEmail != null) {
      _mostrarErro(erroEmail);
      return;
    }

    final erroCodigo = FormValidators.codigoVerificacao(codigoLimpo);
    if (erroCodigo != null) {
      _mostrarErro(erroCodigo);
      return;
    }

    final erroSenha = FormValidators.senha(senhaLimpa);
    if (erroSenha != null) {
      _mostrarErro(erroSenha);
      return;
    }

    final erroConfirmacao = FormValidators.confirmarSenha(
      confirmacaoLimpa,
      senha: senhaLimpa,
    );
    if (erroConfirmacao != null) {
      _mostrarErro(erroConfirmacao);
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Redefinindo senha...');
      await _autenticacaoRepository.redefinirSenhaComCodigo(
        email: emailLimpo,
        codigo: codigoLimpo,
        novaSenha: senhaLimpa,
      );
      EasyLoading.dismiss();
      etapa.value = 2;
      _mostrarSucesso('Senha redefinida com sucesso.');
    } on AutenticacaoException catch (e) {
      EasyLoading.dismiss();
      debugPrint(
          '[PasswordResetController] redefinirSenha: ${e.codigo} | ${e.mensagem}');
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

  String _traduzErroFunctions(AutenticacaoException e) {
    final mensagem = e.mensagem?.trim();
    if (mensagem != null && mensagem.isNotEmpty) return mensagem;

    switch (e.codigo) {
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

  String _traduzErroSolicitarCodigo(AutenticacaoException e) {
    final mensagem = e.mensagem?.trim();
    if (mensagem != null && mensagem.isNotEmpty && e.codigo != 'not-found') {
      return mensagem;
    }

    if (e.codigo == 'not-found') {
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
