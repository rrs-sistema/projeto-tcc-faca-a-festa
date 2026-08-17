import 'dart:async';

import 'package:get/get.dart';

import '../../controllers/convidado/cardapio_controller.dart';
import '../../controllers/convidado/convidado_controller.dart';
import '../../controllers/convidado/grupo_convidado_controller.dart';
import '../../controllers/inspiracao/inspiracao_controller.dart';
import '../../controllers/orcamento_controller.dart';
import '../../controllers/tarefa_controller.dart';
import '../../controllers/tema/event_theme_controller.dart';
import '../../controllers/usuario/usuario_controller.dart';
import '../../domain/entities/evento.dart';

abstract interface class EventoSessionCoordinator {
  void aplicarTema(String nomeTipoEvento);

  Future<void> inicializarModulosRelacionados(Evento evento);

  Future<void> cancelar();
}

/// Coordinates the existing GetX controllers that react to the current event.
///
/// The calls and their order intentionally match the legacy initialization
/// previously kept inside EventoController.
class GetxEventoSessionCoordinator implements EventoSessionCoordinator {
  StreamSubscription<void>? _orcamentosSub;
  StreamSubscription<void>? _convidadosSub;
  StreamSubscription<void>? _cardapiosSub;
  StreamSubscription<void>? _gruposSub;
  StreamSubscription<void>? _tarefasSub;

  @override
  void aplicarTema(String nomeTipoEvento) {
    Get.find<EventThemeController>().aplicarTemaPorNome(nomeTipoEvento);
  }

  @override
  Future<void> inicializarModulosRelacionados(Evento evento) async {
    final orcamentoController = Get.find<OrcamentoController>();
    final convidadoController = Get.find<ConvidadoController>();
    final cardapioController = Get.find<CardapioController>();
    final grupoController = Get.find<GrupoConvidadoController>();
    final tarefaController = Get.find<TarefaController>();
    final inspiracaoController = Get.find<InspiracaoController>();
    final usuarioController = Get.find<UsuarioController>();

    _orcamentosSub = orcamentoController
        .carregarOrcamentosDoEvento(evento.idEvento)
        .asStream()
        .listen((_) {});
    _convidadosSub = convidadoController
        .escutarConvidados(evento.idEvento)
        .asStream()
        .listen((_) {});
    _cardapiosSub = cardapioController
        .escutarCardapios(evento.idEvento)
        .asStream()
        .listen((_) {});
    _gruposSub = grupoController
        .escutarGrupos(evento.idEvento)
        .asStream()
        .listen((_) {});
    _tarefasSub = tarefaController
        .listenTarefas(evento.idEvento)
        .asStream()
        .listen((_) {});

    final usuarioLogado = usuarioController.usuario.value;
    inspiracaoController
        .configurarContextoEvento(
          eventoId: evento.idEvento,
          userId: usuarioLogado?.idUsuario ?? '',
        )
        .asStream()
        .listen((_) {});
  }

  @override
  Future<void> cancelar() async {
    await _orcamentosSub?.cancel();
    await _tarefasSub?.cancel();
    await _convidadosSub?.cancel();
    await _cardapiosSub?.cancel();
    await _gruposSub?.cancel();

    _orcamentosSub = null;
    _tarefasSub = null;
    _convidadosSub = null;
    _cardapiosSub = null;
    _gruposSub = null;
  }
}
