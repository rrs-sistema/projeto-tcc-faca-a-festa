import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_faca_festa/data/local/cadastro_armazenamento_io.dart';
import 'package:app_faca_festa/data/datasources/remote/agenda_servico_remote.dart';
import 'package:app_faca_festa/data/datasources/remote/plano_execucao_remote_datasource.dart';
import 'package:app_faca_festa/domain/services/plano_execucao_service.dart';
import '../test/features/calculadora/plano_execucao_test.dart' show regraExec;
import '../test/features/calculadora/plano_evento_test.dart' show calculo;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'recupera recibo durável após resposta perdida e reinício do adaptador',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Use o harness demo local.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-calculadora-execucao'));
    if (app.options.projectId != 'demo-calculadora-execucao') {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'execucao-owner@example.test', password: 'TesteLocal123!');
    final pasta = await Directory.systemTemp.createTemp('execucao-recibo-');
    addTearDown(() async {
      await pasta.delete(recursive: true);
    });
    final armazenamento = CadastroArquivos(diretorio: pasta),
        url = Uri.parse(
            'http://127.0.0.1:5001/demo-calculadora-execucao/southamerica-east1/aplicarPlanoCalculadora');
    final remoto = PlanoExecucaoRemoteDatasource(db, auth,
        emulador: url, recuperacao: armazenamento);
    final fontes = await remoto.carregar('evento');
    final proposta = const PlanoExecucaoService().gerar(
        pedido: 'resposta-perdida',
        contexto: fontes,
        calculo: calculo(pessoas: 20).copyWith(margemPersonalizada: 0),
        regras: [regraExec('almoco'), regraExec('janta')]);
    final perdeResposta = PlanoExecucaoRemoteDatasource(db, auth,
        recuperacao: armazenamento, enviar: (command) async {
      await CallableCalculadoraRemote(auth, emulador: url)
          .chamar('aplicarPlanoCalculadora', command);
      throw StateError('Resposta perdida depois do commit remoto');
    });
    await expectLater(perdeResposta.aplicar(proposta), throwsStateError);
    expect((await armazenamento.listar('execucao_v1_')).length, 1);
    final antes = await db
        .collection('tarefa')
        .where('id_evento', isEqualTo: 'evento')
        .get();
    final reiniciado = PlanoExecucaoRemoteDatasource(db, auth,
        emulador: url, recuperacao: CadastroArquivos(diretorio: pasta));
    final recuperado = await reiniciado.carregar('evento');
    expect(recuperado.recibosRecuperados, ['resposta-perdida']);
    expect(await armazenamento.listar('execucao_v1_'), isEmpty);
    expect(await reiniciado.aplicar(proposta), false);
    final depois = await db
        .collection('tarefa')
        .where('id_evento', isEqualTo: 'evento')
        .get();
    expect(depois.docs.map((d) => d.id).toSet(),
        antes.docs.map((d) => d.id).toSet());
    expect(recuperado.operacao['execucao']['pedido'], 'resposta-perdida');
    expect(
        (await db.doc('cardapios/almoco/itens/arroz').get())
            .data()!['quantidade_final'],
        7);
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'execucao-other@example.test', password: 'TesteLocal123!');
    await expectLater(reiniciado.aplicar(proposta), throwsStateError);
    await expectLater(
        db.doc('calculadora_operacao/evento/aplicacoes/resposta-perdida').get(),
        throwsA(isA<FirebaseException>()));
    expect(await armazenamento.listar('execucao_v1_'), isEmpty);
    await auth.signOut();
  });
}
