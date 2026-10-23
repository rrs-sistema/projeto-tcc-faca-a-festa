import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/repositories/execucao_calculadora_repository.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_execucao_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_ficha_tecnica_dialog.dart';
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'calculadora_composicao_test.dart' show AiQA;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;
import 'plano_execucao_test.dart' show contextoExec, regraExec;

class RepositorioExecucao extends RepoJornada
    implements ExecucaoCalculadoraRepository {
  bool falhar = false;
  int aplicacoes = 0;
  PropostaExecucaoPlano? ultimo;
  Completer<ContextoExecucaoPlano>? consultaPendente;
  Completer<bool>? aplicacaoPendente;
  @override
  Future<ContextoExecucaoPlano> carregarContextoExecucao(String evento) async =>
      consultaPendente != null
          ? await consultaPendente!.future
          : contextoExec(informado: false);
  @override
  Future<bool> aplicarPlanoExecucao(PropostaExecucaoPlano proposta) async {
    aplicacoes++;
    if (aplicacaoPendente != null) return aplicacaoPendente!.future;
    if (falhar) throw StateError('Falha de conexão simulada');
    ultimo = proposta;
    return true;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
  });
  tearDown(() => Get.reset());
  test('respostas de leitura e aplicação não atravessam a reabertura do evento',
      () async {
    final repo = RepositorioExecucao();
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    Future<void> abrir() => c.prepararCalculadora(
        idEvento: 'evento',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    await abrir();
    repo.consultaPendente = Completer<ContextoExecucaoPlano>();
    final consulta = c.carregarExecucao();
    final rejeitada = expectLater(consulta, throwsStateError);
    await abrir();
    repo.consultaPendente!.complete(contextoExec(operacao: {
      'execucao': {
        'regras': [regraExec('almoco').toPlanejamento()]
      }
    }));
    await rejeitada;
    expect(c.regrasManuais, isEmpty);
    c.regrasManuais.assignAll([regraExec('almoco'), regraExec('janta')]);
    final proposta = c.proporExecucao(contextoExec(), 'tardio');
    repo.aplicacaoPendente = Completer<bool>();
    final aplicacao = c.aplicarExecucao(proposta, c.assinaturaProposta);
    await abrir();
    final antes = assinaturaExecucao(Map.of(c.operacaoEvento));
    repo.aplicacaoPendente!.complete(true);
    await aplicacao;
    expect(assinaturaExecucao(Map.of(c.operacaoEvento)), antes);
    expect(c.regrasManuais, isEmpty);
  });
  testWidgets(
      'revisão compacta invalida contexto, atualiza fontes, mantém erro e permite retomar sem alterar fatos',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.runAsync(() async {
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
          .load();
    });
    final captura = GlobalKey();
    final repo = RepositorioExecucao();
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'evento',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    c.regrasManuais.assignAll([regraExec('almoco'), regraExec('janta')]);
    await tester.pumpWidget(GetMaterialApp(
        builder: (_, child) => RepaintBoundary(key: captura, child: child!),
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<bool>(
                        context: ctx,
                        builder: (_) =>
                            CalculadoraExecucaoDialog(controller: c)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    final declarar =
        find.text('Ainda não comprei itens sem disponibilidade');
    await tester.ensureVisible(declarar);
    await tester.tap(declarar);
    await tester.pumpAndSettle();
    if (Platform.environment['CALCULADORA_QA_CAPTURE'] == '1') {
      await tester.ensureVisible(find.text('Arroz'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            captura.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final imagem = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
        final arquivo = File('.dart_tool/qa-calculadora/plano-execucao.png');
        await arquivo.parent.create(recursive: true);
        await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
        imagem.dispose();
      });
    }
    c.totalAdultos.value = 21;
    await tester.tap(find.text('Aplicar conjunto'));
    await tester.pumpAndSettle();
    expect(repo.aplicacoes, 0);
    expect(find.byKey(const Key('erro_execucao')), findsOneWidget);
    final atualizar = find.text('Atualizar pelas fontes atuais');
    await tester.ensureVisible(atualizar);
    await tester.tap(atualizar);
    await tester.pumpAndSettle();
    repo.falhar = true;
    await tester.tap(find.text('Aplicar conjunto'));
    await tester.pumpAndSettle();
    expect(repo.aplicacoes, 1);
    expect(repo.ultimo, isNull);
    repo.falhar = false;
    await tester.tap(find.text('Aplicar conjunto'));
    await tester.pumpAndSettle();
    expect(repo.aplicacoes, 2);
    expect(find.byType(CalculadoraExecucaoDialog), findsNothing);
    expect(
        repo.ultimo!
                .alteracoes['cardapios/almoco/itens/arroz']!['disponibilidade']
            ['comprado'],
        0);
    expect(
        repo.ultimo!.alteracoes.values
            .any((m) => m.containsKey('quantidade_final')),
        false);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'ficha aceita decimais, mantém ações com teclado e retorna ingredientes estruturados',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    Map<String, dynamic>? ficha;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      ficha = await showDialog<Map<String, dynamic>>(
                          context: ctx,
                          builder: (_) => const CalculadoraFichaTecnicaDialog(
                              prato: 'Receita',
                              unidade: 'kg',
                              estado: 'pronto'));
                    },
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '2,5');
    await tester.ensureVisible(find.text('Adicionar ingrediente'));
    await tester.tap(find.text('Adicionar ingrediente'));
    await tester.pumpAndSettle();
    final campos = find.byType(TextFormField);
    await tester.ensureVisible(campos.at(1));
    await tester.enterText(campos.at(1), 'Ingrediente da receita');
    await tester.ensureVisible(campos.at(2));
    await tester.enterText(campos.at(2), '1,25');
    await tester.tap(find.text('Usar ficha'));
    await tester.pumpAndSettle();
    expect(ficha!['rendimento'], 2.5);
    expect(ficha!['ingredientes'][0]['quantidade'], 1.25);
    expect(ficha!['estado'], 'pronto');
    expect(tester.takeException(), isNull);
  });
}
