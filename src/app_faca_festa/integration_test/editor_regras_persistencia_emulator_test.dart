import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';

import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;
import '../test/features/calculadora/calculadora_jornada_test.dart'
    show BaseJornada;

/// Cancelar e confirmar a regra no editor real, com Auth, regras e Firestore
/// do emulador. AiQA e BaseJornada só satisfazem o construtor: esta prova não
/// chama interpretação nem usa o catálogo substituto como cardápio.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const eventoId = 'festa-regras';
  const regraId = 'menu_almoco_arroz';
  const projeto = 'demo-regras12';

  testWidgets(
      'cancelar e fechar a regra não gravam; confirmar persiste e retoma sem histórico',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Use o harness demo local.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: projeto));
    if (app.options.projectId != projeto) {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'regras-owner@example.test', password: 'TesteLocal123!');
    final dono = auth.currentUser!.uid;
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    final repo = CalculadoraFestaRepositoryImpl(
        CalculadoraFestaRemoteDatasource(firestore: db, auth: auth));

    Future<Map<String, dynamic>> operacao() async =>
        (await db.doc('calculadora_operacao/$eventoId').get()).data()!;
    Future<Map<String, dynamic>> evento() async =>
        (await db.doc('evento/$eventoId').get()).data()!;
    Future<Map<String, dynamic>> historico() async =>
        (await db.doc('calculadora_festa/hist-regras12').get()).data()!;

    Future<CalculadoraFestaController> abrir() async {
      final c = CalculadoraFestaController(
          repository: repo,
          itensBaseRepository: BaseJornada(),
          aiService: AiQA());
      await c.prepararCalculadora(
          idEvento: eventoId, tipoEvento: 'Corporativo', adultosEvento: 20);
      await c.iniciarOperacaoEvento();
      for (var i = 0; i < 150 && !c.operacaoCarregada.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      if (!c.operacaoCarregada.value) {
        throw StateError(c.erroOperacao.value.isEmpty
            ? 'A operação não foi carregada.'
            : c.erroOperacao.value);
      }
      if (c.usandoContextoHistorico.value) {
        throw StateError('A retomada abriu um histórico.');
      }
      return c;
    }

    Future<void> abrirEditor(CalculadoraFestaController c) async {
      await tester.pumpWidget(GetMaterialApp(
          home: Builder(
              builder: (ctx) => Scaffold(
                  body: TextButton(
                      onPressed: () {
                        final sessao = c.sessaoPlanejador;
                        final anterior =
                            jsonDecode(jsonEncode(c.regraPersistida(regraId)))
                                as Map<String, dynamic>;
                        final inicial =
                            ItemEstimativaFinanceira.fromPlanejamento(anterior);
                        showDialog<void>(
                            context: ctx,
                            builder: (_) => CalculadoraRegraManualDialog(
                                inicial: inicial,
                                nome: inicial.nome,
                                id: inicial.id,
                                unidade: inicial.unidade,
                                publico: inicial.publicoAlvo,
                                tipo: inicial.tipoItem,
                                confirmarLabel: 'Salvar porção e preço',
                                onSalvar: (editada) async {
                                  if (c.idEventoAtual.value != eventoId ||
                                      c.sessaoPlanejador != sessao) {
                                    throw StateError(
                                        'O evento mudou. Reabra o ajuste para salvar.');
                                  }
                                  await c.salvarItemManual(
                                      editada.copyWith(premissas: {
                                        ...editada.premissas,
                                        'id_cardapio': 'almoco',
                                        'id_item_cardapio': 'arroz',
                                      }),
                                      anterior: anterior);
                                }));
                      },
                      child: const Text('Editar regra'))))));
      await tester.tap(find.text('Editar regra'));
      await tester.pumpAndSettle();
      expect(find.byType(CalculadoraRegraManualDialog), findsOneWidget);
      expect(find.text('Salvar porção e preço').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Fechar').hitTestable(), findsOneWidget);
    }

    Future<void> editar(String preco, String consumo) async {
      final campoPreco = find.widgetWithText(TextFormField, 'Preço por kg');
      await tester.ensureVisible(campoPreco);
      await tester.pumpAndSettle();
      await tester.enterText(campoPreco, preco);
      final campoConsumo =
          find.widgetWithText(TextFormField, 'Quantidade por convidado');
      await tester.ensureVisible(campoConsumo);
      await tester.pumpAndSettle();
      await tester.enterText(campoConsumo, consumo);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    Future<void> aguardarFechar() async {
      for (var i = 0;
          i < 150 &&
              find.byType(CalculadoraRegraManualDialog).evaluate().isNotEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      final erro = find.byKey(const Key('erro_salvar_regra'));
      if (erro.evaluate().isNotEmpty) {
        throw StateError(tester.widget<Text>(erro).data ?? 'Falha ao salvar.');
      }
      expect(find.byType(CalculadoraRegraManualDialog), findsNothing);
    }

    Map<String, dynamic> regraDe(Map<String, dynamic> dados) {
      final regras = (dados['execucao'] as Map)['regras'] as List;
      expect(regras, hasLength(1));
      return Map<String, dynamic>.from(regras.single as Map);
    }

    final antes = await operacao();
    final eventoAntes = await evento();
    final historicoAntes = await historico();
    expect(regraDe(antes)['preco'], 5.75);
    expect(regraDe(antes)['consumo'], 0.05);
    expect(antes['revisao'], 1);

    final c = await abrir();
    expect(c.regraPersistida(regraId)!['preco'], 5.75);
    expect(c.regrasManuais.single.valorUnitarioMedio, 5.75);
    expect(await operacao(), antes, reason: 'carregar a operação não grava');

    await abrirEditor(c);
    await editar('999', '0,2');
    expect(find.text('Cancelar').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraRegraManualDialog), findsNothing);
    expect(await operacao(), antes, reason: 'cancelar não grava');
    expect(c.regraPersistida(regraId)!['preco'], 5.75);
    expect(c.regrasManuais.single.valorUnitarioMedio, 5.75);
    expect(c.regrasManuais.single.quantidadePorConvidadoEquivalente, 0.05);

    await abrirEditor(c);
    await editar('111', '0,3');
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraRegraManualDialog), findsNothing);
    expect(await operacao(), antes, reason: 'fechar não grava');
    expect(await evento(), eventoAntes);
    expect(await historico(), historicoAntes);

    await abrirEditor(c);
    await editar('850', '0,08');
    final preco = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Preço por kg'));
    expect(preco.controller!.text, contains('8,50'));
    await tester.ensureVisible(find.text('Salvar porção e preço'));
    await tester.pumpAndSettle();
    expect(find.text('Salvar porção e preço').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Salvar porção e preço'));
    await aguardarFechar();

    final confirmada = await operacao();
    final regra = regraDe(confirmada);
    expect(regra['preco'], 8.5);
    expect(regra['consumo'], closeTo(0.08, 1e-9));
    expect(regra['nome'], 'Arroz');
    expect(confirmada['revisao'], 2);
    expect(confirmada['configuracao_planejamento'],
        antes['configuracao_planejamento']);
    expect(c.regraPersistida(regraId)!['preco'], 8.5);
    expect(c.regrasManuais.single.valorUnitarioMedio, 8.5);
    expect(
        (await db.collection('calculadora_operacao/$eventoId/aplicacoes').get())
            .size,
        0);
    expect(await evento(), eventoAntes);
    expect(await historico(), historicoAntes);
    c.onClose();

    final retomado = await abrir();
    expect(retomado.usandoContextoHistorico.value, isFalse);
    expect(retomado.regraPersistida(regraId)!['preco'], 8.5);
    expect(retomado.regraPersistida(regraId)!['consumo'], closeTo(0.08, 1e-9));
    expect(retomado.regrasManuais, hasLength(1));

    await abrirEditor(retomado);
    await tester.ensureVisible(find.text('Salvar porção e preço'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar porção e preço'));
    await aguardarFechar();
    final repetida = await operacao();
    expect(regraDe(repetida)['id'], regraId);
    expect(regraDe(repetida)['preco'], 8.5);
    expect(regraDe(repetida)['consumo'], closeTo(0.08, 1e-9));
    expect((repetida['execucao'] as Map)['regras'], hasLength(1));
    expect(await historico(), historicoAntes);
    final revisaoRepetida = repetida['revisao'];
    retomado.onClose();

    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'regras-outro@example.test', password: 'TesteLocal123!');
    expect(auth.currentUser!.uid, isNot(dono));
    await expectLater(
        db.doc('calculadora_operacao/$eventoId').get(),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')));
    await expectLater(
        db.doc('calculadora_operacao/$eventoId').update({'revisao': 99}),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')));
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'regras-owner@example.test', password: 'TesteLocal123!');
    final depoisDoIntruso = await operacao();
    expect(depoisDoIntruso['revisao'], revisaoRepetida);
    expect(regraDe(depoisDoIntruso)['preco'], 8.5);
    expect((depoisDoIntruso['execucao'] as Map)['regras'], hasLength(1));
    expect(await historico(), historicoAntes);
    expect(await evento(), eventoAntes);

    await auth.signOut();
    Get.reset();
    expect(tester.takeException(), isNull);
  });
}
