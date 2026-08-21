import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../data/local/evento_ativo_store.dart';
import '../domain/entities/evento.dart';
import '../domain/entities/tipo_evento.dart';
import '../domain/repositories/evento_repository.dart';
import '../presentation/coordinators/evento_session_coordinator.dart';

class EventoController extends GetxController {
  EventoController({
    required EventoRepository repository,
    required EventoSessionCoordinator sessionCoordinator,
    EventoAtivoStore? eventoAtivoStore,
  })  : _repository = repository,
        _sessionCoordinator = sessionCoordinator,
        _eventoAtivoStore = eventoAtivoStore ?? const NoOpEventoAtivoStore();

  final EventoRepository _repository;
  final EventoSessionCoordinator _sessionCoordinator;
  final EventoAtivoStore _eventoAtivoStore;

  final Rx<Evento?> eventoAtual = Rx<Evento?>(null);
  final Rx<TipoEvento?> tipoEventoAtual = Rx<TipoEvento?>(null);
  final RxList<Evento> eventosDoUsuario = <Evento>[].obs;
  final RxBool carregando = false.obs;
  final RxBool trocandoEvento = false.obs;

  /// Domain-facing access used by presentation and application controllers.
  Evento? get eventoAtualEntidade => eventoAtual.value;

  /// Domain-facing access used by presentation and application controllers.
  TipoEvento? get tipoEventoAtualEntidade => tipoEventoAtual.value;

  StreamSubscription<Evento?>? _eventoSubscription;
  StreamSubscription<Evento?>? _eventoDocSub;
  StreamSubscription<List<Evento>>? _eventosUsuarioSub;
  String? _idUsuarioListado;
  int _geracaoSessao = 0;
  DateTime? _protegerEventoAtualAte;

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
          final temaAnterior = eventoAtual.value?.idTema;
          eventoAtual.value = eventoAtualizado;
          if (temaAnterior != eventoAtualizado.idTema) {
            _sessionCoordinator.aplicarTema(
              tipoEventoAtualEntidade?.nome ?? '',
              evento: eventoAtualizado,
            );
          }
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

  /// Lists the organizer's events and restores the last selected one.
  Future<void> carregarEventosDoUsuario(String idUsuario) async {
    final usuario = idUsuario.trim();
    if (usuario.isEmpty) return;

    if (_idUsuarioListado == usuario && _eventosUsuarioSub != null) {
      return;
    }

    await _eventosUsuarioSub?.cancel();
    _idUsuarioListado = usuario;
    carregando.value = true;

    final pronto = Completer<void>();

    _eventosUsuarioSub = _repository.listarPorUsuario(usuario).listen(
      (eventos) async {
        final ordenados = _ordenarEventos(eventos);
        eventosDoUsuario.assignAll(ordenados);
        await _aplicarListaDoUsuario(ordenados);
        if (!pronto.isCompleted) pronto.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
            '❌ [EventoController] Erro ao listar eventos do usuário: $error');
        if (!pronto.isCompleted) pronto.complete();
      },
    );

