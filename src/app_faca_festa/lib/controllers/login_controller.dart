import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      await _auth.signInWithEmailAndPassword(
        email: email.value.trim(),
        password: senha.value.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

        if (doc.exists) {
          // final dados = doc.data()!;
          // Preenche temporariamente
          // final usuario = UsuarioModel.fromMap(dados);
          // pode armazenar localmente ou passar como parâmetro
        } else {
          await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
            'idUsuario': user.uid,
            'email': user.email,
            'criadoAutomaticamente': true,
          });
        }
      }
      Get.offAllNamed('/welcome');
    } on FirebaseAuthException catch (e) {
      EasyLoading.showError(_traduzErro(e.code));
    } finally {
      carregando.value = false;
    }
  }

  String _traduzErro(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Senha incorreta';
      case 'invalid-email':
        return 'Email inválido';
      default:
        return 'Erro ao fazer login. Tente novamente.';
    }
  }
}
