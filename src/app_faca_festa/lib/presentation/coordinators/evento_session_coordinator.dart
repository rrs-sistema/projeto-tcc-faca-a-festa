import 'dart:async';

import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';

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
  GetxEventoSessionCoordinator({
    required this.themeControllerOf,
    required this.orcamentoControllerOf,
    required this.convidadoControllerOf,
    required this.cardapioControllerOf,
    required this.grupoControllerOf,
    required this.tarefaControllerOf,
    required this.inspiracaoControllerOf,
    required this.usuarioControllerOf,
    required this.fornecedorControllerOf,
    required this.orcamentoGastoControllerOf,
    required this.calculadoraControllerOf,
  });

  final EventThemeController Function() themeControllerOf;
  final OrcamentoController? Function() orcamentoControllerOf;
  final ConvidadoController? Function() convidadoControllerOf;
  final CardapioController? Function() cardapioControllerOf;
  final GrupoConvidadoController? Function() grupoControllerOf;
  final TarefaController? Function() tarefaControllerOf;
  final InspiracaoController? Function() inspiracaoControllerOf;
  final UsuarioController? Function() usuarioControllerOf;
  final FornecedorController? Function() fornecedorControllerOf;
  final OrcamentoGastoController? Function() orcamentoGastoControllerOf;
  final CalculadoraFestaController? Function() calculadoraControllerOf;

  StreamSubscription<void>? _orcamentosSub;
  StreamSubscription<void>? _convidadosSub;
  StreamSubscription<void>? _cardapiosSub;
  StreamSubscription<void>? _gruposSub;
  StreamSubscription<void>? _tarefasSub;

  @override
  void aplicarTema(String nomeTipoEvento, {Evento? evento}) {
    final theme = themeControllerOf();
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
    final orcamentoController = orcamentoControllerOf();
    final convidadoController = convidadoControllerOf();
    final cardapioController = cardapioControllerOf();
    final grupoController = grupoControllerOf();
    final tarefaController = tarefaControllerOf();
    final inspiracaoController = inspiracaoControllerOf();
    final usuarioController = usuarioControllerOf();

    _orcamentosSub = orcamentoController
        ?.carregarOrcamentosDoEvento(evento.idEvento)
        .asStream()
        .listen((_) {});
    _convidadosSub = convidadoController
        ?.escutarConvidados(evento.idEvento)
        .asStream()
        .listen((_) {});
    _cardapiosSub = cardapioController
        ?.escutarCardapios(evento.idEvento)
        .asStream()
        .listen((_) {});
    _gruposSub = grupoController
        ?.escutarGrupos(evento.idEvento)
        .asStream()
        .listen((_) {});
    _tarefasSub = tarefaController
        ?.listenTarefas(evento.idEvento)
        .asStream()
        .listen((_) {});

    final usuarioLogado = usuarioController?.usuario.value;
    final userId = (usuarioLogado?.idUsuario ?? '').trim().isNotEmpty
        ? usuarioLogado!.idUsuario
        : evento.idUsuario;
    inspiracaoController
        ?.configurarContextoEvento(
          eventoId: evento.idEvento,
          userId: userId,
        )
        .asStream()
        .listen((_) {});

    final fornecedorController = fornecedorControllerOf();
    if (fornecedorController != null) {
      unawaited(
          fornecedorController.carregarServicosPorEvento(evento.idEvento));
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

    await orcamentoControllerOf()?.encerrarEscutas();
    await tarefaControllerOf()?.encerrarEscutas();
    convidadoControllerOf()?.limpar();
    await cardapioControllerOf()?.encerrarEscutas();
    await grupoControllerOf()?.encerrarEscutas();
    await inspiracaoControllerOf()?.encerrarEscutas();
    await orcamentoGastoControllerOf()?.encerrarEscutas();
    calculadoraControllerOf()?.limpar();
  }
}
