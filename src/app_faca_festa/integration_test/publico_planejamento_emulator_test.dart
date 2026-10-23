import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/evento_remote_ds.dart';
import 'package:app_faca_festa/data/datasources/remote/convidado_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/convidado_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/evento_repository_impl.dart';
import 'package:app_faca_festa/domain/repositories/presente_reservation_repository.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/services/publico_planejamento_service.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;
import '../test/features/calculadora/calculadora_jornada_test.dart'
    show BaseJornada;

class SemUpload extends Fake implements FirebaseStorage {}

class SemPresentes extends Fake implements PresenteReservationRepository {}

Future<void> esperar(bool Function() condicao) async {
  for (var i = 0; i < 150; i++) {
    if (condicao()) return;
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
  throw StateError('A fonte emulada não entregou o estado esperado.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'SDK real: previsão, declaração privada, escolha, manual e público próprio',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Somente demo local.');
    }
    const eventoId = String.fromEnvironment('PUBLICO_QA_EVENTO');
    if (!RegExp(r'^publico-festa-[0-9]+$').hasMatch(eventoId)) {
      throw StateError('Use o harness local com evento sintético único.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-publico-planejamento'));
    if (app.options.projectId != 'demo-publico-planejamento') {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'publico-owner@example.test', password: 'TesteLocal123!');
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    final eventos =
        EventoRepositoryImpl(EventoRemoteDatasource(db, storage: SemUpload()));
    final evento = Evento(
        idEvento: eventoId,
        idUsuario: 'publico-owner',
        idTipoEvento: 'tipo',
        nomeEvento: 'Evento sintético',
        localEvento: '',
        data: DateTime(2026),
        totalConvidados: 40,
        totalAdultos: 40,
        totalCriancas: 0,
        totalBebes: 0);
    await eventos.salvar(evento);
    final repo = CalculadoraFestaRepositoryImpl(
        CalculadoraFestaRemoteDatasource(firestore: db, auth: auth));
    final convidadosRepo =
        ConvidadoRepositoryImpl(ConvidadoRemoteDatasource(db));
    final convidados = ConvidadoController(
        repository: convidadosRepo,
        presenteReservationRepository: SemPresentes(),
        planejamentoResolver: () => repo,
        usuarioContexto: () => auth.currentUser?.uid);
    CalculadoraFestaController criar() => CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    final c = criar();
    await c.prepararCalculadora(
        idEvento: evento.idEvento,
        tipoEvento: 'Formatura',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    await c.iniciarOperacaoEvento();
    await esperar(() => c.operacaoCarregada.value);
    await convidados.escutarConvidados(evento.idEvento);
    await esperar(() => !convidados.carregando.value);
    final worker = ever(
        convidados.convidados,
        (_) => c.sincronizarConvidados(convidados.convidados.toList(),
            eventoFonte: convidados.idEventoAtual.value));
    final um = Convidado(
        idConvidado: 'primeiro-publico',
        idEvento: evento.idEvento,
        nome: 'Pessoa sintética',
        contato: '',
        dataCadastro: DateTime.now(),
        dataAtualizacao: DateTime.now());
    await convidadosRepo.salvar(um);
    await esperar(() => convidados.convidados.length == 1);
    expect(c.totalConvidados, 40);
    await c.declararCompletude(CompletudeLista.emPreenchimento,
        assinatura: c.contextoEvento.assinatura);
    await esperar(() =>
        convidados.configuracaoPublico['lista_completude'] ==
        'em_preenchimento');
    expect(convidados.publicoPlanejadoDoEvento(evento).total, 40);
    await c.confirmarBasePublico(BaseCalculoFesta.apenasConfirmados,
        assinatura: c.contextoEvento.assinatura);
    expect(c.totalConvidados, 0);
    c.atualizarTotaisManuais(adultos: 7, criancas: 0, bebes: 0);
    await c.confirmarBasePublico(BaseCalculoFesta.manual,
        assinatura: c.contextoEvento.assinatura);
    await db.collection('cardapios').doc('${evento.idEvento}-refeicao').set({
      'id_evento': evento.idEvento,
      'ativo': true,
      'titulo': 'Refeição sintética'
    });
    await c.alterarOperacao({
      'tipo': 'refeicao',
      'id_cardapio': '${evento.idEvento}-refeicao',
      'config': {
        'publico': {'adultos': 8, 'criancas': 2, 'bebes': 0}
      }
    });
    await convidadosRepo.salvar(um.copyWith(
        status: StatusConvidado.confirmado, dataAtualizacao: DateTime.now()));
    await esperar(() => convidados.totalConfirmados == 1);
    expect(c.totalConvidados, 7);
    expect(
        c.publicoDaRefeicao('${evento.idEvento}-refeicao').totalInformado, 10);
    final novo = criar();
    await novo.prepararCalculadora(
        idEvento: evento.idEvento,
        tipoEvento: 'Formatura',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    await novo.iniciarOperacaoEvento();
    await esperar(() => novo.operacaoCarregada.value);
    expect(novo.baseCalculo.value, BaseCalculoFesta.manual);
    expect(novo.totalConvidados, 7);
    await novo.declararCompletude(CompletudeLista.concluida,
        assinatura: novo.contextoEvento.assinatura);
    final privado =
        (await db.collection('calculadora_operacao').doc(evento.idEvento).get())
            .data()!;
    expect(
        privado['configuracao_planejamento']['lista_completude'], 'concluida');
    final publico =
        (await db.collection('evento').doc(evento.idEvento).get()).data()!;
    expect(publico.containsKey('configuracao_planejamento'), isFalse);
    worker.dispose();
    convidados.onClose();
    c.onClose();
    novo.onClose();
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'publico-other@example.test', password: 'TesteLocal123!');
    await expectLater(
        db.collection('calculadora_operacao').doc(evento.idEvento).get(),
        throwsA(isA<FirebaseException>()
            .having((e) => e.code, 'code', 'permission-denied')));
    await auth.signOut();
    Get.reset();
  });
}
