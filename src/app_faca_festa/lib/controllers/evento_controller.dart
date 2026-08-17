import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../domain/entities/evento.dart';
import '../domain/entities/tipo_evento.dart';
import '../domain/repositories/evento_repository.dart';
import '../presentation/coordinators/evento_session_coordinator.dart';

class EventoController extends GetxController {
  EventoController({
    required EventoRepository repository,
    required EventoSessionCoordinator sessionCoordinator,
  })  : _repository = repository,
        _sessionCoordinator = sessionCoordinator;

  final EventoRepository _repository;
  final EventoSessionCoordinator _sessionCoordinator;

  final Rx<Evento?> eventoAtual = Rx<Evento?>(null);
  final Rx<TipoEvento?> tipoEventoAtual = Rx<TipoEvento?>(null);
  final RxBool carregando = false.obs;

  /// Domain-facing access used by presentation and application controllers.
  Evento? get eventoAtualEntidade => eventoAtual.value;

  /// Domain-facing access used by presentation and application controllers.
  TipoEvento? get tipoEventoAtualEntidade => tipoEventoAtual.value;

  StreamSubscription<Evento?>? _eventoSubscription;
  StreamSubscription<Evento?>? _eventoDocSub;

  /// =====================================================
  /// 🔹 Busca o último evento do usuário (uma vez)
  /// =====================================================
  Future<Evento?> buscarEventoPeloIdEvento(String idEvento) async {
    try {
      carregando.value = true;
      debugPrint("📦 [EventoController] Buscando o evento para id: $idEvento");

      final evento = await _repository.buscarPorId(idEvento);

      if (evento != null) {
        carregando.value = false;
        return evento;
      } else {
        carregando.value = false;
        eventoAtual.value = null;
        debugPrint(
            "⚠️ [EventoController] Nenhum evento encontrado para id: $idEvento");
        return null;
      }
    } catch (e, s) {
      carregando.value = false;
      debugPrint(
          "❌ [EventoController] Erro ao buscar o evento do id: $idEvento - erros: $e\n$s");
      return null;
    }
  }

  Future<void> escutarEventoPorId(
    String idEvento, {
    Evento? eventoInicial,
  }) async {
    if (idEvento.trim().isEmpty) return;

    await _eventoDocSub?.cancel();
    if (eventoInicial != null &&
        (eventoAtual.value == null ||
            eventoAtual.value!.idEvento != idEvento)) {
      eventoAtual.value = eventoInicial;
    }

    _eventoDocSub = _repository.observarPorId(idEvento).listen(
      (eventoAtualizado) {
        if (eventoAtualizado != null) {
          eventoAtual.value = eventoAtualizado;
          debugPrint(
              'Evento atualizado em tempo real: ${eventoAtualizado.nomeEvento}');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Erro ao acompanhar evento: $error');
      },
    );
  }

  /// =====================================================
  /// 🔹 Busca o último evento do usuário (uma vez)
  /// =====================================================
  Future<void> buscarUltimoEvento(String idUsuario) async {
    try {
      carregando.value = true;
      debugPrint(
          "📦 [EventoController] Buscando último evento para usuário: $idUsuario");

      final evento = await _repository.buscarUltimoPorUsuario(idUsuario);

      if (evento != null) {
        await _inicializarEvento(evento);
      } else {
        eventoAtual.value = null;
        debugPrint(
            "⚠️ [EventoController] Nenhum evento encontrado para este usuário.");
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

    _eventoSubscription =
        _repository.observarUltimoPorUsuario(idUsuario).listen((evento) async {
      if (evento != null) {
        // Evita reinicialização desnecessária
        if (eventoAtual.value == null ||
            evento.idEvento != eventoAtual.value!.idEvento) {
          debugPrint(
              "🔁 [EventoController] Evento detectado/atualizado: ${evento.nomeEvento}");
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
  Future<void> _inicializarEvento(Evento evento) async {
    try {
      debugPrint(
          "🎯 [EventoController] Inicializando evento: ${evento.nomeEvento}");
      await _cancelarEscutas();

      eventoAtual.value = evento;

      // 🔹 Busca e define o tipo do evento
      await buscarTipoEvento(evento.idTipoEvento);

      // ✅ Aplica o tema visual automaticamente
      final tipoNome = tipoEventoAtual.value?.nome ?? 'Padrão';
      debugPrint("🎨 [EventoController] Aplicando tema para tipo: $tipoNome");
      _sessionCoordinator.aplicarTema(tipoNome);

      // ✅ Escuta o documento do evento em tempo real
      _eventoDocSub = _repository.observarPorId(evento.idEvento).listen(
        (eventoAtualizado) {
          if (eventoAtualizado != null) {
            eventoAtual.value = eventoAtualizado;

            debugPrint(
                "🔄 [EventoController] Evento atualizado em tempo real: ${eventoAtualizado.nomeEvento}");
          }
        },
      );

      await _sessionCoordinator.inicializarModulosRelacionados(evento);

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
    await _sessionCoordinator.cancelar();

    _eventoDocSub = null;
  }

  /// =====================================================
  /// 🔹 Busca tipo de evento e aplica o tema
  /// =====================================================
  Future<void> buscarTipoEvento(String idTipoEvento) async {
    try {
      final tipoEvento = await _repository.buscarTipoPorId(idTipoEvento);

      if (tipoEvento != null) {
        tipoEventoAtual.value = tipoEvento;

        final nome = tipoEventoAtual.value!.nome;
        debugPrint("📘 [EventoController] Tipo de evento carregado: $nome");

        // 🔹 Aplica tema imediatamente
        _sessionCoordinator.aplicarTema(nome);
      } else {
        debugPrint(
            "⚠️ [EventoController] Tipo de evento não encontrado para ID: $idTipoEvento");
      }
    } catch (e, s) {
      debugPrint("❌ [EventoController] Erro ao buscar tipo de evento: $e\n$s");
    }
  }

  /// =====================================================
  /// 🔹 Salvar e excluir eventos
  /// =====================================================
  Future<void> salvarEvento(Evento evento) async {
    await _repository.salvar(evento);
  }

  Future<void> excluirEvento(String idEvento) async {
    await _repository.excluir(idEvento);
  }

  /// =====================================================
  /// 🔹 Listar eventos por usuário
  /// =====================================================
  Stream<List<Evento>> listarEventosPorUsuario(String idUsuario) {
    return _repository.listarPorUsuario(idUsuario);
  }

  Stream<List<Evento>> listarEntidadesPorUsuario(String idUsuario) {
    return _repository.listarPorUsuario(idUsuario);
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

  void limparSessaoAtual() {
    eventoAtual.value = null;
    tipoEventoAtual.value = null;
  }
}
