import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../domain/entities/usuario.dart';
import '../domain/repositories/autenticacao_repository.dart';
import '../domain/repositories/perfil_usuario_repository.dart';

class LoginController extends GetxController {
  final AutenticacaoRepository _autenticacaoRepository =
      Get.find<AutenticacaoRepository>();
  final PerfilUsuarioRepository _perfilRepository =
      Get.find<PerfilUsuarioRepository>();

  var email = ''.obs;
  var senha = ''.obs;
  var carregando = false.obs;

  Future<void> login() async {
    if (email.value.isEmpty || senha.value.isEmpty) {
      EasyLoading.showError('Preencha todos os campos');
      return;
    }

    try {
      carregando.value = true;
      await _autenticacaoRepository.entrar(
        email: email.value.trim(),
        senha: senha.value.trim(),
      );

      await _garantirPerfilDoUsuario();
      Get.offAllNamed('/welcome');
    } on AutenticacaoException catch (e) {
      EasyLoading.showError(_traduzErro(e.codigo));
    } finally {
      carregando.value = false;
    }
  }

  Future<void> loginComGoogle() async {
    try {
      carregando.value = true;
      await _autenticacaoRepository.entrarComGoogle();
      await _garantirPerfilDoUsuario();
      Get.offAllNamed('/welcome');
    } on AutenticacaoException catch (e) {
      EasyLoading.showError(_traduzErro(e.codigo));
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _garantirPerfilDoUsuario() async {
    final idUsuario = _autenticacaoRepository.idUsuarioAtual;
    if (idUsuario == null) return;

    final usuario = await _perfilRepository.buscarUsuario(idUsuario);
    if (usuario != null) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final nome = firebaseUser?.displayName?.trim() ?? '';
    final email = _autenticacaoRepository.emailUsuarioAtual ?? '';

    if (nome.isNotEmpty) {
      await _perfilRepository.salvarUsuario(
        Usuario(
          idUsuario: idUsuario,
          nome: nome,
          email: email,
          tipo: 'O',
          fotoPerfilUrl: firebaseUser?.photoURL,
          ativo: true,
          dataCadastro: DateTime.now(),
        ),
      );
      return;
    }

    await _perfilRepository.criarUsuarioAutomatico(
      idUsuario: idUsuario,
      email: _autenticacaoRepository.emailUsuarioAtual,
    );
  }

  String _traduzErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-email':
        return 'Email inválido';
      case 'account-exists-with-different-credential':
        return 'Este e-mail já está cadastrado com outro método de login';
      case 'canceled':
        return 'Login com Google cancelado';
      case 'interrupted':
        return 'O Google interrompeu o login. Tente novamente.';
      case 'clientConfigurationError':
      case 'providerConfigurationError':
        return 'Google não configurado corretamente no Firebase';
      case 'google-token-not-found':
      case 'google-sign-in-unsupported':
      case 'google-unexpected-error':
        return 'Login com Google indisponível neste dispositivo';
      default:
        return 'Erro ao fazer login. Tente novamente.';
    }
  }
}
