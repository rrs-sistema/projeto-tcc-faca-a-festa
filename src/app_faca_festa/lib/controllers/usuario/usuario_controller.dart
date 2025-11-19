import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import './../../presentation/pages/endereco/endereco_section_controller.dart';
import './../../data/models/model.dart';
import 'endereco_usuario_controller.dart';

class UsuarioController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // LISTA DE USUÁRIOS (já existia)
  final usuarios = <UsuarioModel>[].obs;
  final usuariosFiltrados = <UsuarioModel>[].obs;

  // NOVOS CAMPOS NECESSÁRIOS
  final usuario = Rxn<UsuarioModel>(); // 🔹 Usuário logado
  final carregandoPerfil = false.obs;

  final carregando = false.obs;
  final buscaCtrl = TextEditingController();
  final novoUsuarioAdmin = false.obs;
  final senhaVisivel = false.obs;

  // CONTROLLER DE ENDEREÇO
  final enderecoUsuarioController = Get.put(EnderecoUsuarioController());
  final enderecoController = EnderecoSectionController().obs;

  @override
  void onInit() {
    super.onInit();
    carregarUsuarios();
    carregarUsuarioLogado();
  }

  // =============================================================
  // 🔹 CARREGA usuário logado a partir do Auth
  // =============================================================
  Future<void> carregarUsuarioLogado() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snap = await _db.collection('usuarios').doc(uid).get();
      if (!snap.exists) return;

      usuario.value = UsuarioModel.fromMap(snap.data()!);

      // 🔹 Carrega endereço principal
      await enderecoUsuarioController.carregarEnderecoPrincipal(uid);
    } catch (e) {
      debugPrint('❌ Erro ao carregar usuário logado: $e');
    }
  }

  // =============================================================
  // 🔹 ATUALIZAR PERFIL DO USUÁRIO
  // =============================================================
  Future<void> salvarPerfil({
    required String nome,
    required String cpf,
  }) async {
    try {
      carregandoPerfil.value = true;

      final uid = _auth.currentUser!.uid;

      await _db.collection('usuarios').doc(uid).update({
        'nome': nome,
        'cpf': cpf,
      });

      // Atualiza instância local
      usuario.value = usuario.value!.copyWith(
        nome: nome,
        cpf: cpf,
      );

      // Atualiza lista de usuários (para tela de admin)
      final idx = usuarios.indexWhere((u) => u.idUsuario == uid);
      if (idx != -1) {
        usuarios[idx] = usuarios[idx].copyWith(nome: nome, cpf: cpf);
        filtrarUsuarios(buscaCtrl.text);
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar perfil: $e');
      rethrow;
    } finally {
      carregandoPerfil.value = false;
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

  // =============================================================
  // 🔹 Trocar Foto de Perfil (Firebase Storage)
  // =============================================================
  Future<void> trocarFotoPerfil() async {
    try {
      final uid = _auth.currentUser!.uid;

      // Seleciona imagem
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);

      if (img == null) return;

      EasyLoading.show(status: 'Enviando foto...');

      final ext = img.name.split('.').last;

      final ref = FirebaseStorage.instance.ref().child('usuarios').child(uid).child('perfil.$ext');

      await ref.putFile(File(img.path));

      final url = await ref.getDownloadURL();

      // Atualiza Firestore
      await _db.collection('usuarios').doc(uid).update({
        'foto_perfil_url': url,
      });

      // Atualiza localmente
      usuario.value = usuario.value!.copyWith(fotoPerfilUrl: url);

      EasyLoading.showSuccess('Foto atualizada!');
    } catch (e) {
      debugPrint('❌ Erro ao trocar foto: $e');
      EasyLoading.showError("Falha ao trocar foto");
    }
  }

  // =============================================================
  // 🔹 MÉTODOS QUE JÁ EXISTIAM (mantidos exatamente como estavam)
  // =============================================================

  Future<void> carregarUsuarios() async {
    try {
      carregando.value = true;
      final snap = await _db.collection('usuarios').get();

      final lista = snap.docs.map((d) => UsuarioModel.fromMap(d.data())).toList();

      lista.sort((a, b) {
        final nomeComp = (a.nome.toLowerCase()).compareTo(b.nome.toLowerCase());
        if (nomeComp != 0) return nomeComp;

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

      final user = usuarios.firstWhereOrNull((u) => u.idUsuario == idUsuario);
      if (user != null) {
        final atualizado = user.copyWith(ativo: novoStatus);
        usuarios[usuarios.indexOf(user)] = atualizado;
        filtrarUsuarios(buscaCtrl.text);
      }

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

  // ... (todos os métodos de cadastro ficaram intocados)
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
