import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:email_validator/email_validator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:br_validators/br_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../domain/repositories/autenticacao_repository.dart';
import './../presentation/pages/endereco/endereco_section_controller.dart';
import '../data/models/servico_produto/fornecedor_categoria_model.dart';
import '../data/models/servico_produto/subcategoria_servico_model.dart';
import '../data/models/servico_produto/categoria_servico_model.dart';
import './../data/models/model.dart';
import 'app_controller.dart';

class RegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AutenticacaoRepository _autenticacaoRepository =
      Get.find<AutenticacaoRepository>();
  final AppController appController = Get.find<AppController>();

  static const String _logTag = '[RegisterController]';
  static const String _versaoDiagnostico =
      'v2026-06-16-convidado-sem-endereco-vinculo-convite';

  // 🔹 Categorias e subcategorias selecionadas
  RxList<FornecedorCategoriaModel> categoriasSelecionadas =
      <FornecedorCategoriaModel>[].obs;

  // 🆕 Controle reativo de seleção de serviços
  //final RxSet<String> servicosSelecionados = <String>{}.obs;
  RxList<ServicoProdutoModel> servicosSelecionados =
      <ServicoProdutoModel>[].obs;

  // 🔹 Mapa de subcategorias organizadas por categoria
  final RxMap<String, List<SubcategoriaServicoModel>>
      subcategoriasPorCategoria =
      <String, List<SubcategoriaServicoModel>>{}.obs;

  // 🆕 Nova lista de subcategorias selecionadas
  final RxList<SubcategoriaServicoModel> subcategoriasSelecionadas =
      <SubcategoriaServicoModel>[].obs;

  // 🧠 IA de recomendação: tipos de evento que este fornecedor atende
  final RxList<String> tipoEventoIds = <String>[].obs;
  final RxList<String> tipoEventoSlugs = <String>[].obs;
  final RxList<String> tipoEventoNomes = <String>[].obs;

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

  /// Permite que a tela force o cadastro como convidado quando o tipo não vier
  /// corretamente em Get.arguments.
  ///
  /// Exemplo na tela de cadastro do convidado:
  /// controller.configurarCadastroComoConvidado(true);
  final cadastroConvidadoManual = false.obs;

  @override
  void onInit() {
    super.onInit();
    _log(
        'onInit $_versaoDiagnostico | route=${Get.currentRoute} | args=${Get.arguments}');
    _log(
        'tipoCadastroInicial=$tipoCadastroAtual | cadastroComoConvidado=$cadastroComoConvidado');
  }

  /// Tipo esperado hoje:
  /// O = Organizador
  /// F = Fornecedor
  /// C = Convidado
  String get tipoCadastroAtual {
    final args = Get.arguments;
    final rawTipo = args is Map ? args['tipo'] : null;
    final tipo = (rawTipo ?? 'O').toString().trim().toUpperCase();

    if (tipo.isEmpty) return 'O';
    return tipo;
  }

  bool get cadastroComoFornecedor => tipoCadastroAtual == 'F';

  bool get cadastroComoConvidado {
    final manual = cadastroConvidadoManual.value;
    final porTipo = tipoCadastroAtual == 'C';
    final porArgumentos = _argumentsIndicamConvidado(Get.arguments);
    final porRota = _normalizeTexto(Get.currentRoute).contains('convidado');

    final resultado = manual || porTipo || porArgumentos || porRota;

    _log(
      'cadastroComoConvidado => $resultado | '
      'manual=$manual | porTipo=$porTipo | tipo=$tipoCadastroAtual | '
      'porArgumentos=$porArgumentos | porRota=$porRota | route=${Get.currentRoute} | args=${Get.arguments}',
    );

    return resultado;
  }

  /// Organizador e fornecedor precisam informar endereço.
  /// Convidado não precisa informar endereço.
  bool get enderecoObrigatorio => !cadastroComoConvidado;

  void configurarCadastroComoConvidado(bool value) {
    cadastroConvidadoManual.value = value;
    _log('configurarCadastroComoConvidado($value)');
  }

  Future<void> registrarUsuario() async {
    if (carregando.value) return;
    _log('===== INÍCIO registrarUsuario $_versaoDiagnostico =====');
    _log('route=${Get.currentRoute} | args=${Get.arguments}');

    final tipo = tipoCadastroAtual;
    final cadastroConvidado = cadastroComoConvidado;

    // Se a tela/argumentos indicarem cadastro de convidado, o tipo efetivo deve
    // ser C mesmo que Get.arguments['tipo'] não tenha vindo corretamente.
    final tipoEfetivo = cadastroConvidado ? 'C' : tipo;
    final tokenConvite = _tokenConviteEntrada();

    final enderecoAntesDoUid = enderecoController.value.toModel('');
    final enderecoFoiInformado =
        _enderecoTemAlgumCampoPreenchido(enderecoAntesDoUid);
    final deveSalvarEndereco = !cadastroConvidado || enderecoFoiInformado;

    _log(
      'Decisão inicial: tipo=$tipo | tipoEfetivo=$tipoEfetivo | cadastroConvidado=$cadastroConvidado | '
      'enderecoObrigatorio=$enderecoObrigatorio | enderecoFoiInformado=$enderecoFoiInformado | '
      "deveSalvarEndereco=$deveSalvarEndereco | tokenConvite=${tokenConvite ?? 'sem token'}",
    );
    _logEndereco(enderecoAntesDoUid,
        origem: 'registrarUsuario antes da validação');

    if (!_validarCamposCadastro()) {
      _log('BLOQUEADO: _validarCamposCadastro retornou false.');
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Criando cadastro...');
      appController.marcarLoginComSenha();

      final credencial = await _auth.createUserWithEmailAndPassword(
        email: email.value.trim(),
        password: senha.value.trim(),
      );

      final uid = credencial.user!.uid;
      final endereco = enderecoAntesDoUid.copyWith(idUsuario: uid);

      _log(
          'Usuário criado no FirebaseAuth: uid=$uid | tipo=$tipo | tipoEfetivo=$tipoEfetivo');
      _logEndereco(endereco, origem: 'registrarUsuario após uid');

      final novoUsuario = UsuarioModel(
        idUsuario: uid,
        nome: nome.value.trim(),
        email: email.value.trim(),
        tipo: tipoEfetivo,
        ativo: true,
        cidade: _texto(endereco.nomeCidade),
        uf: _texto(endereco.uf),
        dataCadastro: DateTime.now(),
      );

      final usuarioMap = novoUsuario.toMap();
      usuarioMap['email_normalizado'] = _normalizarEmail(email.value);
      usuarioMap['tipo'] = tipoEfetivo;

      await _db.collection('usuarios').doc(uid).set(usuarioMap);
      _log('Documento usuarios/$uid salvo com tipo=$tipoEfetivo.');

      if (deveSalvarEndereco) {
        await _db
            .collection('usuarios')
            .doc(uid)
            .collection('enderecos')
            .doc(endereco.id)
            .set(endereco.toMap());
        _log('Endereço salvo em usuarios/$uid/enderecos/${endereco.id}.');
      } else {
        _log(
            'Endereço não salvo: cadastro de convidado sem endereço informado.');
      }

      if (tipoEfetivo == 'F') {
        final novoFornecedor = FornecedorModel(
          idFornecedor: uid,
          idUsuario: uid,
          razaoSocial: razaoSocial.value.trim(),
          telefone: telefone.value.trim(),
          email: email.value.trim(),
          aptoParaOperar: false,
          ativo: true,
          bannerUrl: bannerUrl,
          cnpj: cnpj.value.trim(),
          descricao: '',
          dataCadastro: DateTime.now(),
          tipoEventoIds: tipoEventoIds.toList(growable: false),
          tipoEventoSlugs: tipoEventoSlugs.toList(growable: false),
          tipoEventoNomes: tipoEventoNomes.toList(growable: false),
        );

        await _db.collection('fornecedor').doc(uid).set(novoFornecedor.toMap());
        _log('Documento fornecedor/$uid salvo.');

        for (final cat in categoriasSelecionadas) {
          final catUpdate = cat.copyWith(idFornecedor: uid);
          await _db.collection('fornecedor_categoria').add(catUpdate.toMap());
        }
        _log(
            'Categorias vinculadas ao fornecedor: ${categoriasSelecionadas.length}.');

        for (final serv in servicosSelecionados) {
          final model = FornecedorProdutoServicoModel(
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
          await _db
              .collection('fornecedor_servico')
              .doc(vinculoId)
              .set(model.toMap());
        }
        _log(
            'Serviços vinculados ao fornecedor: ${servicosSelecionados.length}.');
      }

      Get.snackbar(
        'Sucesso',
        'Usuário cadastrado com sucesso!',
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );

      EasyLoading.dismiss();
      _log('Navegando para /splash para autenticador TOTP e roteamento.');
      Get.offAllNamed('/splash');
    } on FirebaseAuthException catch (e) {
      _log('FirebaseAuthException: code=${e.code} | message=${e.message}');
      _showError(_traduzErro(e.code));
    } catch (e, s) {
      _log('Erro ao salvar: $e');
      _log('StackTrace: $s');
      _showError('Erro ao salvar cadastro. Tente novamente.');
    } finally {
      EasyLoading.dismiss();
      carregando.value = false;
      _log('===== FIM registrarUsuario =====');
    }
  }

  Future<void> registrarComGoogle() async {
    if (carregando.value) return;
    final tipo = tipoCadastroAtual;
    final cadastroConvidado = cadastroComoConvidado;
    final tipoEfetivo = cadastroConvidado ? 'C' : tipo;
    final tokenConvite = _tokenConviteEntrada();

    final enderecoAntesDoUid = enderecoController.value.toModel('');
    final enderecoFoiInformado =
        _enderecoTemAlgumCampoPreenchido(enderecoAntesDoUid);
    final deveSalvarEndereco = !cadastroConvidado || enderecoFoiInformado;

    if (!_validarCamposCadastroGoogle(tipoEfetivo, enderecoAntesDoUid)) {
      return;
    }

    try {
      carregando.value = true;
      EasyLoading.show(status: 'Conectando com Google...');
      appController.marcarLoginComGoogle();
      final autenticou = await _autenticacaoRepository.entrarComGoogle();
      if (!autenticou) {
        _log('Cadastro com Google cancelado: usuário fechou o seletor.');
        return;
      }

      final firebaseUser = _auth.currentUser;
      final uid = firebaseUser?.uid;
      if (uid == null) {
        _showError('Não foi possível identificar sua conta Google.');
        return;
      }

      final usuarioExistente = await _db.collection('usuarios').doc(uid).get();
      final emailGoogle = firebaseUser?.email ??
          _autenticacaoRepository.emailUsuarioAtual ??
          '';
      final nomeInformado = nome.value.trim();
      final nomeGoogle = nomeInformado.isNotEmpty
          ? nomeInformado
          : (firebaseUser?.displayName?.trim() ?? '');

      if (!usuarioExistente.exists) {
        final novoUsuario = UsuarioModel(
          idUsuario: uid,
          nome: nomeGoogle.isEmpty ? 'Usuário Google' : nomeGoogle,
          email: emailGoogle,
          tipo: tipoEfetivo,
          ativo: true,
          fotoPerfilUrl: firebaseUser?.photoURL,
          cidade: _texto(enderecoAntesDoUid.nomeCidade),
          uf: _texto(enderecoAntesDoUid.uf),
          dataCadastro: DateTime.now(),
        );

        final usuarioMap = novoUsuario.toMap();
        usuarioMap['email_normalizado'] = _normalizarEmail(emailGoogle);
        usuarioMap['tipo'] = tipoEfetivo;
        usuarioMap['provider'] = 'google';

        await _db.collection('usuarios').doc(uid).set(usuarioMap);
      } else if ((usuarioExistente.data()?['tipo']?.toString().trim().isEmpty ??
          true)) {
        await _db.collection('usuarios').doc(uid).update({'tipo': tipoEfetivo});
      }

      if (deveSalvarEndereco) {
        final endereco = enderecoAntesDoUid.copyWith(idUsuario: uid);
        await _db
            .collection('usuarios')
            .doc(uid)
            .collection('enderecos')
            .doc(endereco.id)
            .set(endereco.toMap());
      }

      if (tipoEfetivo == 'F') {
        await _salvarDadosFornecedorGoogle(
          uid: uid,
          email: emailGoogle,
        );
      }

      Get.snackbar(
        'Sucesso',
        'Conta Google conectada com sucesso!',
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
      );

      EasyLoading.dismiss();
      final usuario = UsuarioModel.fromMap({
        ...(usuarioExistente.data() ?? const <String, dynamic>{}),
        'id_usuario': uid,
        'nome': usuarioExistente.data()?['nome'] ?? nomeGoogle,
        'email': usuarioExistente.data()?['email'] ?? emailGoogle,
        'tipo': usuarioExistente.data()?['tipo'] ?? tipoEfetivo,
        'foto_perfil_url': usuarioExistente.data()?['foto_perfil_url'] ??
            firebaseUser?.photoURL,
      });

      if (tipoEfetivo == 'C') {
        await appController.redirecionarConvidadoAposLogin(usuario,
            token: tokenConvite);
      } else {
        Get.offAllNamed('/splash');
      }
    } on AutenticacaoException catch (e) {
      if (e.foiCancelada) {
        _log('Cadastro com Google cancelado pelo usuário: ${e.codigo}');
        return;
      }
      _showError(_traduzErro(e.codigo));
    } on PlatformException catch (e) {
      if (autenticacaoFoiCancelada(e.code)) {
        _log('Cadastro com Google cancelado pelo usuário: ${e.code}');
        return;
      }
      _log('PlatformException no cadastro Google: ${e.code} | ${e.message}');
      _showError('Erro ao entrar com Google. Tente novamente.');
    } catch (e, s) {
      _log('Erro no cadastro Google: $e');
      _log('StackTrace: $s');
      _showError('Erro ao entrar com Google. Tente novamente.');
    } finally {
      EasyLoading.dismiss();
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

  Future<void> _salvarDadosFornecedorGoogle({
    required String uid,
    required String email,
  }) async {
    final novoFornecedor = FornecedorModel(
      idFornecedor: uid,
      idUsuario: uid,
      razaoSocial: razaoSocial.value.trim(),
      telefone: telefone.value.trim(),
      email: email,
      aptoParaOperar: false,
      ativo: true,
      bannerUrl: bannerUrl,
      cnpj: cnpj.value.trim(),
      descricao: '',
      dataCadastro: DateTime.now(),
      tipoEventoIds: tipoEventoIds.toList(growable: false),
      tipoEventoSlugs: tipoEventoSlugs.toList(growable: false),
      tipoEventoNomes: tipoEventoNomes.toList(growable: false),
    );

    await _db.collection('fornecedor').doc(uid).set(novoFornecedor.toMap());

    for (final cat in categoriasSelecionadas) {
      final catUpdate = cat.copyWith(idFornecedor: uid);
      await _db.collection('fornecedor_categoria').add(catUpdate.toMap());
    }

    for (final serv in servicosSelecionados) {
      final model = FornecedorProdutoServicoModel(
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
      await _db
          .collection('fornecedor_servico')
          .doc(vinculoId)
          .set(model.toMap());
    }
  }

  void alternarSubcategoria(FornecedorCategoriaModel catSel,
      SubcategoriaServicoModel sub, bool selected) {
    final index = categoriasSelecionadas
        .indexWhere((c) => c.idCategoria == catSel.idCategoria);
    if (index == -1) return;

    final atual = categoriasSelecionadas[index];
    final subcats =
        List<Map<String, dynamic>>.from((atual as dynamic).subcategorias ?? []);

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

  /// 🧠 Define todos os tipos de evento atendidos pelo fornecedor.
  /// Útil quando a tela trabalha com seleção múltipla e envia as listas completas.
  void definirTiposEventoAtendidos({
    required List<String> ids,
    required List<String> slugs,
    required List<String> nomes,
  }) {
    tipoEventoIds.assignAll(_normalizarLista(ids));
    tipoEventoSlugs.assignAll(_normalizarLista(slugs));
    tipoEventoNomes.assignAll(_normalizarLista(nomes));
  }

  /// 🧠 Alterna um tipo de evento atendido pelo fornecedor.
  /// Útil para ChoiceChip/FilterChip com seleção individual.
  void alternarTipoEventoAtendido({
    required String id,
    required String slug,
    required String nome,
    required bool selecionado,
  }) {
    final idLimpo = id.trim();
    final slugLimpo = slug.trim();
    final nomeLimpo = nome.trim();

    if (idLimpo.isEmpty) return;

    if (selecionado) {
      if (!tipoEventoIds.contains(idLimpo)) {
        tipoEventoIds.add(idLimpo);
      }

      if (slugLimpo.isNotEmpty && !tipoEventoSlugs.contains(slugLimpo)) {
        tipoEventoSlugs.add(slugLimpo);
      }

      if (nomeLimpo.isNotEmpty && !tipoEventoNomes.contains(nomeLimpo)) {
        tipoEventoNomes.add(nomeLimpo);
      }
    } else {
      tipoEventoIds.remove(idLimpo);
      tipoEventoSlugs.remove(slugLimpo);
      tipoEventoNomes.remove(nomeLimpo);
    }

    tipoEventoIds.refresh();
    tipoEventoSlugs.refresh();
    tipoEventoNomes.refresh();
  }

  bool isTipoEventoAtendidoSelecionado(String id) {
    return tipoEventoIds.contains(id.trim());
  }

  void limparTiposEventoAtendidos() {
    tipoEventoIds.clear();
    tipoEventoSlugs.clear();
    tipoEventoNomes.clear();
  }

  List<String> _normalizarLista(List<String> valores) {
    return valores
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
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
          .map((doc) =>
              SubcategoriaServicoModel.fromMap({...doc.data(), 'id': doc.id}))
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

  bool _validarCamposCadastro() {
    final tipoOriginal = tipoCadastroAtual;
    final cadastroConvidado = cadastroComoConvidado;
    final tipo = cadastroConvidado ? 'C' : tipoOriginal;

    _log('===== INÍCIO _validarCamposCadastro =====');
    _log(
      'tipoOriginal=$tipoOriginal | tipoValidacao=$tipo | cadastroConvidado=$cadastroConvidado | '
      'enderecoObrigatorio=$enderecoObrigatorio | nome="${nome.value}" | email="${email.value}"',
    );

    // ------------------------------
    // 🔹 Validações comuns
    // ------------------------------
    if (!_validarNomeCompleto()) {
      _log('FALHA validação: nome completo inválido.');
      return false;
    }

    if (!EmailValidator.validate(email.value.trim())) {
      _log('FALHA validação: e-mail inválido.');
      _showError('Digite um e-mail válido (ex: contato@email.com)');
      return false;
    }

    if (senha.value.trim().length < 6) {
      _log('FALHA validação: senha com menos de 6 caracteres.');
      _showError('A senha deve ter pelo menos 6 caracteres');
      return false;
    }

    // ------------------------------
    // 🔹 Validações específicas para Fornecedor
    // ------------------------------
    if (tipo == 'F') {
      if (razaoSocial.value.trim().isEmpty) {
        _log('FALHA fornecedor: razão social vazia.');
        _showError('Informe a razão social da sua empresa');
        return false;
      }

      if (telefone.value.trim().length < 8) {
        _log('FALHA fornecedor: telefone inválido.');
        _showError('Informe um telefone de contato válido');
        return false;
      }

      if (cnpj.value.trim().isEmpty) {
        _log('FALHA fornecedor: CNPJ vazio.');
        _showError('Informe o CNPJ da sua empresa');
        return false;
      }

      if (!BRValidators.validateCNPJ(cnpj.value.trim())) {
        _log('FALHA fornecedor: CNPJ inválido.');
        _showError('CNPJ inválido. Verifique e tente novamente.');
        return false;
      }

      if (categoriasSelecionadas.isEmpty) {
        _log('FALHA fornecedor: nenhuma categoria selecionada.');
        _showError('Selecione pelo menos uma categoria de atuação');
        return false;
      }

      if (servicosSelecionados.isEmpty) {
        _log('FALHA fornecedor: nenhum serviço selecionado.');
        _showError('Selecione pelo menos um serviço oferecido');
        return false;
      }

      if (tipoEventoIds.isEmpty) {
        _log('FALHA fornecedor: nenhum tipo de evento selecionado.');
        _showError('Selecione pelo menos um tipo de evento atendido');
        return false;
      }
    }

    // ------------------------------
    // 🔹 Endereço
    // ------------------------------
    final endereco = enderecoController.value.toModel('');
    final enderecoFoiInformado = _enderecoTemAlgumCampoPreenchido(endereco);
    final deveValidarEndereco = !cadastroConvidado || enderecoFoiInformado;

    _logEndereco(endereco, origem: '_validarCamposCadastro');
    _log(
      'Decisão endereço na validação: cadastroConvidado=$cadastroConvidado | '
      'enderecoFoiInformado=$enderecoFoiInformado | deveValidarEndereco=$deveValidarEndereco',
    );

    // Organizador e fornecedor precisam informar endereço.
    // Convidado só precisa validar endereço se começou a preencher algum campo.
    if (deveValidarEndereco && !_validarCamposEndereco(endereco)) {
      _log('BLOQUEADO: _validarCamposEndereco retornou false.');
      return false;
    }

    if (!deveValidarEndereco) {
      _log(
          'Endereço ignorado na validação: convidado sem endereço preenchido.');
    }

    _log('Cadastro validado com sucesso.');
    return true;
  }

  bool _validarCamposCadastroGoogle(
    String tipo,
    EnderecoUsuarioModel endereco,
  ) {
    if (!_validarNomeCompleto(tipo == 'F'
        ? 'Informe o nome completo do responsável'
        : 'Informe seu nome completo (nome e sobrenome)')) {
      return false;
    }

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

      if (tipoEventoIds.isEmpty) {
        _showError('Selecione pelo menos um tipo de evento atendido');
        return false;
      }
    }

    if (tipo != 'C' || _enderecoTemAlgumCampoPreenchido(endereco)) {
      return _validarCamposEndereco(endereco);
    }

    return true;
  }

  bool _validarCamposEndereco(EnderecoUsuarioModel endereco) {
    if (endereco.cep.trim().isEmpty) {
      _log('FALHA endereço: CEP vazio.');
      _showError('Informe o CEP');
      return false;
    }
    if (endereco.logradouro.trim().isEmpty) {
      _log('FALHA endereço: logradouro vazio.');
      _showError('Informe o endereço completo');
      return false;
    }
    if (endereco.numero.trim().isEmpty) {
      _log('FALHA endereço: número vazio.');
      _showError('Informe o número do endereço');
      return false;
    }
    if (endereco.bairro == null || endereco.bairro!.trim().isEmpty) {
      _log('FALHA endereço: bairro vazio.');
      _showError('Informe o bairro');
      return false;
    }
    if (endereco.uf == null || endereco.uf!.trim().isEmpty) {
      _log('FALHA endereço: UF vazia.');
      _showError('Informe o estado (UF)');
      return false;
    }
    if (endereco.nomeCidade == null || endereco.nomeCidade!.trim().isEmpty) {
      _log('FALHA endereço: cidade vazia.');
      _showError('Informe a cidade');
      return false;
    }

    _log('Endereço validado com sucesso.');
    return true;
  }

  bool _validarNomeCompleto(
      [String mensagem = 'Informe seu nome completo (nome e sobrenome)']) {
    final nomeLimpo = nome.value.trim();
    if (nomeLimpo.isEmpty) {
      _showError(mensagem);
      return false;
    }

    final partes = nomeLimpo
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .toList();
    if (partes.length < 2) {
      _showError(mensagem);
      return false;
    }

    return true;
  }

  bool _enderecoTemAlgumCampoPreenchido(EnderecoUsuarioModel endereco) {
    // Não considera UF sozinha, porque alguns controllers iniciam com "PR" por padrão.
    return endereco.cep.trim().isNotEmpty ||
        endereco.logradouro.trim().isNotEmpty ||
        endereco.numero.trim().isNotEmpty ||
        (endereco.complemento?.trim().isNotEmpty ?? false) ||
        (endereco.bairro?.trim().isNotEmpty ?? false) ||
        (endereco.nomeCidade?.trim().isNotEmpty ?? false);
  }

  bool _argumentsIndicamConvidado(dynamic args) {
    if (args == null) return false;

    if (args is Map) {
      final valores = <dynamic>[
        args['tipo'],
        args['isConvidado'],
        args['ehConvidado'],
        args['convidado'],
        args['cadastroConvidado'],
        args['cadastroComoConvidado'],
        args['tipoCadastro'],
        args['origemCadastro'],
        args['perfil'],
        args['tipoUsuario'],
      ];

      final resultado = valores.any(_valorRepresentaConvidado);
      _log('_argumentsIndicamConvidado=$resultado | valores=$valores');
      return resultado;
    }

    final resultado = _valorRepresentaConvidado(args);
    _log('_argumentsIndicamConvidado=$resultado | valor=$args');
    return resultado;
  }

  bool _valorRepresentaConvidado(dynamic valor) {
    if (valor == null) return false;
    if (valor is bool) return valor;

    final texto = _normalizeTexto(valor.toString());
    return texto == 'c' ||
        texto == 'convidado' ||
        texto == 'guest' ||
        texto == 'area convidado' ||
        texto.contains('convidado') ||
        texto.contains('guest');
  }

  String _normalizeTexto(String texto) {
    return texto.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
  }

  String _texto(String? value) => value?.trim() ?? '';

  String _normalizarEmail(String value) => value.trim().toLowerCase();

  String? _tokenConviteEntrada() {
    final args = Get.arguments;

    if (args is Map) {
      final raw = args['conviteToken'] ??
          args['tokenConvite'] ??
          args['token'] ??
          args['convite_token'] ??
          args['token_convite'];
      final tokenArgs = raw?.toString().trim() ?? '';
      if (tokenArgs.isNotEmpty) return tokenArgs;
    }

    final tokenApp = appController.conviteToken.value.trim();
    if (tokenApp.isNotEmpty) return tokenApp;

    final tokenUrl = appController.obterTokenConvite()?.trim() ?? '';
    if (tokenUrl.isNotEmpty) return tokenUrl;

    return null;
  }

  void _logEndereco(EnderecoUsuarioModel endereco, {required String origem}) {
    _log(
      'Endereço [$origem]: '
      'id="${endereco.id}" | '
      'cep="${endereco.cep}" | '
      'logradouro="${endereco.logradouro}" | '
      'numero="${endereco.numero}" | '
      'bairro="${endereco.bairro}" | '
      'cidade="${endereco.nomeCidade}" | '
      'uf="${endereco.uf}" | '
      'complemento="${endereco.complemento}"',
    );
  }

  void _log(String mensagem) {
    debugPrint('$_logTag $mensagem');
  }

  /// 🔹 Exibe mensagens elegantes de erro
  void _showError(String mensagem) {
    EasyLoading.dismiss();
    Get.rawSnackbar(
      title: 'Verificação necessária',
      message: mensagem,
      titleText: const Text(
        'Verificação necessária',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      messageText: Text(
        mensagem,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.red.shade600.withValues(alpha: 0.95),
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
      case 'account-exists-with-different-credential':
        return 'Este e-mail já está cadastrado com outro método de login';
      case 'canceled':
      case 'web-context-canceled':
      case 'ERROR_WEB_CONTEXT_CANCELED':
      case 'popup-closed-by-user':
        return 'Cadastro com Google cancelado';
      case 'interrupted':
        return 'O Google interrompeu o cadastro. Tente novamente.';
      case 'clientConfigurationError':
      case 'providerConfigurationError':
        return 'Google não configurado corretamente no Firebase';
      case 'google-token-not-found':
      case 'google-sign-in-unsupported':
      case 'google-unexpected-error':
        return 'Login com Google indisponível neste dispositivo';
      default:
        return 'Erro ao criar conta. Tente novamente.';
    }
  }
}
