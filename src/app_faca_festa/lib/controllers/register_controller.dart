import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:br_validators/br_validators.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../presentation/pages/endereco/endereco_section_controller.dart';
import '../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../data/models/servico_produto/subcategoria_servico_model.dart';
import '../data/models/servico_produto/categoria_servico_model.dart';
import './../data/models/model.dart';
import 'app_controller.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AppController appController = Get.find<AppController>();
  // 🔹 Categorias e subcategorias selecionadas
  RxList<FornecedorCategoriaModel> categoriasSelecionadas = <FornecedorCategoriaModel>[].obs;

  // 🆕 Controle reativo de seleção de serviços
  //final RxSet<String> servicosSelecionados = <String>{}.obs;
  RxList<ServicoProdutoModel> servicosSelecionados = <ServicoProdutoModel>[].obs;

  // 🔹 Mapa de subcategorias organizadas por categoria
  final RxMap<String, List<SubcategoriaServicoModel>> subcategoriasPorCategoria =
      <String, List<SubcategoriaServicoModel>>{}.obs;

// 🆕 Nova lista de subcategorias selecionadas
  final RxList<SubcategoriaServicoModel> subcategoriasSelecionadas =
      <SubcategoriaServicoModel>[].obs;

  var nome = ''.obs;
  var razaoSocial = ''.obs;
  var email = ''.obs;
  var senha = ''.obs;
  var cnpj = ''.obs;
  var telefone = ''.obs;
  var categoriaSelecionada = ''.obs;
  var subcategoriaSelecionada = ''.obs;
  String? bannerUrl;

  var carregando = false.obs;
  RxBool exibirSenha = false.obs;

  final enderecoController = EnderecoSectionController().obs;

  Future<void> registrarUsuario() async {
    EnderecoUsuarioModel endereco = enderecoController.value.toModel('');
    if (!_validarCamposFornecedor()) return;

    try {
      carregando.value = true;
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: senha.value.trim(),
      );

      final uid = credencial.user!.uid;

      endereco = endereco.copyWith(idUsuario: uid);
      final tipo = (Get.arguments?['tipo'] ?? 'O') as String;

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
        final novoFornecedor = FornecedorModel(
          idFornecedor: uid,
          idUsuario: uid,
          razaoSocial: razaoSocial.value,
          telefone: telefone.value,
          email: email.value,
          aptoParaOperar: false,
          ativo: true,
          bannerUrl: bannerUrl,
          cnpj: cnpj.value,
          descricao: '',
          dataCadastro: DateTime.now(),
        );

        await _db.collection('fornecedor').doc(uid).set(novoFornecedor.toMap());

        for (final cat in categoriasSelecionadas) {
          final catUpdate = cat.copyWith(idFornecedor: uid);
          await _db.collection('fornecedor_categoria').add(catUpdate.toMap());
        }
        for (final serv in servicosSelecionados) {
          FornecedorProdutoServicoModel model = FornecedorProdutoServicoModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            idProdutoServico: serv.id,
            idFornecedor: uid,
            preco: 0.0,
            dataCadastro: DateTime.now(),
            ativo: true,
            idSubcategoria: serv.idSubcategoria,
            precoPromocao: 0.0,
          );
          final vinculoId = '${model.idFornecedor}_${model.idProdutoServico}';
          await _db.collection('fornecedor_servico').doc(vinculoId).set(model.toMap());
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
    categoriasSelecionadas.refresh();
  }

  /// 🔹 Alterna o estado de seleção de um serviço
  void alternarServico(ServicoProdutoModel servico, bool selecionado) {
    if (selecionado) {
      servicosSelecionados.add(servico);
    } else {
      servicosSelecionados.remove(servico);
    }
    servicosSelecionados.refresh();
  }

// 🔹 Carrega todas as subcategorias de uma categoria
  Future<void> carregarSubcategoriasPorCategoria(String idCategoria) async {
    try {
      carregando.value = true;
      final snap = await _db
          .collection('subcategoria_servico')
          .where('id_categoria', isEqualTo: idCategoria)
          .get();

      final lista = snap.docs
          .map((doc) => SubcategoriaServicoModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      subcategoriasPorCategoria[idCategoria] = lista;
    } catch (e) {
      debugPrint('⚠️ Erro ao carregar subcategorias: $e');
    } finally {
      carregando.value = false;
    }
  }

  /// 🆕 Limpa subcategorias de uma categoria específica
  void limparSubcategorias(String idCategoria) {
    subcategoriasPorCategoria.remove(idCategoria);
  }

  /// 🆕 Limpa todas as subcategorias
  void limparTudo() {
    subcategoriasPorCategoria.clear();
  }

  bool _validarCamposFornecedor() {
    final tipo = (Get.arguments?['tipo'] ?? 'O') as String;

    // ------------------------------
    // 🔹 Validações comuns
    // ------------------------------
    if (nome.value.trim().isEmpty) {
      _showError('Informe seu nome completo');
      return false;
    }

    if (!EmailValidator.validate(email.value.trim())) {
      _showError('Digite um e-mail válido (ex: contato@email.com)');
      return false;
    }

    if (senha.value.trim().length < 6) {
      _showError('A senha deve ter pelo menos 6 caracteres');
      return false;
    }

    // ------------------------------
    // 🔹 Validações específicas para Fornecedor
    // ------------------------------
    if (tipo == 'F') {
      if (razaoSocial.value.trim().isEmpty) {
        _showError('Informe a razão social da sua empresa');
        return false;
      }

      if (telefone.value.trim().length < 8) {
        _showError('Informe um telefone de contato válido');
        return false;
      }

      if (cnpj.value.trim().isEmpty) {
        _showError('Informe o CNPJ da sua empresa');
        return false;
      }

      if (!BRValidators.validateCNPJ(cnpj.value.trim())) {
        _showError('CNPJ inválido. Verifique e tente novamente.');
        return false;
      }

      if (categoriasSelecionadas.isEmpty) {
        _showError('Selecione pelo menos uma categoria de atuação');
        return false;
      }

      if (servicosSelecionados.isEmpty) {
        _showError('Selecione pelo menos um serviço oferecido');
        return false;
      }
    }

    // ------------------------------
    // 🔹 Endereço
    // ------------------------------
    final endereco = enderecoController.value.toModel('');
    if (endereco.cep.isEmpty) {
      _showError('Informe o CEP');
      return false;
    }
    if (endereco.logradouro.isEmpty) {
      _showError('Informe o endereço completo');
      return false;
    }
    if (endereco.numero.isEmpty) {
      _showError('Informe o número do enredeço');
      return false;
    }
    if (endereco.bairro == null || endereco.bairro!.isEmpty) {
      _showError('Informe o bairro');
      return false;
    }
    if (endereco.uf == null || endereco.uf!.isEmpty) {
      _showError('Informe o estado (UF)');
      return false;
    }
    if (endereco.nomeCidade == null || endereco.nomeCidade!.isEmpty) {
      _showError('Informe a cidade');
      return false;
    }

    return true;
  }

  /// 🔹 Exibe mensagens elegantes de erro
  void _showError(String mensagem) {
    Get.snackbar(
      'Verificação necessária',
      mensagem,
      backgroundColor: Colors.red.shade600.withValues(alpha: 0.95),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 12,
      icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
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
