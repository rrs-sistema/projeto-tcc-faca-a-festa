import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/presentation/coordinators/evento_session_coordinator.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/inspiracao/controllers/inspiracao_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_gasto_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/usuario_controller.dart';

void main() {
  late _CallLog log;
  late _TemaFake theme;
  late _OrcamentoFake orcamento;
  late _ConvidadoFake convidado;
  late _CardapioFake cardapio;
  late _GrupoFake grupo;
  late _TarefaFake tarefa;
  late _InspiracaoFake inspiracao;
  late _UsuarioFake usuario;
  late _FornecedorFake fornecedor;
  late _OrcamentoGastoFake gasto;
  late _CalculadoraFake calculadora;
  late GetxEventoSessionCoordinator coordinator;

  setUp(() {
    log = _CallLog();
    theme = _TemaFake(log);
    orcamento = _OrcamentoFake(log);
    convidado = _ConvidadoFake(log);
    cardapio = _CardapioFake(log);
    grupo = _GrupoFake(log);
    tarefa = _TarefaFake(log);
    inspiracao = _InspiracaoFake(log);
    usuario = _UsuarioFake(log);
    fornecedor = _FornecedorFake(log);
    gasto = _OrcamentoGastoFake(log);
    calculadora = _CalculadoraFake(log);
    coordinator = _montarCoordinator(
      log: log,
      theme: theme,
      orcamento: orcamento,
      convidado: convidado,
      cardapio: cardapio,
      grupo: grupo,
      tarefa: tarefa,
      inspiracao: inspiracao,
      usuario: usuario,
      fornecedor: fornecedor,
      gasto: gasto,
      calculadora: calculadora,
    );
  });

  test(
    'inicializarModulosRelacionados looks up then starts modules in legacy order',
    () async {
      usuario.usuario.value = _usuario(id: 'usuario-logado');

      await coordinator.inicializarModulosRelacionados(_evento());

      expect(log.calls, [
        'lookup:orcamento',
        'lookup:convidado',
        'lookup:cardapio',
        'lookup:grupo',
        'lookup:tarefa',
        'lookup:inspiracao',
        'lookup:usuario',
        'orcamento.carregar:evento-1',
        'convidado.escutar:evento-1',
        'cardapio.escutar:evento-1',
        'grupo.escutar:evento-1',
        'tarefa.listen:evento-1',
        'inspiracao.configurar:evento-1:usuario-logado',
        'lookup:fornecedor',
        'fornecedor.carregar:evento-1',
      ]);
    },
  );

  test(
    'inicializarModulosRelacionados uses event user when session user is empty',
    () async {
      usuario.usuario.value = _usuario(id: '   ');

      await coordinator.inicializarModulosRelacionados(_evento());

      expect(
        log.calls,
        contains('inspiracao.configurar:evento-1:usuario-evento'),
      );
    },
  );

  test(
    'inicializarModulosRelacionados uses event user when usuario module is absent',
    () async {
      coordinator = _montarCoordinator(
        log: log,
        theme: theme,
        orcamento: orcamento,
        convidado: convidado,
        cardapio: cardapio,
        grupo: grupo,
        tarefa: tarefa,
        inspiracao: inspiracao,
        usuario: null,
        fornecedor: fornecedor,
        gasto: gasto,
        calculadora: calculadora,
      );

      await coordinator.inicializarModulosRelacionados(_evento());

      expect(
        log.calls,
        contains('inspiracao.configurar:evento-1:usuario-evento'),
      );
    },
  );

  test(
    'inicializarModulosRelacionados skips missing modules and still loads supplier',
    () async {
      coordinator = _montarCoordinator(
        log: log,
        theme: theme,
        orcamento: null,
        convidado: null,
        cardapio: null,
        grupo: null,
        tarefa: null,
        inspiracao: null,
        usuario: null,
        fornecedor: fornecedor,
        gasto: null,
        calculadora: null,
      );

      await coordinator.inicializarModulosRelacionados(_evento());

      expect(log.calls, [
        'lookup:orcamento',
        'lookup:convidado',
        'lookup:cardapio',
        'lookup:grupo',
        'lookup:tarefa',
        'lookup:inspiracao',
        'lookup:usuario',
        'lookup:fornecedor',
        'fornecedor.carregar:evento-1',
      ]);
    },
  );

  test(
    'inicializarModulosRelacionados does not start gastos, calculadora or theme',
    () async {
      await coordinator.inicializarModulosRelacionados(_evento());

      expect(
          log.calls.where((call) => call.startsWith('lookup:theme')), isEmpty);
      expect(
          log.calls.where((call) => call.startsWith('lookup:gasto')), isEmpty);
      expect(
        log.calls.where((call) => call.startsWith('lookup:calculadora')),
        isEmpty,
      );
      expect(log.calls.where((call) => call.startsWith('gasto.')), isEmpty);
      expect(
          log.calls.where((call) => call.startsWith('calculadora.')), isEmpty);
      expect(log.calls.where((call) => call.startsWith('theme.')), isEmpty);
    },
  );

  test(
    'cancelar cancels stored subscriptions then tears modules down in legacy order',
    () async {
      await coordinator.inicializarModulosRelacionados(_evento());
      log.calls.clear();

      await coordinator.cancelar();

      expect(log.calls, [
        'orcamento.sub.cancel',
        'tarefa.sub.cancel',
        'convidado.sub.cancel',
        'cardapio.sub.cancel',
        'grupo.sub.cancel',
        'lookup:orcamento',
        'orcamento.encerrar',
        'lookup:tarefa',
        'tarefa.encerrar',
        'lookup:convidado',
        'convidado.limpar',
        'lookup:cardapio',
        'cardapio.encerrar',
        'lookup:grupo',
        'grupo.encerrar',
        'lookup:inspiracao',
        'inspiracao.encerrar',
        'lookup:gasto',
        'gasto.encerrar',
        'lookup:calculadora',
        'calculadora.limpar',
      ]);
    },
  );

  test(
    'cancelar still tears modules down when nothing was initialized',
    () async {
      await coordinator.cancelar();

      expect(log.calls, [
        'lookup:orcamento',
        'orcamento.encerrar',
        'lookup:tarefa',
        'tarefa.encerrar',
        'lookup:convidado',
        'convidado.limpar',
        'lookup:cardapio',
        'cardapio.encerrar',
        'lookup:grupo',
        'grupo.encerrar',
        'lookup:inspiracao',
        'inspiracao.encerrar',
        'lookup:gasto',
        'gasto.encerrar',
        'lookup:calculadora',
        'calculadora.limpar',
      ]);
    },
  );

  test(
    'cancelar does not touch theme, usuario or fornecedor',
    () async {
      await coordinator.inicializarModulosRelacionados(_evento());
      log.calls.clear();

      await coordinator.cancelar();

      expect(log.calls.where((call) => call.contains('theme')), isEmpty);
      expect(log.calls.where((call) => call.contains('usuario')), isEmpty);
      expect(log.calls.where((call) => call.contains('fornecedor')), isEmpty);
      expect(log.calls, isNot(contains('inspiracao.sub.cancel')));
    },
  );

  test(
    'cancelar does not wait for module setup futures to finish',
    () async {
      await coordinator.inicializarModulosRelacionados(_evento());

      expect(orcamento.pendente.isCompleted, isFalse);
      expect(tarefa.pendente.isCompleted, isFalse);

      await coordinator.cancelar().timeout(const Duration(seconds: 1));

      expect(orcamento.pendente.isCompleted, isFalse);
      expect(fornecedor.pendente.isCompleted, isFalse);
    },
  );

  test('aplicarTema with event delegates to aplicarParaEvento', () {
    coordinator.aplicarTema('Casamento', evento: _evento());

    expect(log.calls, [
      'lookup:theme',
      'theme.aplicarParaEvento:evento-1:Casamento',
    ]);
  });

  test('aplicarTema without event uses product theme when role forbids party',
      () {
    theme.permiteTemaDaFesta = false;

    coordinator.aplicarTema('Casamento');

    expect(log.calls, [
      'lookup:theme',
      'theme.aplicarTemaProduto',
    ]);
  });

  test('aplicarTema without event uses type name when role allows party', () {
    theme.permiteTemaDaFesta = true;

    coordinator.aplicarTema('Casamento');

    expect(log.calls, [
      'lookup:theme',
      'theme.aplicarTemaPorNome:Casamento',
    ]);
  });
}

