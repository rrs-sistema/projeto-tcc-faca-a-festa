import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import './../presentation/pages/endereco/endereco_section_controller.dart';
import './../data/models/model.dart';
import 'app_controller.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppController appController = Get.find<AppController>();

  var nome = ''.obs;
  var email = ''.obs;
  var senha = ''.obs;
  var carregando = false.obs;
  RxBool exibirSenha = false.obs;

  final enderecoController = EnderecoSectionController().obs;

  Future<void> registrarUsuario() async {
    if (nome.value.isEmpty || email.value.isEmpty || senha.value.isEmpty) {
      EasyLoading.showError('Preencha todos os campos');
      return;
    }

    try {
      carregando.value = true;

      // Cria usuário Firebase Auth
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: senha.value.trim(),
      );

      final uid = credencial.user!.uid;
      final tipo = (Get.arguments?['tipo'] ?? 'O') as String;

      // 📍 Monta endereço principal
      final endereco = enderecoController.value.toModel(uid);

      // Salva usuário principal
      final novoUsuario = UsuarioModel(
        idUsuario: uid,
        nome: nome.value,
        email: email.value,
        tipo: tipo,
        ativo: true,
        cidade: endereco.nomeCidade,
        uf: endereco.uf,
        dataCadastro: DateTime.now(),
      );

      await _db.collection('usuarios').doc(uid).set(novoUsuario.toMap());

      // 🔹 Subcoleção de endereços
      await _db
          .collection('usuarios')
          .doc(uid)
          .collection('enderecos')
          .doc(endereco.id)
          .set(endereco.toMap());

      // 🔹 Salvar endereço adicional futuramente:
      // await _db.collection('usuarios').doc(uid)
      //   .collection('enderecos').add(EnderecoUsuarioModel(...).toMap());

      EasyLoading.showSuccess('Usuário e endereço salvos com sucesso');

      // 🚀 Redireciona conforme tipo
      if (tipo == 'F') {
        Get.offAllNamed('/fornecedor_home');
      }
      if (tipo == 'C') {
        Get.offAllNamed('/convidadosPage');
      } else {
        Get.offAllNamed('/welcome');
      }
    } on FirebaseAuthException catch (e) {
      EasyLoading.showError(_traduzErro(e.code));
    } catch (e) {
      EasyLoading.showError('Erro ao salvar: $e');
    } finally {
      carregando.value = false;
    }
  }

  String _traduzErro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado';
      case 'invalid-email':
        return 'E-mail inválido';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres';
      default:
        return 'Erro ao criar conta. Tente novamente.';
    }
  }
}
