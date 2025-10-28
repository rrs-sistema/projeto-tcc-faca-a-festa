import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../data/models/DTO/servico_cotado_dto.dart';
import './../presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './../presentation/pages/fornecedor/fornecedor_home_screen.dart';
import './../presentation/pages/admin/admin_dashboard_screen.dart';
import './../presentation/pages/welcome/welcome_event_screen.dart';
import './../presentation/pages/convidado/convidado_page.dart';
import './../presentation/pages/home_event_screen.dart';
import './../role_selector_screen.dart';
import './../data/models/model.dart';

import 'avaliacao/avaliacao_controller.dart';
import 'contacao/cotacao_controller.dart';
import 'evento_controller.dart';
import 'fornecedor_controller.dart';
import 'orcamento_controller.dart';
import 'tarefa_controller.dart';

class AppController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Estado reativo do usuário
  final Rx<UsuarioModel?> usuarioLogado = Rx<UsuarioModel?>(null);
  final Rx<EnderecoUsuarioModel?> enderecoPrincipal = Rx<EnderecoUsuarioModel?>(null);
  final RxList<EnderecoUsuarioModel> enderecosUsuario = <EnderecoUsuarioModel>[].obs;

  /// 🔹 Lista global de serviços selecionados para cotação
  final RxList<ServicoCotadoDto> servicosSelecionados = <ServicoCotadoDto>[].obs;

  final RxBool carregando = false.obs;
  StreamSubscription<User?>? _authSub;

  // ✅ Injeção de controladores auxiliares
  final eventoController = Get.put(EventoController());
  final orcamentoController = Get.put(OrcamentoController());
  final cotacaoController = Get.put(CotacaoController());
  final fornecedorController = Get.put(FornecedorController());
  final tarefaController = Get.put(TarefaController());
  final avaliacaoController = Get.put(AvaliacaoController());

  @override
  void onInit() {
    super.onInit();
    _monitorarSessao();
  }

  // ------------------------------------------------------------
  // 🔹 Carrega usuário logado e endereço principal
  // ------------------------------------------------------------
  Future<UsuarioModel?> prepararUsuarioComEndereco() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      carregando.value = true;

      // 🔹 1️⃣ Busca o documento do usuário
      final docUser = await _db.collection('usuarios').doc(user.uid).get();
      if (!docUser.exists || docUser.data() == null) {
        debugPrint('⚠️ Usuário não encontrado no Firestore.');
        carregando.value = false;
        return null;
      }

      final usuario = UsuarioModel.fromMap(docUser.data()!);
      await eventoController.buscarUltimoEvento(usuario.idUsuario);

      // 🔹 2️⃣ Busca subcoleção de endereços
      final enderecosSnapshot =
          await _db.collection('usuarios').doc(user.uid).collection('enderecos').get();

      final enderecos =
          enderecosSnapshot.docs.map((e) => EnderecoUsuarioModel.fromMap(e.data())).toList();

      enderecosUsuario.assignAll(enderecos);

      if (enderecos.isNotEmpty) {
        final principal = enderecos.firstWhere(
          (e) => e.principal,
          orElse: () => enderecos.first,
        );

        enderecoPrincipal.value = principal;

        usuarioLogado.value = usuario.copyWith(
          cidade: principal.nomeCidade,
          uf: principal.uf,
        );
      } else {
        enderecoPrincipal.value = null;
        usuarioLogado.value = usuario;
      }

      carregando.value = false;
      return usuarioLogado.value;
    } catch (e, s) {
      carregando.value = false;
      debugPrint('❌ Erro ao preparar usuário: $e');
      debugPrintStack(stackTrace: s);
      return null;
    }
  }

  // ------------------------------------------------------------
  // 🔹 Monitora sessão do Firebase Auth e redireciona o usuário
  // ------------------------------------------------------------
  void _monitorarSessao() {
    _authSub = _auth.authStateChanges().listen((user) async {
      await Future.delayed(const Duration(milliseconds: 300)); // ✅ pequeno delay
      if (user == null) {
        usuarioLogado.value = null;
        enderecoPrincipal.value = null;
        eventoController.eventoAtual.value = null;
        eventoController.tipoEventoAtual.value = null;

        if (Get.currentRoute != '/role') Get.offAllNamed('/role');
        return;
      }

      if (Get.currentRoute != '/splash') Get.offAllNamed('/splash');

      carregando.value = true;

      try {
        // Busca usuário + endereços
        final results = await Future.wait([
          _db.collection('usuarios').doc(user.uid).get(),
          _db.collection('usuarios').doc(user.uid).collection('enderecos').get(),
        ]);

        final docUser = results[0] as DocumentSnapshot<Map<String, dynamic>>;
        final enderecosSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;

        if (!docUser.exists || docUser.data() == null) {
          throw Exception('Usuário não encontrado no Firestore.');
        }

        final usuario = UsuarioModel.fromMap(docUser.data()!);
        final enderecos =
            enderecosSnapshot.docs.map((e) => EnderecoUsuarioModel.fromMap(e.data())).toList();

        // Atualiza cache reativo
        if (enderecos.isNotEmpty) {
          final principal = enderecos.firstWhere(
            (e) => e.principal,
            orElse: () => enderecos.first,
          );
          enderecoPrincipal.value = principal;
          usuarioLogado.value = usuario.copyWith(
            cidade: principal.nomeCidade,
            uf: principal.uf,
          );
        } else {
          enderecoPrincipal.value = null;
          usuarioLogado.value = usuario;
        }

        Widget destino;

        // ----------------------------------------------------------
        // 🔹 Lógica de roteamento por tipo de usuário
        // ----------------------------------------------------------
        switch (usuario.tipo) {
          case 'F': // 🧑‍🔧 Fornecedor
            final fornecedorDoc = await _db.collection('fornecedor').doc(usuario.idUsuario).get();

            if (fornecedorDoc.exists && fornecedorDoc.data() != null) {
              final fornecedor = FornecedorModel.fromMap(fornecedorDoc.data()!);
              if (!fornecedor.aptoParaOperar) {
                Get.snackbar(
                  "Em análise",
                  "Seu cadastro ainda não foi aprovado pelo administrador.",
                  backgroundColor: Colors.orange.shade400,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              }
              fornecedorController.fornecedor.value = fornecedor;
              fornecedorController.escutarServicosFornecedor(fornecedor.idUsuario);
              orcamentoController.escutarOrcamentos(fornecedor.idUsuario);
              avaliacaoController.listenAvaliacoes(fornecedor.idUsuario);
            }
            destino = FornecedorHomeScreen();
            break;

          case 'C': // 🎁 Convidado
            await eventoController.buscarUltimoEvento(usuario.idUsuario);
            final evento = eventoController.eventoAtual.value;

            if (evento != null) {
              await orcamentoController.carregarOrcamentosDoEvento(evento.idEvento);
              destino = AreaConvidadoHomeScreen(convidado: usuario, evento: evento);
            } else {
              destino = const ConvidadosPage();
            }
            break;

          case 'A': // 🛠️ Administrador
            destino = const AdminDashboardScreen();
            break;

          default: // 🎉 Organizador
            await eventoController.buscarUltimoEvento(usuario.idUsuario);
            final evento = eventoController.eventoAtual.value;

            if (evento != null) {
              debugPrint('🔹 Carregando dados do evento ${evento.nome}...');
              fornecedorController.carregarServicosPorEvento(evento.idEvento);
              await orcamentoController.carregarOrcamentosDoEvento(evento.idEvento);
              cotacaoController.ouvirMinhasCotacoes();

              debugPrint('✅ Evento ${evento.nome} carregado com sucesso!');
              destino = HomeEventScreen();
            } else {
              destino = const WelcomeEventScreen();
            }
            break;
        }

        carregando.value = false;
        Get.offAll(
          () => destino,
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 250),
        );
      } catch (e, s) {
        carregando.value = false;
        debugPrint('❌ Erro ao validar sessão: $e\n$s');
        Get.snackbar(
          'Erro de sessão',
          'Não foi possível validar sua conta. Tente novamente.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        Get.offAllNamed('/role');
      }
    });
  }

  // ------------------------------------------------------------
  // 🔹 Logout
  // ------------------------------------------------------------

  Future<void> logout() async {
    await _auth.signOut();
    usuarioLogado.value = null;
    eventoController.reset();
    orcamentoController.reset();
    tarefaController.reset();
    Get.offAll(() => const WelcomeEventScreen());
  }

  Future<void> logoutFornecedor() async {
    await _authSub?.cancel();
    await _auth.signOut();
    usuarioLogado.value = null;
    eventoController.reset();
    orcamentoController.reset();
    tarefaController.reset();
    Get.offAll(() => const RoleSelectorScreen());
    _monitorarSessao(); // Reativa sessão
  }

  // ------------------------------------------------------------
  // 🔹 Usuários (CRUD básico)
  // ------------------------------------------------------------
  Future<void> salvarUsuario(UsuarioModel usuario) async {
    await _db.collection('usuarios').doc(usuario.idUsuario).set(usuario.toMap());
    usuarioLogado.value = usuario;
  }

  Future<UsuarioModel?> obterUsuario(String id) async {
    final doc = await _db.collection('usuarios').doc(id).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromMap(doc.data()!);
  }

  // ------------------------------------------------------------
  // 🔹 Utilitário genérico
  // ------------------------------------------------------------
  Future<void> excluirDocumento(String colecao, String idDocumento) async {
    await _db.collection(colecao).doc(idDocumento).delete();
  }

  /// 🔹 Adiciona serviço à lista (evita duplicatas)
  void adicionarServico(ServicoCotadoDto servico) {
    if (!servicosSelecionados.any((s) => s.idProduto == servico.idProduto)) {
      servicosSelecionados.add(servico);
    }
  }

  /// 🔹 Remove serviço da lista
  void removerServico(String idProduto) {
    servicosSelecionados.removeWhere((s) => s.idProduto == idProduto);
  }

  /// 🔹 Limpa todos os serviços selecionados
  void limparServicosSelecionados() {
    servicosSelecionados.clear();
  }

  /// 🔹 Verifica se um serviço está selecionado
  bool isServicoSelecionado(String idProduto) {
    return servicosSelecionados.any((s) => s.idProduto == idProduto);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }
}