    try {
      await pronto.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      debugPrint(
          '⚠️ [EventoController] Timeout ao listar eventos de $usuario.');
    } finally {
      carregando.value = false;
    }
  }

  /// Makes [evento] the active planning session and reloads related modules.
  Future<void> selecionarEvento(Evento evento) async {
    if (evento.idEvento.trim().isEmpty) return;

    if (eventoAtual.value?.idEvento == evento.idEvento) {
      _eventoAtivoStore.salvar(evento.idUsuario, evento.idEvento);
      return;
    }

    trocandoEvento.value = true;
    try {
      _protegerEventoAtualAte =
          DateTime.now().add(const Duration(seconds: 12));
      await _inicializarEvento(evento);
    } finally {
      trocandoEvento.value = false;
    }
  }

  List<Evento> _ordenarEventos(List<Evento> eventos) {
    final copia = [...eventos];
    copia.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
    return copia;
  }

  Future<void> _aplicarListaDoUsuario(List<Evento> eventos) async {
    if (eventos.isEmpty) {
      final atual = eventoAtual.value;
      final proteger = _protegerEventoAtualAte;
      if (atual != null &&
          proteger != null &&
          DateTime.now().isBefore(proteger)) {
        debugPrint(
          '⚠️ [EventoController] Lista vazia ignorada: evento '
          '${atual.nomeEvento} recém-selecionado ainda não apareceu na query.',
        );
        return;
      }
      if (atual != null) {
        await _cancelarEscutas();
        eventoAtual.value = null;
        tipoEventoAtual.value = null;
      }
      return;
    }

    final idAtual = eventoAtual.value?.idEvento;
    if (idAtual != null && eventos.any((evento) => evento.idEvento == idAtual)) {
      return;
    }

    await _inicializarEvento(eventoMaisProximo(eventos));
  }

  /// Picks the event closest to happening. Future dates win; if every
  /// event already passed, the most recent past date is used.
  static Evento eventoMaisProximo(List<Evento> eventos) {
    if (eventos.length == 1) return eventos.first;

    final inicioHoje = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    Evento? proximoFuturo;
    Duration? menorFuturo;
    Evento? recentePassado;
    Duration? menorPassado;

    for (final evento in eventos) {
      final data = DateTime(evento.data.year, evento.data.month, evento.data.day);
      final diferenca = data.difference(inicioHoje);

      if (!diferenca.isNegative) {
        if (menorFuturo == null || diferenca < menorFuturo) {
          menorFuturo = diferenca;
          proximoFuturo = evento;
        }
        continue;
      }

      final atrasado = diferenca.abs();
      if (menorPassado == null || atrasado < menorPassado) {
        menorPassado = atrasado;
        recentePassado = evento;
      }
    }

    return proximoFuturo ?? recentePassado ?? eventos.first;
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
    final geracao = ++_geracaoSessao;
    try {
      debugPrint(
          "🎯 [EventoController] Inicializando evento: ${evento.nomeEvento}");
      await _cancelarEscutas();
      if (geracao != _geracaoSessao) return;

      eventoAtual.value = evento;
      _eventoAtivoStore.salvar(evento.idUsuario, evento.idEvento);

      // 🔹 Busca e define o tipo do evento
      await buscarTipoEvento(evento.idTipoEvento);
      if (geracao != _geracaoSessao) return;

      // ✅ Aplica o tema visual automaticamente
      final tipoNome = tipoEventoAtual.value?.nome ?? 'Padrão';
      debugPrint("🎨 [EventoController] Aplicando tema para tipo: $tipoNome");
      _sessionCoordinator.aplicarTema(tipoNome, evento: evento);

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
      if (geracao != _geracaoSessao) return;

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
        _sessionCoordinator.aplicarTema(nome, evento: eventoAtualEntidade);
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
    _eventosUsuarioSub?.cancel();
    _cancelarEscutas();
    super.onClose();
  }

  void reset() {
    unawaited(_eventoSubscription?.cancel());
    _eventoSubscription = null;
    unawaited(_eventosUsuarioSub?.cancel());
    _eventosUsuarioSub = null;
    _idUsuarioListado = null;
    eventosDoUsuario.clear();
    unawaited(_cancelarEscutas());
    eventoAtual.value = null;
    tipoEventoAtual.value = null;
    _protegerEventoAtualAte = null;
  }

  Future<void> encerrarEscutas() async {
    await _eventoSubscription?.cancel();
    _eventoSubscription = null;
    await _eventosUsuarioSub?.cancel();
    _eventosUsuarioSub = null;
    _idUsuarioListado = null;
    eventosDoUsuario.clear();
    await _cancelarEscutas();
    eventoAtual.value = null;
    tipoEventoAtual.value = null;
    _protegerEventoAtualAte = null;
  }

  void limparSessaoAtual() {
    reset();
  }
}
