import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';

import './convidado/grupo_convidado_controller.dart';
import './convidado/convidado_controller.dart';
import './convidado/cardapio_controller.dart';
import './../data/models/model.dart';
import './orcamento_controller.dart';
import 'inspiracao_controller.dart';
import 'tarefa_controller.dart';
import 'tema/event_theme_controller.dart';
import 'usuario/usuario_controller.dart';

class EventoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Rx<EventoModel?> eventoAtual = Rx<EventoModel?>(null);
  final Rx<TipoEventoModel?> tipoEventoAtual = Rx<TipoEventoModel?>(null);
  final RxBool carregando = false.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventoSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _eventoDocSub;

  // 🔹 Escutas individuais de dados relacionados
  StreamSubscription? _convidadosSub;
  StreamSubscription? _gruposSub;
  StreamSubscription? _cardapiosSub;
  StreamSubscription? _orcamentosSub;
  StreamSubscription? _tarefasSub;

  /// =====================================================
  /// 🔹 Busca o último evento do usuário (uma vez)
  /// =====================================================
  Future<EventoModel?> buscarEventoPeloIdEvento(String idEvento) async {
    try {
      carregando.value = true;
      debugPrint("📦 [EventoController] Buscando o evento para id: $idEvento");

      final snapshot = await _db
          .collection('evento')
          .where('id_evento', isEqualTo: idEvento)
          .orderBy('data_cadastro', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        carregando.value = false;
        return EventoModel.fromMap(snapshot.docs.first.data());
      } else {
        carregando.value = false;
        eventoAtual.value = null;
        debugPrint("⚠️ [EventoController] Nenhum evento encontrado para id: $idEvento");
        return null;
      }
    } catch (e, s) {
      carregando.value = false;
      debugPrint("❌ [EventoController] Erro ao buscar o evento do id: $idEvento - erros: $e\n$s");
      return null;
    }
  }

  /// =====================================================
  /// 🔹 Busca o último evento do usuário (uma vez)
  /// =====================================================
  Future<void> buscarUltimoEvento(String idUsuario) async {
    try {
      carregando.value = true;
      debugPrint("📦 [EventoController] Buscando último evento para usuário: $idUsuario");

      final snapshot = await _db
          .collection('evento')
          .where('id_usuario', isEqualTo: idUsuario)
          .orderBy('data_cadastro', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final evento = EventoModel.fromMap(snapshot.docs.first.data());
        await _inicializarEvento(evento);
      } else {
        eventoAtual.value = null;
        debugPrint("⚠️ [EventoController] Nenhum evento encontrado para este usuário.");
      }

      carregando.value = false;
    } catch (e, s) {
      carregando.value = false;
      debugPrint("❌ [EventoController] Erro ao buscar último evento: $e\n$s");
    }
  }

  /// =====================================================
  /// 🔹 Escuta continuamente o último evento do usuário
  /// =====================================================
  void escutarUltimoEvento(String idUsuario) {
    _eventoSubscription?.cancel();

    _eventoSubscription = _db
        .collection('evento')
        .where('id_usuario', isEqualTo: idUsuario)
        .orderBy('data_cadastro', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final evento = EventoModel.fromMap(snapshot.docs.first.data());

        // Evita reinicialização desnecessária
        if (eventoAtual.value == null || evento.idEvento != eventoAtual.value!.idEvento) {
          debugPrint("🔁 [EventoController] Evento detectado/atualizado: ${evento.nomeEvento}");
          await _inicializarEvento(evento);
        }
      } else {
        eventoAtual.value = null;
      }
    }, onError: (e) {
      debugPrint('❌ [EventoController] Erro ao escutar evento: $e');
    });
  }

  /// =====================================================
  /// 🔹 Inicializa todos os controladores do evento atual
  /// =====================================================
  Future<void> _inicializarEvento(EventoModel evento) async {
    try {
      debugPrint("🎯 [EventoController] Inicializando evento: ${evento.nomeEvento}");
      await _cancelarEscutas();

      eventoAtual.value = evento;

      // 🔹 Busca e define o tipo do evento
      await buscarTipoEvento(evento.idTipoEvento);

      // ✅ Aplica o tema visual automaticamente
      final themeController = Get.find<EventThemeController>();
      final tipoNome = tipoEventoAtual.value?.nome ?? 'Padrão';
      debugPrint("🎨 [EventoController] Aplicando tema para tipo: $tipoNome");
      themeController.aplicarTemaPorNome(tipoNome);

      // ✅ Escuta o documento do evento em tempo real
      _eventoDocSub = _db.collection('evento').doc(evento.idEvento).snapshots().listen((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          final eventoAtualizado = EventoModel.fromMap(data);
          eventoAtual.value = eventoAtualizado;

          debugPrint(
              "🔄 [EventoController] Evento atualizado em tempo real: ${eventoAtualizado.nomeEvento}");
        }
      });

      // 🔹 Inicializa controladores auxiliares
      final orcamentoController = Get.find<OrcamentoController>();
      final convidadoController = Get.find<ConvidadoController>();
      final cardapioController = Get.find<CardapioController>();
      final grupoController = Get.find<GrupoConvidadoController>();
      final tarefaController = Get.find<TarefaController>();
      final inspiracaoController = Get.find<InspiracaoController>();
      final usuarioController = Get.find<UsuarioController>();
      

      _orcamentosSub =
          orcamentoController.carregarOrcamentosDoEvento(evento.idEvento).asStream().listen((_) {});
      _convidadosSub =
          convidadoController.escutarConvidados(evento.idEvento).asStream().listen((_) {});

      _cardapiosSub =
          cardapioController.escutarCardapios(evento.idEvento).asStream().listen((_) {});
      _gruposSub = grupoController.escutarGrupos(evento.idEvento).asStream().listen((_) {});
      _tarefasSub = tarefaController.listenTarefas(evento.idEvento).asStream().listen((_) {});
      final userLogado = usuarioController.usuario.value;

      inspiracaoController
          .configurarContextoEvento(eventoId: evento.idEvento, userId: userLogado?.idUsuario ?? '')
          .asStream()
          .listen((_) {});

      debugPrint(
          "✅ [EventoController] Evento '${evento.nomeEvento}' inicializado com sucesso e escutando alterações.");
    } catch (e, s) {
      debugPrint("❌ [EventoController] Erro ao inicializar evento: $e\n$s");
    }
  }

  /// =====================================================
  /// 🔹 Cancela todas as escutas anteriores
  /// =====================================================
  Future<void> _cancelarEscutas() async {
    await _eventoDocSub?.cancel();
    await _orcamentosSub?.cancel();
    await _tarefasSub?.cancel();
    await _convidadosSub?.cancel();
    await _cardapiosSub?.cancel();
    await _gruposSub?.cancel();

    _tarefasSub = null;
    _eventoDocSub = null;
    _orcamentosSub = null;
    _convidadosSub = null;
    _cardapiosSub = null;
    _gruposSub = null;
  }

  /// =====================================================
  /// 🔹 Busca tipo de evento e aplica o tema
  /// =====================================================
  Future<void> buscarTipoEvento(String idTipoEvento) async {
    try {
      final snapshot = await _db
          .collection('tipo_evento')
          .where('id_tipo_evento', isEqualTo: idTipoEvento)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        tipoEventoAtual.value = TipoEventoModel.fromMap(snapshot.docs.first.data());

        final nome = tipoEventoAtual.value!.nome;
        debugPrint("📘 [EventoController] Tipo de evento carregado: $nome");

        // 🔹 Aplica tema imediatamente
        final themeController = Get.find<EventThemeController>();
        themeController.aplicarTemaPorNome(nome);
      } else {
        debugPrint("⚠️ [EventoController] Tipo de evento não encontrado para ID: $idTipoEvento");
      }
    } catch (e, s) {
      debugPrint("❌ [EventoController] Erro ao buscar tipo de evento: $e\n$s");
    }
  }

  /// =====================================================
  /// 🔹 Salvar e excluir eventos
  /// =====================================================
  Future<void> salvarEvento(EventoModel evento) async {
    await _db.collection('evento').doc(evento.idEvento).set(evento.toMap());
  }

  Future<void> excluirEvento(String idEvento) async {
    await _db.collection('evento').doc(idEvento).delete();
  }

  /// =====================================================
  /// 🔹 Listar eventos por usuário
  /// =====================================================
  Stream<List<EventoModel>> listarEventosPorUsuario(String idUsuario) {
    return _db
        .collection('evento')
        .where('id_usuario', isEqualTo: idUsuario)
        .snapshots()
        .map((snap) => snap.docs.map((d) => EventoModel.fromMap(d.data())).toList());
  }

  /// =====================================================
  /// 🔹 Encerramento seguro
  /// =====================================================
  @override
  void onClose() {
    _eventoSubscription?.cancel();
    _cancelarEscutas();
    super.onClose();
  }

  void reset() {
    eventoAtual.value = null;
  }
}
