// SDKs, repositórios, motor quantitativo e modais reais; dados sintéticos.
// O extrator documental é determinístico no harness local, nunca em produção.
// Cobertura suplementar: começa pelo repositório e não prova cadastro pela UI
// nem reinício do processo. Para isso: homologacao_cadastro_retomada_test.dart.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_itens_base_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/cardapio_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/evento_remote_ds.dart';
import 'package:app_faca_festa/data/datasources/remote/orcamento_gasto_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora/calculadora_itens_base_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/cardapio_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/evento_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/services/criacao_cardapio_inicial_service.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_criar_cardapio_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_entrada_inteligente_dialog.dart';
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'suplementar autenticada: fixture, proposta, estoque e financeiro',
      (tester) async {
    if (!const bool.fromEnvironment('CALCULADORA_QA')) {
      throw StateError('Somente QA.');
    }
    final app = await Firebase.initializeApp(
        name: 'calculadora-qa',
        options: const FirebaseOptions(
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
    Future<void> entrar(String email) => auth
        .signInWithEmailAndPassword(email: email, password: 'TesteLocal123!')
        .then((_) {});
    await entrar('qa-calculadora@example.test');
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    await tester.pumpWidget(const GetMaterialApp(
        home: Scaffold(body: Text('Preparando jornada QA'))));
    await tester.pumpAndSettle();
    final eventos = EventoRepositoryImpl(EventoRemoteDatasource(db,
        storage: FirebaseStorage.instanceFor(
            app: app, bucket: 'gs://demo-calculadora-entrada.appspot.com')));
    final menus = CardapioRepositoryImpl(CardapioRemoteDatasource(db));
    final repo = CalculadoraFestaRepositoryImpl(
        CalculadoraFestaRemoteDatasource(
            firestore: db, auth: auth, functions: functions));
    final base = CalculadoraItensBaseRepositoryImpl(
        CalculadoraItensBaseRemoteDatasource(firestore: db));
    CalculadoraFestaController novoController() => CalculadoraFestaController(
        repository: repo, itensBaseRepository: base, aiService: AiQA());
    var c = novoController();
    addTearDown(() {
      c.onClose();
      Get.reset();
    });
    Future<void> esperar(bool Function() pronto) async {
      for (var i = 0; i < 300 && !pronto(); i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(pronto(), true,
          reason: tester.allWidgets
              .whereType<Text>()
              .map((t) => t.data)
              .join(' | '));
    }

    final evento = Evento(
        idEvento: 'festa',
        idTipoEvento: 'churrasco',
        idUsuario: 'owner',
        nomeEvento: 'Jornada QA',
        localEvento: 'Local fictício',
        data: DateTime.now().add(const Duration(days: 7)),
        custoEstimado: 1500,
        totalAdultos: 30,
        totalCriancas: 5,
        totalBebes: 0,
        totalConvidados: 35);
    await eventos.salvar(evento);
    debugPrint('QA jornada: evento criado pelo repositório.');
    final criado = await eventos.buscarPorId('festa');
    expect(criado!.totalConvidados, 35);
    // Public list differs deliberately from the initial forecast: 37 + 1 refused.
    final convidados = db.batch();
    for (var i = 0; i < 38; i++) {
      convidados.set(db.doc('convidado/qa_$i'), {
        'id_convidado': 'qa_$i',
        'id_evento': 'festa',
        'nome': 'Pessoa QA $i',
        'contato': '',
        'tipo_convidado': i < 29 || i == 37 ? 'adulto' : 'crianca',
        'status': i == 37 ? 'recusado' : 'confirmado',
        'data_cadastro': Timestamp.now(),
        'data_atualizacao': Timestamp.now()
      });
    }
    await convidados.commit();
    Future<void> preparar() async {
      await c.prepararCalculadora(
          idEvento: 'festa',
          tipoEvento: 'Churrasco',
          base: BaseCalculoFesta.naoRecusados,
          adultosEvento: 30,
          criancasEvento: 5,
          totalConvidadosEvento: 35);
      c.orcamentoDisponivel.value =
          (await eventos.buscarPorId('festa'))!.custoEstimado;
      await c.iniciarOperacaoEvento();
    }

    await preparar();
    debugPrint('QA jornada: público e catálogo carregados.');
    expect(c.totalAdultos.value, 29);
    expect(c.totalCriancas.value, 8);
    expect(c.erroOrcamento.value, isEmpty);
    final plano = const PlanoEventoService().gerar(
        calculo: c.calculoAtual.value!,
        cardapios: [],
        itensPorCardapio: {},
        regras: c.regrasDisponiveis,
        formato: FormatoPlanoInicial.churrasco);
    final destino = plano.destinos.single;
    expect(destino.resultados.length, 3);
    debugPrint('QA jornada: consultando cardápios existentes.');
    expect(
        (await menus
            .observarCardapios('festa')
            .first
            .timeout(const Duration(seconds: 15))),
        isEmpty);
    debugPrint('QA jornada: abrindo revisão inicial.');
    CriacaoCardapioInicial? criacao;
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: Center(
                    child: FilledButton(
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => CalculadoraCriarCardapioDialog(
                                destino: destino,
                                onSalvar: (titulo) async {
                                  criacao =
                                      const CriacaoCardapioInicialService()
                                          .preparar(
                                              destino: destino,
                                              calculo: c.calculoAtual.value!,
                                              usuario: 'owner',
                                              contexto: {},
                                              titulo: titulo);
                                  expect(
                                      await menus
                                          .criarCardapioInicial(criacao!),
                                      true);
                                })),
                        child: const Text('Revisar proposta QA')))))));
    await tester.tap(find.text('Revisar proposta QA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar cardápio'));
    await esperar(
        () => find.byType(CalculadoraCriarCardapioDialog).evaluate().isEmpty);
    expect(await menus.criarCardapioInicial(criacao!), false);
    debugPrint('QA jornada: cardápio e histórico criados sem duplicidade.');
    final iniciais = await menus
        .observarItens('plano_inicial_festa', idEvento: 'festa')
        .first;
    expect(
        iniciais.every((i) =>
            i.quantidadeFinal == 0 &&
            !i.confirmado &&
            i.disponibilidade == null),
        true);
    expect((await repo.listarSimulacoesPorEvento('festa')).length, 1);
    // Explicit user planning: 4 kg at lunch + 2 kg at dinner, sharing 3 kg stock.
    final arroz = iniciais.singleWhere((i) => i.nome == 'Arroz');
    await menus.salvarItem(
        'plano_inicial_festa',
        arroz.copyWith(
            quantidadeFinal: 4,
            confirmado: true,
            disponibilidade: const DisponibilidadeCardapio(
                comprado: 0,
                estoque: 0,
                unidade: 'kg',
                estado: 'cru',
                nome: 'Arroz',
                publico: 'todos')));
    await menus.salvarCardapio(const Cardapio(
        idEvento: 'festa',
        idCardapio: 'janta',
        titulo: 'Jantar QA',
        escopo: EscopoCardapio.refeicao));
    await menus.salvarItem(
        'janta',
        arroz.copyWith(
            idCardapio: 'janta',
            quantidadeFinal: 2,
            confirmado: true,
            disponibilidade: const DisponibilidadeCardapio(
                comprado: 0,
                estoque: 0,
                unidade: 'kg',
                estado: 'cru',
                nome: 'Arroz',
                publico: 'todos')));
    ItemEstimativaFinanceira regra(String menu) => ItemEstimativaFinanceira(
            id: 'menu_${menu}_${arroz.idItem}',
            nome: 'Arroz',
            categoria: 'comida',
            tipoItem: 'comida',
            publicoAlvo: 'todos',
            unidade: UnidadeEstimativa.quilo,
            quantidadePorConvidadoEquivalente: .1,
            valorUnitarioMedio: 0,
            premissas: {
              'id_evento': 'festa',
              'id_cardapio': menu,
              'id_item_cardapio': arroz.idItem,
              'origem': 'ajuste_organizador',
              'revisada_pelo_organizador': true,
              'papel_na_refeicao': 'acompanhamento',
              'estado': 'cru',
              'estado_compra': 'cru',
              'ajustar_por_duracao': false,
              'ajustar_por_perfil': false
            });
    c.regrasManuais.assignAll([
      ...criacao!.regras
          .where((r) => r.premissas['id_item_cardapio'] != arroz.idItem),
      regra('plano_inicial_festa'),
      regra('janta')
    ]);
    await c.alterarOperacao({
      'tipo': 'lote',
      'id_lote': 'arroz',
      'lote': {'nome': 'Arroz', 'total': 3, 'unidade': 'kg', 'estado': 'cru'}
    });
    final contexto = await c.carregarExecucao();
    final proposta =
        c.proporExecucao(contexto, 'jornada_1', declararSemCompras: true);
    final compraArroz =
        proposta.compras.where((p) => p['nome'] == 'Arroz').toList();
    expect(compraArroz.single['quantidade'], closeTo(3, .0001));
    expect(await c.aplicarExecucao(proposta, c.assinaturaProposta), true);
    expect(await repo.aplicarPlanoExecucao(proposta), false);
    debugPrint('QA jornada: executor aplicado e repetição reconhecida.');
    expect(
        (await db
                .collection('tarefa')
                .where('id_evento', isEqualTo: 'festa')
                .get())
            .docs,
        isNotEmpty);
    final stock = (await db.doc('calculadora_operacao/festa').get())
        .data()!['lotes']['arroz'];
    expect(
        (stock['reservas'] as Map)
            .values
            .fold<num>(0, (s, r) => s + r['quantidade']),
        3);
    // Actual intelligent-entry modal and callable apply, then finance editor.
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: Center(
                    child: FilledButton(
                        onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => CalculadoraEntradaInteligenteDialog(
                                controller: c,
                                textoInicial:
                                    'Comprei 1 kg de arroz cru a R\$ 6/kg. Compra de mantimentos: R\$ 60, paguei R\$ 20. Cotação de decoração R\$ 500.')),
                        child: const Text('Ler financeiro QA')))))));
    await tester.tap(find.text('Ler financeiro QA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preparar leitura'));
    await esperar(() => find.text('Aplicar 5 ação(ões)').evaluate().isNotEmpty);
    expect(await repo.listarCompromissosDoEvento('festa'), isEmpty);
    await tester.tap(find.text('Aplicar 5 ação(ões)'));
    await esperar(() =>
        find.byType(CalculadoraEntradaInteligenteDialog).evaluate().isEmpty);
    var financeiro = await repo.listarCompromissosDoEvento('festa');
    expect(financeiro.fold<num>(0, (s, b) => s + b['valor']), 560);
    expect(financeiro.fold<num>(0, (s, b) => s + b['pago']), 20);
    final despesa = financeiro
        .singleWhere((b) => b['descricao'] == 'Compra de mantimentos QA');
    expect(despesa['contratado'], true);
    expect(
        financeiro
            .singleWhere((b) => b['descricao'] == 'Decoração QA')['contratado'],
        false);
    final gastos = OrcamentoGastoRemoteDatasource(firestore: db);
    final detalhes = await gastos.observarGastos(despesa['id']).first;
    debugPrint('QA jornada: entrada lida pelo financeiro real.');
    expect(detalhes.single.nome, 'Compra de mantimentos QA');
    expect(detalhes.single.idGasto, 'entrada');
    expect(detalhes.single.custo, 60);
    expect(detalhes.single.pago, 20);
    await gastos.marcarComoPago(
        idOrcamento: despesa['id'],
        idGasto: detalhes.single.idGasto,
        valorTotal: detalhes.single.custo);
    financeiro = await repo.listarCompromissosDoEvento('festa');
    expect(financeiro.fold<num>(0, (s, b) => s + b['valor']), 560);
    expect(financeiro.fold<num>(0, (s, b) => s + b['pago']), 60);
    final atual = (await db
            .doc('cardapios/plano_inicial_festa/itens/${arroz.idItem}')
            .get())
        .data()!;
    expect(atual['disponibilidade']['comprado'], 1);
    expect(atual['quantidade_final'], 4);
    expect(atual['confirmado'], true);
    // Editing event metadata must preserve the other modules and future-event guard.
    await eventos.salvar(
        criado.copyWith(nomeEvento: 'Jornada QA editada', custoEstimado: 1800));
    final pendente = c.proporExecucao(
        await c.carregarExecucao(), 'jornada_obsoleta',
        declararSemCompras: true);
    expect(
        pendente.compras.singleWhere((p) => p['nome'] == 'Arroz')['quantidade'],
        closeTo(2, .0001));
    await eventos.salvar(
        criado.copyWith(nomeEvento: 'Jornada QA final', custoEstimado: 1900));
    await expectLater(repo.aplicarPlanoExecucao(pendente), throwsStateError);
    await expectLater(
        repo.alterarOperacaoEvento('festa', {
          'tipo': 'revisao_pos_evento',
          'id_cardapio': 'plano_inicial_festa',
          'revisao': c.operacaoEvento['revisao'],
          'itens': {},
          'concluir': false,
        }),
        throwsStateError);
    expect(
        (await db.doc('evento/festa').get()).data()!['custo_estimado'], 1900);
    c.onClose();
    c = novoController();
    await auth.signOut();
    await entrar('qa-calculadora@example.test');
    await preparar();
    await esperar(() => c.operacaoEvento['lotes'] != null);
    await c.carregarExecucao();
    expect(c.totalAdultos.value, 29);
    expect(c.totalCriancas.value, 8);
    expect(c.orcamentoDisponivel.value, 1900);
    debugPrint('QA jornada: evento reaberto e configurações recuperadas.');
    expect(
        c.regrasManuais
            .singleWhere(
                (r) => r.id == 'menu_plano_inicial_festa_${arroz.idItem}')
            .valorUnitarioMedio,
        6);
    expect(c.compromissosOrcamento.fold<num>(0, (s, b) => s + b['pago']), 60);
    expect(
        (await menus
                .observarItens('plano_inicial_festa', idEvento: 'festa')
                .first)
            .singleWhere((i) => i.idItem == arroz.idItem)
            .quantidadeFinal,
        4);
    c.onClose();
    await auth.signOut();
    await entrar('outro@example.test');
    await expectLater(repo.carregarContextoExecucao('festa'), throwsStateError);
    await auth.signOut();
    await expectLater(
        repo.interpretarEntradaCalculadora(
            {'evento': 'festa', 'texto': 'teste', 'regras': []}),
        throwsStateError);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
