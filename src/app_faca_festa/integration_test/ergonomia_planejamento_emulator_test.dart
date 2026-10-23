import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_comando_texto_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;
import '../test/features/calculadora/calculadora_jornada_test.dart'
    show BaseJornada;
import '../test/features/calculadora/ajustes_manuais_persistencia_test.dart'
    show ajuste;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'editores reais confirmam no Firestore e retomam escolhas e preço sem redigitar',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Use o harness demo local.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-ergonomia10'));
    if (app.options.projectId != 'demo-ergonomia10') {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'ergonomia-owner@example.test', password: 'TesteLocal123!');
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    final repo = CalculadoraFestaRepositoryImpl(
        CalculadoraFestaRemoteDatasource(firestore: db, auth: auth));
    Future<CalculadoraFestaController> abrir() async {
      final c = CalculadoraFestaController(
          repository: repo,
          itensBaseRepository: BaseJornada(),
          aiService: AiQA());
      await c.prepararCalculadora(
          idEvento: 'festa10', tipoEvento: 'Formatura', adultosEvento: 20);
      await c.iniciarOperacaoEvento();
      for (var i = 0; i < 150 && !c.operacaoCarregada.value; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      if (!c.operacaoCarregada.value) {
        throw StateError('A operação não foi carregada.');
      }
      return c;
    }

    final c = await abrir();
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) =>
                            CalculadoraComandoTextoDialog(controller: c)),
                    child: const Text('Editar escolhas'))))));
    await tester.tap(find.text('Editar escolhas'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField), 'planeje para 30 adultos; duração 6 horas');
    await tester.tap(find.text('Preparar ajustes'));
    await tester.pumpAndSettle();
    expect(c.totalAdultos.value, 20);
    await tester.tap(find.text('Usar estes ajustes'));
    for (var i = 0;
        i < 150 &&
            find.byType(CalculadoraComandoTextoDialog).evaluate().isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byType(CalculadoraComandoTextoDialog), findsNothing);
    final salvo = (await db.doc('calculadora_operacao/festa10').get()).data()!;
    expect(salvo['configuracao_planejamento']['publico']['adultos'], 30);
    expect(salvo['configuracao_planejamento']['duracao'], 6);
    expect((await db.doc('evento/festa10').get()).data()!['total_adultos'], 20);
    c.onClose();
    final retomado = await abrir();
    expect(retomado.totalAdultos.value, 30);
    expect(retomado.duracaoHoras.value, 6);
    final regra = ajuste('almoco', 5.75, 'seco').copyWith(premissas: {
      ...ajuste('almoco', 5.75, 'seco').premissas,
      'id_evento': 'festa10'
    });
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) => CalculadoraRegraManualDialog(
                            inicial: regra,
                            onSalvar: (editada) => retomado.salvarItemManual(
                                editada,
                                anterior:
                                    retomado.regraPersistida(editada.id)))),
                    child: const Text('Editar preço'))))));
    await tester.tap(find.text('Editar preço'));
    await tester.pumpAndSettle();
    final preco = find.widgetWithText(TextFormField, 'Preço por kg');
    await tester.ensureVisible(preco);
    await tester.enterText(preco, '850');
    await tester.ensureVisible(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar no cálculo'));
    for (var i = 0;
        i < 150 &&
            find.byType(CalculadoraRegraManualDialog).evaluate().isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byType(CalculadoraRegraManualDialog), findsNothing);
    expect(
        (await db.doc('calculadora_operacao/festa10').get())
            .data()!['execucao']['regras']
            .single['preco'],
        8.5);
    retomado.onClose();
    final novamente = await abrir();
    expect(novamente.regraPersistida(regra.id)!['preco'], 8.5);
    novamente.onClose();
    await auth.signOut();
    Get.reset();
    expect(tester.takeException(), isNull);
  });
}
