import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../data/models/servico_produto/categoria_servico_model.dart';
import '../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../data/models/servico_produto/subcategoria_servico_model.dart';
import './../presentation/pages/endereco/endereco_section_controller.dart';
import './../data/models/model.dart';
import 'app_controller.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppController appController = Get.find<AppController>();
  // 🔹 Categorias e subcategorias selecionadas
  RxList<FornecedorCategoriaModel> categoriasSelecionadas = <FornecedorCategoriaModel>[].obs;

  var nome = ''.obs;
  var email = ''.obs;
  var senha = ''.obs;
  var cnpj = ''.obs;
  var telefone = ''.obs;
  var categoriaSelecionada = ''.obs;
  var subcategoriaSelecionada = ''.obs;

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

      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: senha.value.trim(),
      );

      final uid = credencial.user!.uid;
      final tipo = (Get.arguments?['tipo'] ?? 'O') as String;

      final endereco = enderecoController.value.toModel(uid);

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
      await _db
          .collection('usuarios')
          .doc(uid)
          .collection('enderecos')
          .doc(endereco.id)
          .set(endereco.toMap());

      if (tipo == 'F') {
        // 🔹 Cria fornecedor com categorias
        final novoFornecedor = FornecedorModel(
          idFornecedor: uid,
          idUsuario: uid,
          razaoSocial: nome.value,
          telefone: telefone.value,
          email: email.value,
          aptoParaOperar: false,
          ativo: true,
          bannerUrl: null,
          cnpj: cnpj.value,
          descricao: '',
          dataCadastro: DateTime.now(),
        );

        await _db.collection('fornecedor').doc(uid).set(novoFornecedor.toMap());

        for (final cat in categoriasSelecionadas) {
          final catUpdate = cat.copyWith(idFornecedor: uid);
          await _db.collection('fornecedor_categoria').add(catUpdate.toMap());
        }
      } else if (tipo == 'C') {
        Get.offAllNamed('/convidadosPage');
      } else {
        Get.offAllNamed('/welcome');
      }

      Get.snackbar('Sucesso', 'Usuário cadastrado com sucesso!',
          backgroundColor: Colors.green.shade700, colorText: Colors.white);
    } on FirebaseAuthException catch (e) {
      EasyLoading.showError(_traduzErro(e.code));
    } catch (e) {
      EasyLoading.showError('Erro ao salvar: $e');
    } finally {
      carregando.value = false;
    }
  }

  void adicionarCategoria(CategoriaServicoModel cat) {
    categoriasSelecionadas.add(
      FornecedorCategoriaModel(
        idFornecedor: '',
        idCategoria: cat.id,
        nomeCategoria: cat.nome,
      ),
    );
  }

  void alternarSubcategoria(
      FornecedorCategoriaModel catSel, SubcategoriaServicoModel sub, bool selected) {
    final index = categoriasSelecionadas.indexWhere((c) => c.idCategoria == catSel.idCategoria);
    if (index == -1) return;

    final atual = categoriasSelecionadas[index];
    final subcats = List<Map<String, dynamic>>.from((atual as dynamic).subcategorias ?? []);

    if (selected) {
      subcats.add({
        'idSubcategoria': sub.id,
        'nomeSubcategoria': sub.nome,
      });
    } else {
      subcats.removeWhere((s) => s['idSubcategoria'] == sub.id);
    }

    categoriasSelecionadas[index] =
        atual.copyWith(subcategorias: subcats.cast<Map<String, dynamic>>());
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
