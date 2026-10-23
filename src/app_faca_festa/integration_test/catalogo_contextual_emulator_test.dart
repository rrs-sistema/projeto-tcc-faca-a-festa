import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_itens_base_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora/calculadora_itens_base_repository_impl.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import '../test/features/calculadora/catalogo_contextual_test.dart'
    show referenciaQA, respostasQA;
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'publicação e consumo reais: rascunho, versões, permissões, confirmação e histórico',
      (tester) async {
    const evento = String.fromEnvironment('CATALOGO_QA_EVENTO');
    if (!const bool.fromEnvironment('CALCULADORA_QA') ||
        !RegExp(r'^catalogo-[0-9]+$').hasMatch(evento)) {
      throw StateError('Use o harness demo local.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-catalogo-contextual'));
    if (app.options.projectId != 'demo-catalogo-contextual') {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    Future<void> entrar(String papel) async {
      await auth.signOut();
      await auth.signInWithEmailAndPassword(
          email: 'catalogo-$papel@example.test', password: 'TesteLocal123!');
    }

    final base = CalculadoraItensBaseRepositoryImpl(
        CalculadoraItensBaseRemoteDatasource(
            firestore: db,
            auth: auth,
            catalogoEmulador: Uri.parse(
                'http://127.0.0.1:5001/demo-catalogo-contextual/southamerica-east1/editarCatalogoCalculadora')));
    final r = referenciaQA(extra: {'aprovado_por': null, 'aprovado_em': null});
    await entrar('owner');
    await expectLater(
        base.publicarReferencia(r, 0, 'negado'), throwsStateError);
    await entrar('admin');
    await base.salvarRascunhoReferencia(r, 0);
    expect((await base.carregarCatalogoContextual()).referencias, isEmpty);
    final pedido = const Uuid().v4();
    final aprovado = await base.publicarReferencia(r, 0, pedido);
    expect(aprovado.dados['aprovado_por'], 'catalogo-admin');
    await base.publicarReferencia(r, 0, pedido);
    expect(
        (await db
                .collection(
                    'calculadora_itens_base/${r.id}/versoes_contextuais')
                .get())
            .size,
        1);
    await expectLater(
        base.publicarReferencia(referenciaQA(porcao: .9), 0, pedido),
        throwsStateError);
    final modelo = ReferenciaContextual({
      ...r.dados,
      'id': 'modelo_novo_sem_apk',
      'tipo': 'modelo',
      'nome': 'Modelo sintético novo',
      'itens': [
        {'nome': 'Alimento sintético', 'tipo': 'comida'}
      ]
    });
    await base.publicarReferencia(modelo, 0, const Uuid().v4());
    await entrar('owner');
    final repo = CalculadoraFestaRepositoryImpl(
        CalculadoraFestaRemoteDatasource(firestore: db, auth: auth));
    CalculadoraFestaController criar() => CalculadoraFestaController(
        repository: repo, itensBaseRepository: base, aiService: AiQA());
    final c = criar(), menu = '${evento}_menu';
    await c.prepararCalculadora(
        idEvento: evento,
        tipoEvento: 'Corporativo',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    expect(c.catalogoContextual.value.referencias.length, 2);
    c.atualizarCardapio([
      CardapioItem(
          idEvento: evento,
          idCardapio: menu,
          idItem: 'item',
          nome: 'Alimento sintético',
          unidade: 'kg',
          tipo: TipoItemCardapio.comida)
    ],
        titulo: 'Serviço sintético',
        disponivel: true,
        escopo: EscopoCardapio.refeicao);
    final p = c.proporRefeicao(respostas: {
      ...respostasQA(aprovado),
      'servico': 'lanche',
      'formato': 'buffet'
    });
    expect(p.regras.single.quantidadePorConvidadoEquivalente, .1);
    c.usarProposta(p, assinatura: c.assinaturaProposta);
    await c.salvarAjustesManuais();
    final calculo = c.calculoAtual.value!;
    await repo.salvarSimulacao(
        calculo: calculo.copyWith(
            contextoPlanejamento: c.snapshotPlanejamento,
            idUsuario: 'catalogo-owner',
            statusSimulacao: StatusSimulacaoCalculadora.aprovada),
        itens: c.itensCalculados.toList());
    final idHistorico = calculo.idCalculo;
    c.onClose();
    await entrar('admin');
    final nova = referenciaQA(
        versao: 2,
        porcao: .2,
        extra: {'aprovado_por': null, 'aprovado_em': null});
    await base.publicarReferencia(nova, 1, const Uuid().v4());
    await expectLater(
        base.publicarReferencia(nova, 1, const Uuid().v4()), throwsStateError);
    await entrar('owner');
    final novo = criar();
    await novo.prepararCalculadora(
        idEvento: evento,
        tipoEvento: 'Corporativo',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    expect(
        novo.catalogoContextual.value.referencias
            .firstWhere((r) => r.id == nova.id)
            .versao,
        2);
    expect(novo.regrasManuais.single.quantidadePorConvidadoEquivalente, .1);
    expect(novo.regrasManuais.single.premissas['referencia_versao'], 1);
    final historico = (await repo.listarSimulacoesPorEvento(evento))
        .firstWhere((h) => h.idCalculo == idHistorico);
    final antigas = historico.contextoPlanejamento['regras_manuais'] as List;
    expect(antigas.single['premissas']['referencia_versao'], 1);
    expect(
        (await db
                .doc('calculadora_itens_base/${r.id}/versoes_contextuais/1')
                .get())
            .data()!['padrao'],
        .1);
    await expectLater(
        db
            .doc('calculadora_itens_base/${r.id}')
            .update({'referencia_contextual': r.dados}),
        throwsA(isA<FirebaseException>()));
    novo.onClose();
    await auth.signOut();
    Get.reset();
  });
}
