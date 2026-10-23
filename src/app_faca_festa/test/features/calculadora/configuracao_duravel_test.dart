import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/domain/entities/confirmacao_configuracao_calculadora.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/comando_texto_calculadora_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_configuracao_dialog.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_jornada_test.dart' show BaseJornada;
import 'calculadora_composicao_test.dart' show AiQA;
import 'publico_planejamento_test.dart' show RepoPublico;

class RepoConfiguracao extends RepoPublico {
  bool perderResposta = false;
  Completer<void>? aguardar;
  Map<String, dynamic> copia(Map<String, dynamic> m) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(m)) as Map);
  @override
  Stream<Map<String, dynamic>> observarOperacaoEvento(String id) async* {
    yield copia(operacao);
    yield* alteracoes.stream.map(copia);
  }

  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) async {
    final resultado = copia(await super.alterarOperacaoEvento(id, acao));
    await aguardar?.future;
    if (perderResposta) {
      perderResposta = false;
      throw StateError('Confirmação perdida');
    }
    return resultado;
  }
}

class BasePorPerfil extends BaseJornada {
  final perfis = <String?>[];
  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback(
      {required String tipoEvento, String? perfilFesta}) {
    perfis.add(perfilFesta);
    return super.buscarItensPorTipoEventoComFallback(
        tipoEvento: tipoEvento, perfilFesta: perfilFesta);
  }
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  Future<CalculadoraFestaController> criar(RepoConfiguracao repo) async {
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'festa', tipoEvento: 'Formatura', adultosEvento: 40);
    return c;
  }

  test(
      'confirmação perdida repete sem duplicar; id adulterado e revisão concorrente são recusados',
      () async {
    final repo = RepoConfiguracao();
    final c = await criar(repo);
    final comando = c.prepararConfirmacaoConfiguracao(
        {'duracao': 6, 'verba_alimentacao': 1450.0});
    repo.perderResposta = true;
    await expectLater(c.confirmarConfiguracao(comando), throwsStateError);
    expect(c.estadoConfiguracao.value, EstadoConfirmacaoConfiguracao.falhou);
    expect(c.duracaoHoras.value, 4);
    expect(repo.operacao['revisao'], 1);
    await c.confirmarConfiguracao(comando);
    expect(repo.operacao['revisao'], 1);
    expect(c.duracaoHoras.value, 6);
    expect(
        () => const OperacaoCalculadoraService().aplicar(
            repo.operacao,
            ConfirmacaoConfiguracaoCalculadora(
                id: comando.id,
                revisaoEsperada: 0,
                alteracoes: {'duracao': 7}).toAcao()),
        throwsStateError);
    final concorrente = ConfirmacaoConfiguracaoCalculadora(
        id: 'outra', revisaoEsperada: 0, alteracoes: {'duracao': 8});
    await expectLater(c.confirmarConfiguracao(concorrente), throwsStateError);
    expect(c.estadoConfiguracao.value, EstadoConfirmacaoConfiguracao.conflito);
    expect(c.duracaoHoras.value, 6);
  });
  test(
      'snapshots preservam nova edição e resposta tardia não alcança outro evento',
      () async {
    final repo = RepoConfiguracao();
    final c = await criar(repo);
    await c.confirmarConfiguracao(
        c.prepararConfirmacaoConfiguracao({'duracao': 6}));
    c.atualizarDuracao(7);
    c.restaurarEscolhasConfiguracao({'duracao': 8});
    expect(c.duracaoHoras.value, 7);
    expect(c.estadoConfiguracao.value, EstadoConfirmacaoConfiguracao.conflito);
    repo.aguardar = Completer<void>();
    final gravar = c.confirmarConfiguracao(
        c.prepararConfirmacaoConfiguracao({'duracao': 9}));
    await Future<void>.delayed(Duration.zero);
    // Outro evento ainda não possui estas escolhas; isola os dados do substituto.
    repo.operacao = {};
    await c.prepararCalculadora(
        idEvento: 'outra', tipoEvento: 'Formatura', adultosEvento: 20);
    repo.aguardar!.complete();
    await gravar;
    expect(c.idEventoAtual.value, 'outra');
    expect(c.duracaoHoras.value, 4);
  });
  test(
      'texto e comando manual confirmam as mesmas escolhas, incluindo margem e verba',
      () async {
    final a = RepoConfiguracao(), b = RepoConfiguracao();
    final ca = await criar(a), cb = await criar(b);
    await ca.confirmarConfiguracao(ca.prepararConfirmacaoConfiguracao({
      'duracao': 6,
      'perfil': 'premium',
      'margem': 0.1,
      'verba_alimentacao': 1450.0
    }));
    final comandos = const ComandoTextoCalculadoraService().interpretar(
        'duração 6 horas; perfil premium; margem 10%; verba 1450,00');
    await cb.aplicarComandosTexto(comandos, cb.assinaturaProposta);
    for (final k in ['duracao', 'perfil', 'margem', 'verba_alimentacao']) {
      expect(b.operacao['configuracao_planejamento'][k],
          a.operacao['configuracao_planejamento'][k]);
    }
    expect(cb.margemPersonalizada.value, .1);
  });
  testWidgets(
      'campos do modal mantêm foco com teclado em qualquer altura',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    final repo = RepoConfiguracao();
    final c = await criar(repo);
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                resizeToAvoidBottomInset: true,
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) =>
                            CalculadoraConfiguracaoDialog(controller: c)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    Future<void> conferirCampo(Finder campo, String texto) async {
      await tester.ensureVisible(campo);
      await tester.tap(campo);
      await tester.pump();
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.testTextInput.hasAnyClients, isTrue,
          reason: 'foco deve sobreviver à abertura do IME');
      await tester.enterText(campo, texto);
      await tester.pump();
      expect(tester.testTextInput.hasAnyClients, isTrue);
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();
    }

    await conferirCampo(
        find.widgetWithText(TextField, 'Margem extra'), '10');
    await conferirCampo(
        find.widgetWithText(TextField, 'Verba alimentar'), '1500,00');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'cancelar não grava; falha mantém editor e valores em tela pequena',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final repo = RepoConfiguracao();
    final c = await criar(repo);
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) =>
                            CalculadoraConfiguracaoDialog(controller: c)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Duração de referência'), '6');
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(find.text('Cancelar').hitTestable(), findsOneWidget);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.gravacoes, 0);
    expect(c.duracaoHoras.value, 4);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Duração de referência'), '6');
    final verba = find.widgetWithText(TextField, 'Verba alimentar');
    await tester.ensureVisible(verba);
    await tester.enterText(verba, '1450,00');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    repo.falhar = true;
    await tester.tap(find.text('Confirmar escolhas'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraConfiguracaoDialog), findsOneWidget);
    expect(c.duracaoHoras.value, 4);
    expect(repo.gravacoes, 0);
    expect(find.textContaining('Sem conexão'), findsOneWidget);
    repo.falhar = false;
    await tester.tap(find.text('Confirmar escolhas'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraConfiguracaoDialog), findsNothing);
    expect(c.duracaoHoras.value, 6);
    expect(c.verbaAlimentacao.value, 1450);
    expect(tester.takeException(), isNull);
  });
  test('zero de margem e verba permanece conhecido; limpar é ausência',
      () async {
    final repo = RepoConfiguracao();
    final c = await criar(repo);
    await c.confirmarConfiguracao(c.prepararConfirmacaoConfiguracao(
        {'margem': 0.0, 'verba_alimentacao': 0.0}));
    await c.prepararCalculadora(
        idEvento: 'festa', tipoEvento: 'Formatura', adultosEvento: 40);
    expect(c.margemPersonalizada.value, 0);
    expect(c.verbaAlimentacao.value, 0);
    await c.confirmarConfiguracao(c.prepararConfirmacaoConfiguracao(
        {'margem': null, 'verba_alimentacao': null}));
    await c.prepararCalculadora(
        idEvento: 'festa', tipoEvento: 'Formatura', adultosEvento: 40);
    expect(c.margemPersonalizada.value, isNull);
    expect(c.verbaAlimentacao.value, isNull);
  });
  test(
      'restaurar perfil recarrega o catálogo correspondente antes de concluir a preparação',
      () async {
    final repo = RepoConfiguracao();
    final base = BasePorPerfil();
    repo.operacao = {
      'versao': 1,
      'revisao': 1,
      'configuracao_planejamento': {'perfil': 'premium', 'duracao': 6}
    };
    final c = CalculadoraFestaController(
        repository: repo, itensBaseRepository: base, aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'festa', tipoEvento: 'Formatura', adultosEvento: 40);
    expect(base.perfis.last, 'premium');
    expect(c.carregandoItensBase.value, isFalse);
    expect(c.perfilSelecionado.value.tipo.name, 'premium');
  });
  test('6 horas e verba 1450 sobrevivem à nova preparação', () async {
    final repo = RepoConfiguracao();
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'festa', tipoEvento: 'Formatura', adultosEvento: 40);
    await c.confirmarConfiguracao(c.prepararConfirmacaoConfiguracao(
        {'duracao': 6, 'verba_alimentacao': 1450.0}));
    expect(repo.operacao['configuracao_planejamento']['duracao'], 6);
    await c.prepararCalculadora(
        idEvento: 'festa', tipoEvento: 'Formatura', adultosEvento: 40);
    expect(c.operacaoEvento['configuracao_planejamento']['duracao'], 6);
    expect(c.duracaoHoras.value, 6);
    expect(c.verbaAlimentacao.value, 1450);
  });
}
