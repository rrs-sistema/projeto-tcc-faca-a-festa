import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import './../../presentation/pages/endereco/endereco_section_controller.dart';
import './../../data/models/model.dart';

class UsuarioController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final usuarios = <UsuarioModel>[].obs;
  final usuariosFiltrados = <UsuarioModel>[].obs;
  final carregando = false.obs;
  final buscaCtrl = TextEditingController();
  final novoUsuarioAdmin = false.obs;
  final senhaVisivel = false.obs;

  final enderecoController = EnderecoSectionController().obs;

  @override
  void onInit() {
    super.onInit();
    carregarUsuarios();
  }

  Future<void> carregarUsuarios() async {
    try {
      carregando.value = true;
      final snap = await _db.collection('usuarios').get();

      // 🔹 Converte documentos em modelos
      final lista = snap.docs.map((d) => UsuarioModel.fromMap(d.data())).toList();

      // 🔹 Ordena primeiro por nome (A-Z), depois por tipo (A, C, F, O)
      lista.sort((a, b) {
        // 1️⃣ Comparação por nome
        final nomeComp = (a.nome.toLowerCase()).compareTo(b.nome.toLowerCase());
        if (nomeComp != 0) return nomeComp;

        // 2️⃣ Comparação por tipo, se os nomes forem iguais
        final tipoA = a.tipo ?? '';
        final tipoB = b.tipo ?? '';
        return tipoA.compareTo(tipoB);
      });

      usuarios.value = lista;
      usuariosFiltrados.assignAll(lista);
    } catch (e) {
      debugPrint('❌ Erro ao carregar usuários: $e');
    } finally {
      carregando.value = false;
    }
  }

  void filtrarUsuarios(String termo) {
    if (termo.isEmpty) {
      usuariosFiltrados.assignAll(usuarios);
    } else {
      usuariosFiltrados.assignAll(
        usuarios.where((u) =>
            u.nome.toLowerCase().contains(termo.toLowerCase()) ||
            u.email.toLowerCase().contains(termo.toLowerCase())),
      );
    }
  }

  Future<void> tornarAdmin(String idUsuario) async {
    await _db.collection('usuarios').doc(idUsuario).update({'tipo': 'A'});
    final user = usuarios.firstWhereOrNull((u) => u.idUsuario == idUsuario);
    if (user != null) {
      usuarios[usuarios.indexOf(user)] = user.copyWith(isAdmin: true);
      filtrarUsuarios(buscaCtrl.text);
    }
    Get.snackbar('Sucesso', 'Usuário promovido a administrador',
        backgroundColor: Colors.teal.shade600, colorText: Colors.white);
  }

  Future<void> removerAdmin(String idUsuario) async {
    await _db.collection('usuarios').doc(idUsuario).update({'tipo': 'A'});
    final user = usuarios.firstWhereOrNull((u) => u.idUsuario == idUsuario);
    if (user != null) {
      usuarios[usuarios.indexOf(user)] = user.copyWith(isAdmin: false);
      filtrarUsuarios(buscaCtrl.text);
    }
    Get.snackbar('Alteração salva', 'Usuário deixou de ser administrador',
        backgroundColor: Colors.orange.shade700, colorText: Colors.white);
  }

  Future<void> toggleAtivo(String idUsuario, bool novoStatus) async {
    try {
      await _db.collection('usuarios').doc(idUsuario).update({'ativo': novoStatus});

      // Atualiza localmente a lista reativa
      final user = usuarios.firstWhereOrNull((u) => u.idUsuario == idUsuario);
      if (user != null) {
        final atualizado = user.copyWith(ativo: novoStatus);
        usuarios[usuarios.indexOf(user)] = atualizado;
        filtrarUsuarios(buscaCtrl.text);
      }

      // Feedback visual
      if (novoStatus) {
        Get.snackbar(
          'Usuário reativado',
          'O usuário foi marcado como ativo novamente.',
          backgroundColor: Colors.green.shade700,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Usuário desativado',
          'O usuário foi desativado com sucesso.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao alterar status do usuário $idUsuario: $e');
      Get.snackbar(
        'Erro',
        'Falha ao alterar o status do usuário.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  Future<void> salvarNovoUsuario(UsuarioModel usuario) async {
    try {
      // Cria usuário Firebase Auth
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: usuario.email.trim(),
        password: usuario.senhaHash ?? '123456',
      );

      final uid = credencial.user!.uid;
      final endereco = enderecoController.value.toModel(uid);

      final novo = usuario.copyWith(
          idUsuario: uid, cidade: endereco.nomeCidade, uf: endereco.uf, senhaHash: null);
      await _db.collection('usuarios').doc(uid).set(novo.toMap());
      // 🔹 Subcoleção de endereços
      await _db
          .collection('usuarios')
          .doc(uid)
          .collection('enderecos')
          .doc(endereco.id)
          .set(endereco.toMap());

      usuarios.add(novo);
      filtrarUsuarios(buscaCtrl.text);
      Get.snackbar('Sucesso', 'Usuário cadastrado com sucesso!',
          backgroundColor: Colors.green.shade700, colorText: Colors.white);
    } on FirebaseAuthException catch (e) {
      EasyLoading.showError(_traduzErro(e.code));
    } catch (e) {
      Get.snackbar('Erro', 'Falha ao cadastrar usuário: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  /// 🔹 Salva endereço na subcoleção `usuario/{id}/enderecos`
  Future<void> salvarEnderecoUsuario(String idUsuario, Map<String, dynamic> endereco) async {
    try {
      await _db.collection('usuarios').doc(idUsuario).collection('enderecos').add(endereco);

      Get.snackbar('Endereço salvo', 'Endereço cadastrado com sucesso na subcoleção!',
          backgroundColor: Colors.teal.shade600, colorText: Colors.white);
    } catch (e) {
      debugPrint('❌ Erro ao salvar endereço: $e');
      Get.snackbar('Erro', 'Falha ao salvar o endereço',
          backgroundColor: Colors.red.shade700, colorText: Colors.white);
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
