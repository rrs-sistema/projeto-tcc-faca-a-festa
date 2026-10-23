import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/evento_remote_ds.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/evento_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA, regraQA;
import '../test/features/calculadora/calculadora_jornada_test.dart'
    show BaseJornada;

// Upload está fora do escopo: qualquer chamada acidental falha no sentinela.
class StorageSemUpload extends Fake implements FirebaseStorage {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'SDK real: identidade única, vínculo transacional e histórico preservado',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Somente harness demo.');
    }
    const projeto = 'demo-cadastro-vinculo';
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: projeto,
            storageBucket: 'demo-cadastro-vinculo.appspot.com'));
    if (!app.options.projectId.startsWith('demo-')) {
      throw StateError('Projeto não demo recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app);
    final db = FirebaseFirestore.instanceFor(app: app);
    db.settings = const Settings(persistenceEnabled: false);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'cadastro-owner@example.test', password: 'TesteLocal123!');
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    final storage = StorageSemUpload();
    final eventos =
        EventoRepositoryImpl(EventoRemoteDatasource(db, storage: storage));
    final evento = Evento(
        idEvento: 'cadastro-duravel',
        idUsuario: 'cadastro-owner',
        idTipoEvento: 'formatura',
        nomeEvento: 'Evento sintético',
        localEvento: '',
        data: DateTime(2026, 12),
        totalAdultos: 40,
        custoEstimado: 2500);
    await eventos.salvar(evento);
    await eventos.salvar(evento);
    final lista = await db
        .collection('evento')
        .where('id_usuario', isEqualTo: 'cadastro-owner')
        .get();
    expect(lista.docs.where((d) => d.id == evento.idEvento).length, 1);
    final repo = CalculadoraFestaRepositoryImpl(
        CalculadoraFestaRemoteDatasource(firestore: db, auth: auth));
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    final r = RascunhoCalculadora(
        id: 'local-estavel',
        tipoEvento: 'Formatura',
        adultos: 10,
        criancas: 0,
        bebes: 0,
        duracaoHoras: 4,
        perfil: PerfilFesta.padrao(),
        criadoEm: DateTime.utc(2026, 10, 19),
        limite: 1000,
        contexto: {
          'versao_motor': 6,
          'regras_manuais': [regraQA('Arroz').toPlanejamento()],
          'regras_catalogo': []
        });
    await c.vincularRascunho(r, evento);
    final ref = db
        .collection('calculadora_festa')
        .doc(r.calculoPara(evento.idEvento, evento.idUsuario, 2500).idCalculo);
    final salvo = (await ref.get()).data()!;
    expect(salvo['total_adultos'], 40);
    expect(salvo['orcamento_disponivel'], 2500);
    await ref.update({'total_adultos': 41});
    await c.vincularRascunho(r, evento);
    expect((await ref.get()).data()!['total_adultos'], 41);
    expect(
        (await db
                .collection('calculadora_festa')
                .where('id_evento', isEqualTo: evento.idEvento)
                .get())
            .docs
            .length,
        1);
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'cadastro-other@example.test', password: 'TesteLocal123!');
    await expectLater(
        ref.get(),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')));
    await expectLater(c.vincularRascunho(r, evento), throwsStateError);
    c.onClose();
    Get.reset();
    await auth.signOut();
  });
}
