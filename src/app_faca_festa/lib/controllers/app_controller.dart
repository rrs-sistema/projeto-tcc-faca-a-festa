import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../presentation/pages/convidado/convidado_page.dart';
import '../presentation/widgets/splash.dart';
import '../role_selector_screen.dart';
import './../presentation/pages/usuario/show_fornecedor_cadastro_bottom_sheet.dart';
import './../presentation/pages/convidado/area/area_convidado_home_screen.dart';
import './../presentation/pages/fornecedor/fornecedor_home_screen.dart';
import './../presentation/pages/admin/admin_dashboard_screen.dart';
import './../presentation/pages/welcome/welcome_event_screen.dart';
import './../presentation/pages/home_event_screen.dart';
import './../data/models/model.dart';

class AppController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Estado reativo do usuário
  Rx<UsuarioModel?> usuarioLogado = Rx<UsuarioModel?>(null);
  final Rx<EnderecoUsuarioModel?> enderecoPrincipal = Rx<EnderecoUsuarioModel?>(null);
  // === Endereços (cache reativo) ===
  final RxList<EnderecoUsuarioModel> enderecosUsuario = <EnderecoUsuarioModel>[].obs;

  final Rx<EventoModel?> eventoModel = Rx<EventoModel?>(null);
  final Rx<TipoEventoModel?> tipoEventoModel = Rx<TipoEventoModel?>(null);

  RxBool carregando = false.obs;
  StreamSubscription<User?>? _authSub;

  @override
  void onInit() {
    super.onInit();
    _monitorarSessao();
  }

  // ------------------------------------------------------------
  // 👇 Aqui dentro vem o método que usa as variáveis acima
  // ------------------------------------------------------------

  /// 🔹 Busca e carrega o usuário + endereços antes de abrir o modal de evento
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

      // 🔹 2️⃣ Busca subcoleção de endereços
      final enderecosSnapshot =
          await _db.collection('usuarios').doc(user.uid).collection('enderecos').get();

      final enderecos =
          enderecosSnapshot.docs.map((e) => EnderecoUsuarioModel.fromMap(e.data())).toList();

      // 🔹 3️⃣ Atualiza cache reativo
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

  /// 🔹 Observa mudanças na autenticação Firebase
  void _monitorarSessao() {
    _authSub = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        usuarioLogado.value = null;
        Get.offAll(() => const AdminDashboardScreen());
        return;
      }

      carregando.value = true;

      try {
        // ======================================
        // 🧩 1️⃣ Busca usuário principal
        // ======================================
        final docUser = await _db.collection('usuarios').doc(user.uid).get();

        if (!docUser.exists || docUser.data() == null) {
          throw Exception('Usuário não encontrado no Firestore.');
        }

        final usuario = UsuarioModel.fromMap(docUser.data()!);

        // ======================================
        // 🏠 2️⃣ Busca subcoleção de endereços
        // ======================================
        final enderecosSnapshot =
            await _db.collection('usuarios').doc(user.uid).collection('enderecos').get();

        final enderecos =
            enderecosSnapshot.docs.map((e) => EnderecoUsuarioModel.fromMap(e.data())).toList();

        // ✅ Atualiza o estado global (AppController)
        // ✅ Atualiza o estado global (AppController)
        if (enderecos.isNotEmpty) {
          final enderecoPrincipalModel = enderecos.firstWhere(
            (e) => e.principal,
            orElse: () => enderecos.first,
          );

          // Armazena o endereço completo
          enderecoPrincipal.value = enderecoPrincipalModel;

          // Atualiza o usuário logado apenas com cidade/UF resumidas
          usuarioLogado.value = usuario.copyWith(
            cidade: enderecoPrincipalModel.nomeCidade,
            uf: enderecoPrincipalModel.uf,
          );
        } else {
          enderecoPrincipal.value = null;
          usuarioLogado.value = usuario;
        }

        // ======================================
        // 🧩 3️⃣ Lógica específica por tipo
        // ======================================
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

              Get.offAll(
                () => FornecedorHomeScreen(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 200),
              );
            } else {
              // 🚨 Fornecedor ainda não cadastrou empresa
              final confirmado = await showFornecedorCadastroBottomSheet(Get.context!);
              if (confirmado) {
                final novoFornecedor = FornecedorModel(
                  idFornecedor: usuario.idUsuario,
                  idUsuario: usuario.idUsuario,
                  razaoSocial: usuario.nome,
                  telefone: '(00) 00000-0000',
                  email: usuario.email,
                  descricao: 'Cadastro pendente de aprovação',
                  aptoParaOperar: false,
                  ativo: true,
                );

                await _db
                    .collection('fornecedor')
                    .doc(usuario.idUsuario)
                    .set(novoFornecedor.toMap());

                Get.snackbar(
                  "Cadastro enviado",
                  "Seu cadastro foi enviado para aprovação.",
                  backgroundColor: Colors.green.shade400,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.TOP,
                );
              }

              Get.offAll(
                () => FornecedorHomeScreen(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 200),
              );
            }
            break;

          case 'C': // 🎁 Convidado
            await buscarUltimoEvento(usuario.idUsuario);
            if (eventoModel.value != null) {
              Get.offAll(
                () => AreaConvidadoHomeScreen(convidado: usuario, evento: eventoModel.value!),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 200),
              );
            } else {
              Get.snackbar(
                "Convite não encontrado",
                "Você ainda não foi vinculado a um evento ativo.",
                backgroundColor: Colors.orange.shade400,
                colorText: Colors.white,
              );
              Get.offAll(() => const ConvidadosPage());
            }
            break;

          case 'A': // 🛠️ Administrador
            Get.offAll(
              () => const AdminDashboardScreen(),
              transition: Transition.fadeIn,
              duration: const Duration(milliseconds: 200),
            );
            break;

          default: // 🎉 Organizador (O ou vazio)
            await buscarUltimoEvento(usuario.idUsuario);
            if (eventoModel.value != null) {
              Get.offAll(
                () => HomeEventScreen(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 200),
              );
            } else {
              Get.offAll(() => const WelcomeEventScreen());
            }
            break;
        }

        carregando.value = false;
      } catch (e) {
        carregando.value = false;
        Get.snackbar(
          'Erro de sessão',
          'Não foi possível validar sua conta. Tente novamente.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        Get.offAll(() => const RoleSelectorScreen());
      }
    });
  }

  /// 🔹 Logout
  Future<void> logout() async {
    await _auth.signOut();
    usuarioLogado.value = null;
    Get.offAll(() => const WelcomeEventScreen());
  }

  Future<void> logoutFornecedor() async {
    await _authSub?.cancel(); // 🧹 para de ouvir
    await _auth.signOut();
    usuarioLogado.value = null;
    Get.offAll(() => const RoleSelectorScreen());
    _monitorarSessao(); // 🔁 reativa após logout
  }

  // ===================================================
  // === USUÁRIOS ======================================
  // ===================================================

  Future<void> salvarUsuario(UsuarioModel usuario) async {
    await _db.collection('usuarios').doc(usuario.idUsuario).set(usuario.toMap());
    usuarioLogado.value = usuario;
  }

  Future<UsuarioModel?> obterUsuario(String id) async {
    final doc = await _db.collection('usuarios').doc(id).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromMap(doc.data()!);
  }

  // ===================================================
  // === TIPOS DE EVENTOS =======================================
  // ===================================================

  Future<void> buscarTipoEvento(String idTipoEvento) async {
    try {
      final snapshot = await _db
          .collection('tipo_evento')
          .where('id_tipo_evento', isEqualTo: idTipoEvento)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        tipoEventoModel.value = TipoEventoModel.fromMap(snapshot.docs.first.data());
      }
    } catch (e) {
      debugPrint("❌ Erro ao buscar último evento: $e");
    }
  }

  // ===================================================
  // === EVENTOS =======================================
  // ===================================================

  Future<void> buscarUltimoEvento(String idUsuario) async {
    try {
      final snapshot = await _db
          .collection('evento')
          .where('id_usuario', isEqualTo: idUsuario)
          .orderBy('data_cadastro', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        eventoModel.value = EventoModel.fromMap(snapshot.docs.first.data());
        await buscarTipoEvento(eventoModel.value!.idTipoEvento);
      }
    } catch (e) {
      debugPrint("❌ Erro ao buscar último evento: $e");
    }
  }

  Future<void> salvarEvento(EventoModel evento) async {
    await _db.collection('eventos').doc(evento.idEvento).set(evento.toMap());
  }

  Stream<List<EventoModel>> listarEventosPorUsuario(String idUsuario) {
    return _db
        .collection('eventos')
        .where('id_usuario', isEqualTo: idUsuario)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EventoModel.fromMap(d.data())).toList());
  }

  // ===================================================
  // === FORNECEDORES ==================================
  // ===================================================

  Future<void> salvarFornecedor(FornecedorModel fornecedor) async {
    await _db.collection('fornecedor').doc(fornecedor.idFornecedor).set(fornecedor.toMap());
  }

  Stream<List<FornecedorModel>> listarFornecedores() {
    return _db
        .collection('fornecedor')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FornecedorModel.fromMap(d.data())).toList());
  }

  Future<FornecedorModel?> buscarFornecedor(String idUsuario) async {
    try {
      final snapshot = await _db
          .collection('fornecedor')
          .where('id_usuario', isEqualTo: idUsuario)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FornecedorModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint("❌ Erro ao buscar último evento: $e");
      return null;
    }
  }

  // ===================================================
  // === ORÇAMENTO E PAGAMENTO =========================
  // ===================================================

  Future<void> salvarOrcamento(OrcamentoModel orcamento) async {
    await _db
        .collection('eventos')
        .doc(orcamento.idEvento)
        .collection('orcamentos')
        .doc(orcamento.idOrcamento)
        .set(orcamento.toMap());
  }

  Stream<List<OrcamentoModel>> listarOrcamentos(String idEvento) {
    return _db
        .collection('eventos')
        .doc(idEvento)
        .collection('orcamentos')
        .snapshots()
        .map((snap) => snap.docs.map((d) => OrcamentoModel.fromMap(d.data())).toList());
  }

  Future<void> salvarPagamento(
      String idEvento, String idOrcamento, PagamentoModel pagamento) async {
    await _db
        .collection('eventos')
        .doc(idEvento)
        .collection('orcamentos')
        .doc(idOrcamento)
        .collection('pagamentos')
        .doc(pagamento.idPagamento)
        .set(pagamento.toMap());
  }

  // ===================================================
  // === COTAÇÕES ======================================
  // ===================================================

  Future<void> salvarCotacao(CotacaoModel cotacao) async {
    await _db.collection('cotacoes').doc(cotacao.idCotacao.toString()).set(cotacao.toMap());
  }

  Stream<List<CotacaoModel>> listarCotacoes() {
    return _db
        .collection('cotacoes')
        .snapshots()
        .map((snap) => snap.docs.map((d) => CotacaoModel.fromMap(d.data())).toList());
  }

  // ===================================================
  // === GENÉRICO ======================================
  // ===================================================

  Future<void> excluirDocumento(String colecao, String idDocumento) async {
    await _db.collection(colecao).doc(idDocumento).delete();
  }
}
