import 'package:flutter/material.dart';
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
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_planejador_dialog.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import '../test/features/calculadora/catalogo_contextual_test.dart'
    show referenciaQA, respostasQA;
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'planejador real: fallback, cancelar, confirmação, conflito e retomada',
      (tester) async {
    const evento = String.fromEnvironment('PLANEJADOR_QA_EVENTO');
    if (!const bool.fromEnvironment('CALCULADORA_QA') ||
        !RegExp(r'^planejador-[0-9]+$').hasMatch(evento)) {
      throw StateError('Use o harness demo local.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-planejador-hibrido'));
    if (app.options.projectId != 'demo-planejador-hibrido') {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    await auth.signInWithEmailAndPassword(
        email: 'planejador-owner@example.test', password: 'TesteLocal123!');
    final remote = CalculadoraFestaRemoteDatasource(
        firestore: db,
        auth: auth,
        planejadorEmulador: Uri.parse(
            'http://127.0.0.1:5001/demo-planejador-hibrido/southamerica-east1/'));
    final repo = CalculadoraFestaRepositoryImpl(remote),
        base = CalculadoraItensBaseRepositoryImpl(
            CalculadoraItensBaseRemoteDatasource(firestore: db, auth: auth));
    final menu = '${evento}_menu';
    Future<CalculadoraFestaController> abrir() async {
      final c = CalculadoraFestaController(
          repository: repo, itensBaseRepository: base, aiService: AiQA());
      await c.prepararCalculadora(
          idEvento: evento,
          tipoEvento: 'Corporativo',
          adultosEvento: 40,
          totalConvidadosEvento: 40);
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
      return c;
    }

    final c = await abrir(),
        op = db.doc('calculadora_operacao/$evento'),
        item = db.doc('cardapios/$menu/itens/item');
    final antes = (await op.get()).data();
    final leitura = await c.interpretarBriefingPlanejador(
        'Quero Alimento sintético neste serviço');
    expect(leitura['origem'], 'parser_local_limitado');
    expect(leitura['candidatos'], hasLength(1));
    expect((await op.get()).data(), antes);
    // Tela real em largura pequena, fonte ampliada e teclado aberto; cancelar não grava.
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(390, 740),
                textScaler: TextScaler.linear(1.4),
                viewInsets: EdgeInsets.only(bottom: 220)),
            child: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                CalculadoraPlanejadorDialog(controller: c)),
                        child: const Text('Abrir')))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Planejar este serviço'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Voltar sem confirmar'));
    await tester.pumpAndSettle();
    expect((await op.get()).data(), antes);
    final respostas = {
      'objetivo': 'comparar_quantidades',
      'servico': 'lanche',
      'formato': 'buffet',
      ...respostasQA(referenciaQA())
    };
    final fontes = await c.prepararPlanejador(),
        p = c.proporPlanejador(respostas: respostas);
    expect(p.principal.regras, hasLength(1));
    expect(p.financeiroCompleto, isFalse);
    final ctx = c.contextoServicoPlanejador,
        decisao = {
          'versao': 1,
          'objetivo': 'comparar_quantidades',
          'infraestrutura': <String, dynamic>{},
          'respostas': respostas,
          'assinatura_material': ctx.assinatura
        };
    Map<String, dynamic> entrada(String pedido) => {
          'evento': evento,
          'cardapio': menu,
          'pedido': pedido,
          'revisao': fontes.operacao['revisao'],
          'fontes': fontes.fontes,
          'decisao': decisao,
          'regras': p.principal.regras
              .map((r) => r.copyWith(premissas: {
                    ...r.premissas,
                    'revisada_pelo_organizador': true,
                    'proposta_respostas': respostas
                  }).toPlanejamento())
              .toList()
        };
    final maliciosa = entrada(const Uuid().v4());
    (maliciosa['regras'] as List).single['consumo'] = 999;
    await expectLater(repo.confirmarPlanejador(maliciosa), throwsStateError);
    expect((await op.get()).data(), antes);
    final assinatura = c.assinaturaProposta,
        pedido = const Uuid().v4(),
        originalItem = (await item.get()).data();
    await c.confirmarPlanoServico(
        fontes: fontes,
        proposta: p,
        respostas: respostas,
        assinatura: assinatura,
        pedido: pedido);
    final persistido = (await op.get()).data()!;
    expect(persistido['revisao'], 2);
    expect(persistido['planejador'][menu]['objetivo'], 'comparar_quantidades');
    expect((await item.get()).data(), originalItem);
    // Repetição da mesma entrada é idempotente; fontes antigas em novo pedido são rejeitadas.
    final repetida = await repo.confirmarPlanejador(entrada(pedido));
    expect(repetida['revisao'], 2);
    await expectLater(
        repo.confirmarPlanejador(entrada(const Uuid().v4())), throwsStateError);
    c.onClose();
    final reaberto = await abrir();
    await reaberto.prepararPlanejador();
    expect(
        reaberto.contextoServicoPlanejador
            .reutilizar(reaberto.decisaoPlanejador),
        respostas);
    expect(
        reaberto
            .proporPlanejador(respostas: respostas)
            .principal
            .regras
            .single
            .quantidadePorConvidadoEquivalente,
        .1);
    final fontes2 = await reaberto.prepararPlanejador();
    final tentativa = entrada(const Uuid().v4())
      ..['revisao'] = fontes2.operacao['revisao']
      ..['fontes'] = fontes2.fontes;
    (tentativa['regras'] as List).single['consumo'] = .3;
    await expectLater(repo.confirmarPlanejador(tentativa), throwsStateError);
    await expectLater(
        op.update({'planejador': {}}), throwsA(isA<FirebaseException>()));
    reaberto.onClose();
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'planejador-admin@example.test', password: 'TesteLocal123!');
    await expectLater(
        repo.sugerirCandidatosPlanejador({
          'evento': evento,
          'cardapio': menu,
          'texto': 'Alimento sintético'
        }),
        throwsStateError);
    await expectLater(
        repo.confirmarPlanejador(entrada(const Uuid().v4())), throwsStateError);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
    await auth.signOut();
  });
}
