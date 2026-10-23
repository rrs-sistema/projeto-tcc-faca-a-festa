// Apenas pacote QA e projeto demo em emuladores; não acessa o evento real.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_entrada_inteligente_dialog.dart';
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;
import '../test/features/calculadora/calculadora_jornada_test.dart'
    show BaseJornada;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'aparelho: autenticação, proposta, revisão, gravação e duplicidade via SDK real',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Somente pacote QA isolado.');
    }
    final app = await Firebase.initializeApp(
        name: 'calculadora-qa',
        options: const FirebaseOptions(
            // Syntactically valid, fictitious key: required by the native SDK
            // even when Auth/Firestore/Functions use local emulators.
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-calculadora-entrada'));
    final auth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);
    db.settings = const Settings(persistenceEnabled: false);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    final functions =
        FirebaseFunctions.instanceFor(app: app, region: 'southamerica-east1');
    functions.useFunctionsEmulator('127.0.0.1', 5001,
        automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'qa-calculadora@example.test', password: 'TesteLocal123!');
    Get.put<FirebaseAuth>(auth);
    final repo = CalculadoraFestaRepositoryImpl(
        CalculadoraFestaRemoteDatasource(
            firestore: db, auth: auth, functions: functions));
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    c.idEventoAtual.value = 'festa';
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('QA • Leitura inteligente')),
                body: Center(
                    child: FilledButton(
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => CalculadoraEntradaInteligenteDialog(
                                controller: c,
                                textoInicial:
                                    'Comprei 5 kg de arroz cru para o almoço.')),
                        child: const Text('Ler compra de teste')))))));
    await tester.tap(find.text('Ler compra de teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar leitura'));
    for (var i = 0;
        i < 450 && find.text('Aplicar 1 ação(ões)').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Aplicar 1 ação(ões)'), findsOneWidget,
        reason: tester.allWidgets.whereType<Text>().map((t) => t.data).join(' | '));
    final antes = (await db.doc('cardapios/almoco/itens/arroz').get()).data()!;
    expect(antes['disponibilidade']['comprado'], 2);
    await tester.tap(find.text('Aplicar 1 ação(ões)'));
    for (var i = 0;
        i < 150 &&
            find
                .byType(CalculadoraEntradaInteligenteDialog)
                .evaluate()
                .isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(CalculadoraEntradaInteligenteDialog), findsNothing);
    final depois = (await db.doc('cardapios/almoco/itens/arroz').get()).data()!;
    expect(depois['disponibilidade']['comprado'], 7);
    expect(depois['quantidade_final'], 10);
    expect(depois['confirmado'], true);
    final repetido = await repo.interpretarEntradaCalculadora({
      'evento': 'festa',
      'texto': 'Comprei 5 kg de arroz cru para o almoço.',
      'documento': true,
      'regras': [],
      'anexo': {}
    });
    expect(repetido['acoes'], isEmpty);
    expect(repetido['ja_registradas'], 1);
    await auth.signOut();
    await expectLater(
        repo.interpretarEntradaCalculadora(
            {'evento': 'festa', 'texto': 'teste', 'regras': []}),
        throwsStateError);
    c.onClose();
    Get.reset();
  });
}