GetxEventoSessionCoordinator _montarCoordinator({
  required _CallLog log,
  required _TemaFake theme,
  required _OrcamentoFake? orcamento,
  required _ConvidadoFake? convidado,
  required _CardapioFake? cardapio,
  required _GrupoFake? grupo,
  required _TarefaFake? tarefa,
  required _InspiracaoFake? inspiracao,
  required _UsuarioFake? usuario,
  required _FornecedorFake? fornecedor,
  required _OrcamentoGastoFake? gasto,
  required _CalculadoraFake? calculadora,
}) {
  return GetxEventoSessionCoordinator(
    themeControllerOf: () {
      log.add('lookup:theme');
      return theme;
    },
    orcamentoControllerOf: () {
      log.add('lookup:orcamento');
      return orcamento;
    },
    convidadoControllerOf: () {
      log.add('lookup:convidado');
      return convidado;
    },
    cardapioControllerOf: () {
      log.add('lookup:cardapio');
      return cardapio;
    },
    grupoControllerOf: () {
      log.add('lookup:grupo');
      return grupo;
    },
    tarefaControllerOf: () {
      log.add('lookup:tarefa');
      return tarefa;
    },
    inspiracaoControllerOf: () {
      log.add('lookup:inspiracao');
      return inspiracao;
    },
    usuarioControllerOf: () {
      log.add('lookup:usuario');
      return usuario;
    },
    fornecedorControllerOf: () {
      log.add('lookup:fornecedor');
      return fornecedor;
    },
    orcamentoGastoControllerOf: () {
      log.add('lookup:gasto');
      return gasto;
    },
    calculadoraControllerOf: () {
      log.add('lookup:calculadora');
      return calculadora;
    },
  );
}

