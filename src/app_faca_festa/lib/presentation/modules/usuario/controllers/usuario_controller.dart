import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:app_faca_festa/data/models/model.dart';
import 'package:app_faca_festa/data/services/auditoria/auditoria_app.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/foto_perfil_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/endereco_usuario_controller.dart';
import 'package:app_faca_festa/presentation/pages/endereco/endereco_section_controller.dart';

class UsuarioController extends GetxController {
  final AutenticacaoRepository _autenticacaoRepository =
      Get.find<AutenticacaoRepository>();
  final PerfilUsuarioRepository _perfilRepository =
      Get.find<PerfilUsuarioRepository>();
  final FotoPerfilRepository _fotoPerfilRepository =
      Get.find<FotoPerfilRepository>();

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
  final enderecoUsuarioController = Get.find<EnderecoUsuarioController>();
  final enderecoController = EnderecoSectionController().obs;

  @override
  void onInit() {
    super.onInit();
    carregarUsuarioLogado();
  }

  // =============================================================
  // 🔹 CARREGA usuário logado a partir do Auth
  // =============================================================
  Future<void> carregarUsuarioLogado() async {
    try {
      final uid = _autenticacaoRepository.idUsuarioAtual;
      if (uid == null) return;

      final usuarioEncontrado = await _perfilRepository.buscarUsuario(uid);
      if (usuarioEncontrado == null) return;

      usuario.value = UsuarioModel.fromEntity(usuarioEncontrado);

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

      final uid = _autenticacaoRepository.idUsuarioAtual!;

      await _perfilRepository.atualizarDadosBasicos(
        idUsuario: uid,
        nome: nome,
        cpf: cpf,
      );

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
      final senha = usuario.senhaHash?.trim() ?? '';
      if (senha.length < 6) {
        Get.snackbar(
          'Senha obrigatória',
          'Informe uma senha com pelo menos 6 caracteres.',
          backgroundColor: Colors.orange.shade700,
          colorText: Colors.white,
        );
        return;
      }

      final uid = await _autenticacaoRepository.criarUsuario(
        email: usuario.email.trim(),
        senha: senha,
      );
      final endereco = enderecoController.value.toModel(uid);
      final novo = usuario.copyWith(
          idUsuario: uid,
          cidade: endereco.nomeCidade,
          uf: endereco.uf,
          senhaHash: null);
      await _perfilRepository.salvarUsuario(novo);
      // 🔹 Subcoleção de endereços
      await _perfilRepository.salvarEndereco(endereco);
      usuarios.add(novo);
      filtrarUsuarios(buscaCtrl.text);
      AuditoriaApp.registrar(
        acao: 'USUARIO_CRIADO',
        resumo: 'Nova conta cadastrada pelo administrador.',
        entidadeTipo: 'usuario',
        entidadeId: uid,
        entidadeNome: novo.nome,
        mudancas: [
          AuditoriaMudanca(campo: 'Tipo', para: _labelTipo(novo.tipo)),
          AuditoriaMudanca(campo: 'E-mail', para: novo.email),
        ],
      );
      Get.snackbar('Sucesso', 'Usuário cadastrado com sucesso!',
          backgroundColor: Colors.green.shade700, colorText: Colors.white);
    } on AutenticacaoException catch (e) {
      EasyLoading.showError(_traduzErro(e.codigo));
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
      final uid = _autenticacaoRepository.idUsuarioAtual!;

      // Seleciona imagem
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);

      if (img == null) return;

      EasyLoading.show(status: 'Enviando foto...');

      final url = await _fotoPerfilRepository.enviar(
        idUsuario: uid,
        caminhoArquivo: img.path,
        nomeArquivo: img.name,
      );

      await _perfilRepository.atualizarFotoPerfil(uid, url);

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
      final usuariosEncontrados = await _perfilRepository.listarUsuarios();
      final lista = usuariosEncontrados.map(UsuarioModel.fromEntity).toList();

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
    final user = usuarios.firstWhereOrNull((u) => u.idUsuario == idUsuario);
    await _perfilRepository.atualizarTipo(idUsuario, 'A');
    if (user != null) {
      usuarios[usuarios.indexOf(user)] = user.copyWith(tipo: 'A');
      filtrarUsuarios(buscaCtrl.text);
    }
    AuditoriaApp.registrar(
      acao: 'USUARIO_TIPO_ALTERADO',
      resumo: 'Usuário promovido a administrador.',
      entidadeTipo: 'usuario',
      entidadeId: idUsuario,
      entidadeNome: user?.nome,
      mudancas: [
        AuditoriaMudanca(
          campo: 'Papel',
          de: _labelTipo(user?.tipo),
          para: 'Administrador',
        ),
      ],
    );
    Get.snackbar('Sucesso', 'Usuário promovido a administrador',
        backgroundColor: Colors.teal.shade600, colorText: Colors.white);
  }

  Future<void> removerAdmin(String idUsuario) async {
    final user = usuarios.firstWhereOrNull((u) => u.idUsuario == idUsuario);
    await _perfilRepository.atualizarTipo(idUsuario, 'O');
    if (user != null) {
      usuarios[usuarios.indexOf(user)] = user.copyWith(tipo: 'O');
      filtrarUsuarios(buscaCtrl.text);
    }
    AuditoriaApp.registrar(
      acao: 'USUARIO_TIPO_ALTERADO',
      resumo: 'Privilégio de administrador removido.',
      entidadeTipo: 'usuario',
      entidadeId: idUsuario,
      entidadeNome: user?.nome,
      mudancas: [
        AuditoriaMudanca(
          campo: 'Papel',
          de: 'Administrador',
          para: 'Organizador',
        ),
      ],
    );
    Get.snackbar('Alteração salva', 'Usuário deixou de ser administrador',
        backgroundColor: Colors.orange.shade700, colorText: Colors.white);
  }

  Future<void> toggleAtivo(String idUsuario, bool novoStatus) async {
    try {
      final user = usuarios.firstWhereOrNull((u) => u.idUsuario == idUsuario);
      await _perfilRepository.atualizarStatusAtivo(idUsuario, novoStatus);

      if (user != null) {
        final atualizado = user.copyWith(ativo: novoStatus);
        usuarios[usuarios.indexOf(user)] = atualizado;
        filtrarUsuarios(buscaCtrl.text);
      }

      AuditoriaApp.registrar(
        acao: 'USUARIO_STATUS_ALTERADO',
        resumo: novoStatus
            ? 'Conta reativada pelo administrador.'
            : 'Conta desativada pelo administrador.',
        entidadeTipo: 'usuario',
        entidadeId: idUsuario,
        entidadeNome: user?.nome,
        mudancas: [
          AuditoriaMudanca(
            campo: 'Ativo',
            de: user?.ativo == true ? 'sim' : 'não',
            para: novoStatus ? 'sim' : 'não',
          ),
        ],
      );

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

  String _labelTipo(String? tipo) {
    switch ((tipo ?? '').trim()) {
      case 'A':
        return 'Administrador';
      case 'F':
        return 'Fornecedor';
      case 'O':
        return 'Organizador';
      default:
        return tipo ?? '—';
    }
  }
}
