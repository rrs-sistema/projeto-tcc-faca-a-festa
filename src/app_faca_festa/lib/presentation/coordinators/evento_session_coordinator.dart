import 'dart:async';

import 'package:get/get.dart';

import '../../domain/entities/evento.dart';
import '../modules/calculadora/controllers/calculadora_festa_controller.dart';
import '../modules/convidado/controllers/cardapio_controller.dart';
import '../modules/convidado/controllers/convidado_controller.dart';
import '../modules/convidado/controllers/grupo_convidado_controller.dart';
import '../modules/convidado/controllers/tarefa_controller.dart';
import '../modules/fornecedor/controllers/fornecedor_controller.dart';
import '../modules/inspiracao/controllers/inspiracao_controller.dart';
import '../modules/orcamento/controllers/orcamento_gasto_controller.dart';
import '../modules/orcamento/orcamento_controller.dart';
import '../modules/tema/controllers/event_theme_controller.dart';
import '../modules/usuario/controllers/usuario_controller.dart';

abstract interface class EventoSessionCoordinator {
  void aplicarTema(String nomeTipoEvento, {Evento? evento});

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
  void aplicarTema(String nomeTipoEvento, {Evento? evento}) {
    final theme = Get.find<EventThemeController>();
    if (evento != null) {
      unawaited(
        theme.aplicarParaEvento(evento, fallbackNomeTipo: nomeTipoEvento),
      );
      return;
    }
    if (!theme.papelPermiteTemaDaFesta) {
      theme.aplicarTemaProduto();
      return;
    }
    theme.aplicarTemaPorNome(nomeTipoEvento);
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
    final userId = (usuarioLogado?.idUsuario ?? '').trim().isNotEmpty
        ? usuarioLogado!.idUsuario
        : evento.idUsuario;
    inspiracaoController
        .configurarContextoEvento(
          eventoId: evento.idEvento,
          userId: userId,
        )
        .asStream()
        .listen((_) {});

    if (Get.isRegistered<FornecedorController>()) {
      unawaited(
        Get.find<FornecedorController>()
            .carregarServicosPorEvento(evento.idEvento),
      );
    }
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

    if (Get.isRegistered<OrcamentoController>()) {
      await Get.find<OrcamentoController>().encerrarEscutas();
    }
    if (Get.isRegistered<TarefaController>()) {
      await Get.find<TarefaController>().encerrarEscutas();
    }
    if (Get.isRegistered<ConvidadoController>()) {
      Get.find<ConvidadoController>().limpar();
    }
    if (Get.isRegistered<CardapioController>()) {
      await Get.find<CardapioController>().encerrarEscutas();
    }
    if (Get.isRegistered<GrupoConvidadoController>()) {
      await Get.find<GrupoConvidadoController>().encerrarEscutas();
    }
    if (Get.isRegistered<InspiracaoController>()) {
      await Get.find<InspiracaoController>().encerrarEscutas();
    }
    if (Get.isRegistered<OrcamentoGastoController>()) {
      await Get.find<OrcamentoGastoController>().encerrarEscutas();
    }
    if (Get.isRegistered<CalculadoraFestaController>()) {
      Get.find<CalculadoraFestaController>().limpar();
    }
  }
}