Evento _evento() => Evento(
      idEvento: 'evento-1',
      idTipoEvento: 'tipo-1',
      idUsuario: 'usuario-evento',
      nomeEvento: 'Festa',
      localEvento: 'Salão',
      data: DateTime(2026, 12, 20),
    );

Usuario _usuario({required String id}) => Usuario(
      idUsuario: id,
      nome: 'Ana',
      email: 'ana@example.com',
    );

class _CallLog {
  final calls = <String>[];

  void add(String call) => calls.add(call);
}

Future<void> _segurar(
  _CallLog log, {
  required String call,
  required String cancelamento,
  required Completer<void> pendente,
}) {
  log.add(call);
  return _FuturoRastreado(
    pendente: pendente,
    aoCancelarInscricao: () => log.add(cancelamento),
  );
}

/// Completer-backed Future whose [asStream] records subscription cancel.
///
/// The coordinator wraps setup Futures with `asStream().listen`; this lets the
/// test lock that cancel order without a production seam.
class _FuturoRastreado implements Future<void> {
  _FuturoRastreado({
    required this.pendente,
    required this.aoCancelarInscricao,
  });

  final Completer<void> pendente;
  final void Function() aoCancelarInscricao;

  Future<void> get _inner => pendente.future;

  @override
  Stream<void> asStream() {
    final controller = StreamController<void>(
      onCancel: aoCancelarInscricao,
    );
    _inner.then((_) {
      if (!controller.isClosed) {
        controller.add(null);
        unawaited(controller.close());
      }
    }, onError: (Object error, StackTrace stack) {
      if (!controller.isClosed) {
        controller.addError(error, stack);
      }
    });
    return controller.stream;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(void value) onValue, {
    Function? onError,
  }) =>
      _inner.then(onValue, onError: onError);

  @override
  Future<void> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) =>
      _inner.catchError(onError, test: test);

  @override
  Future<void> whenComplete(FutureOr<void> Function() action) =>
      _inner.whenComplete(action);

  @override
  Future<void> timeout(
    Duration timeLimit, {
    FutureOr<void> Function()? onTimeout,
  }) =>
      _inner.timeout(timeLimit, onTimeout: onTimeout);
}

class _TemaFake extends Fake implements EventThemeController {
  _TemaFake(this.log);

  final _CallLog log;
  bool permiteTemaDaFesta = true;

  @override
  bool get papelPermiteTemaDaFesta => permiteTemaDaFesta;

  @override
  void aplicarTemaProduto() {
    log.add('theme.aplicarTemaProduto');
  }

  @override
  void aplicarTemaPorNome(String nomeTipoEvento) {
    log.add('theme.aplicarTemaPorNome:$nomeTipoEvento');
  }

  @override
  Future<void> aplicarParaEvento(
    Evento evento, {
    String? fallbackNomeTipo,
  }) async {
    log.add(
      'theme.aplicarParaEvento:${evento.idEvento}:${fallbackNomeTipo ?? ''}',
    );
  }
}

class _OrcamentoFake extends Fake implements OrcamentoController {
  _OrcamentoFake(this.log);

  final _CallLog log;
  final pendente = Completer<void>();

  @override
  Future<void> carregarOrcamentosDoEvento(String idEvento) {
    return _segurar(
      log,
      call: 'orcamento.carregar:$idEvento',
      cancelamento: 'orcamento.sub.cancel',
      pendente: pendente,
    );
  }

  @override
  Future<void> encerrarEscutas() async {
    log.add('orcamento.encerrar');
  }
}

class _ConvidadoFake extends Fake implements ConvidadoController {
  _ConvidadoFake(this.log);

  final _CallLog log;
  final pendente = Completer<void>();

  @override
  Future<void> escutarConvidados(String idEvento) {
    return _segurar(
      log,
      call: 'convidado.escutar:$idEvento',
      cancelamento: 'convidado.sub.cancel',
      pendente: pendente,
    );
  }

  @override
  void limpar() {
    log.add('convidado.limpar');
  }
}

class _CardapioFake extends Fake implements CardapioController {
  _CardapioFake(this.log);

  final _CallLog log;
  final pendente = Completer<void>();

  @override
  Future<void> escutarCardapios(String idEvento) {
    return _segurar(
      log,
      call: 'cardapio.escutar:$idEvento',
      cancelamento: 'cardapio.sub.cancel',
      pendente: pendente,
    );
  }

  @override
  Future<void> encerrarEscutas() async {
    log.add('cardapio.encerrar');
  }
}

class _GrupoFake extends Fake implements GrupoConvidadoController {
  _GrupoFake(this.log);

  final _CallLog log;
  final pendente = Completer<void>();

  @override
  Future<void> escutarGrupos(String idEvento) {
    return _segurar(
      log,
      call: 'grupo.escutar:$idEvento',
      cancelamento: 'grupo.sub.cancel',
      pendente: pendente,
    );
  }

  @override
  Future<void> encerrarEscutas() async {
    log.add('grupo.encerrar');
  }
}

class _TarefaFake extends Fake implements TarefaController {
  _TarefaFake(this.log);

  final _CallLog log;
  final pendente = Completer<void>();

  @override
  Future<void> listenTarefas(String idEvento) {
    return _segurar(
      log,
      call: 'tarefa.listen:$idEvento',
      cancelamento: 'tarefa.sub.cancel',
      pendente: pendente,
    );
  }

  @override
  Future<void> encerrarEscutas() async {
    log.add('tarefa.encerrar');
  }
}

class _InspiracaoFake extends Fake implements InspiracaoController {
  _InspiracaoFake(this.log);

  final _CallLog log;
  final pendente = Completer<void>();

  @override
  Future<void> configurarContextoEvento({
    required String eventoId,
    required String userId,
  }) {
    return _segurar(
      log,
      call: 'inspiracao.configurar:$eventoId:$userId',
      cancelamento: 'inspiracao.sub.cancel',
      pendente: pendente,
    );
  }

  @override
  Future<void> encerrarEscutas() async {
    log.add('inspiracao.encerrar');
  }
}

class _UsuarioFake extends Fake implements UsuarioController {
  _UsuarioFake(this.log);

  final _CallLog log;

  @override
  final usuario = Rxn<Usuario>();
}

class _FornecedorFake extends Fake implements FornecedorController {
  _FornecedorFake(this.log);

  final _CallLog log;
  final pendente = Completer<void>();

  @override
  Future<void> carregarServicosPorEvento(String idEvento) {
    log.add('fornecedor.carregar:$idEvento');
    return pendente.future;
  }
}

class _OrcamentoGastoFake extends Fake implements OrcamentoGastoController {
  _OrcamentoGastoFake(this.log);

  final _CallLog log;

  @override
  Future<void> encerrarEscutas() async {
    log.add('gasto.encerrar');
  }
}

class _CalculadoraFake extends Fake implements CalculadoraFestaController {
  _CalculadoraFake(this.log);

  final _CallLog log;

  @override
  void limpar() {
    log.add('calculadora.limpar');
  }
}
