import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/domain/entities/ocorrencia_servico.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;
import '../test/features/calculadora/calculadora_jornada_test.dart'
    show BaseJornada;
import '../test/features/calculadora/plano_execucao_test.dart'
    show regraExec, loteExec;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'SDK e callable reais: quatro ocorrências, cópias independentes, repetição e saldo único',
      (tester) async {
    const evento = String.fromEnvironment('AGENDA_QA_EVENTO');
    if (!const bool.fromEnvironment('CALCULADORA_QA') ||
        !RegExp(r'^agenda-[0-9]+$').hasMatch(evento)) {
      throw StateError('Use somente o harness demo local.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-agenda-servicos'));
    if (app.options.projectId != 'demo-agenda-servicos') {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'agenda-owner@example.test', password: 'TesteLocal123!');
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    final ds = CalculadoraFestaRemoteDatasource(
        firestore: db,
        auth: auth,
        agendaEmulador: Uri.parse(
            'http://127.0.0.1:5001/demo-agenda-servicos/southamerica-east1/confirmarAgendaCalculadora'));
    final repo = CalculadoraFestaRepositoryImpl(ds);
    CalculadoraFestaController criar() => CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    final c = criar();
    await c.prepararCalculadora(
        idEvento: evento,
        tipoEvento: 'Retiro',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    for (final modelo in ['${evento}_almoco', '${evento}_jantar']) {
      final r = regraExec(modelo);
      await c.alterarOperacao({
        'tipo': 'regras',
        'regras': [
          r.copyWith(premissas: {
            ...r.premissas,
            'id_evento': evento,
            'numero_servicos': 2,
            'ajustar_por_duracao': true
          }).toPlanejamento()
        ],
        'anteriores': {r.id: null}
      });
    }
    final ocorrencias = <OcorrenciaServico>[];
    for (var i = 0; i < 4; i++) {
      final modelo = '${evento}_${i.isEven ? 'almoco' : 'jantar'}',
          id = '${evento}_oc_$i';
      final o = OcorrenciaServico(
          id: id,
          evento: evento,
          modelo: modelo,
          cardapio: id,
          titulo: i.isEven ? 'Almoço' : 'Jantar',
          dataLocal: i < 2 ? '2026-10-20' : '2026-10-21',
          horaLocal: null,
          fuso: null,
          duracaoMinutos: null,
          formato: 'nao_definido');
      ocorrencias.add(o);
      final itens = [
        CardapioItem(
            idItem: 'arroz',
            idEvento: evento,
            idCardapio: modelo,
            nome: 'Arroz',
            tipo: TipoItemCardapio.comida,
            unidade: 'kg')
      ];
      final pedido = const Uuid().v4(),
          revisao = (c.operacaoEvento['revisao'] as num).toInt();
      final config = {
        'publico': {'adultos': 20 + i * 10, 'criancas': 0, 'bebes': 0},
        'publico_extra': {'adultos': i == 1 ? 2 : 0, 'criancas': 0, 'bebes': 0},
        'servico': 'refeicao'
      };
      await c.confirmarOcorrencia(o,
          revisao: revisao, pedido: pedido, config: config, itensModelo: itens);
      final depois = c.operacaoEvento['revisao'];
      await c.confirmarOcorrencia(o,
          revisao: revisao, pedido: pedido, config: config, itensModelo: itens);
      expect(c.operacaoEvento['revisao'], depois);
      final item = (await db.doc('cardapios/$id/itens/arroz').get()).data()!;
      expect(item['quantidade_final'], 0);
      expect(item['confirmado'], false);
      expect(item.containsKey('disponibilidade'), false);
    }
    expect(c.agendaServicos.length, 4);
    expect(c.agendaServicos.map((o) => o.id).toSet().length, 4);
    expect(c.publicoDaRefeicao(ocorrencias[0].cardapio).adultos, 20);
    expect(c.publicoDaRefeicao(ocorrencias[1].cardapio).adultos, 32);
    expect(c.totalConvidados, 40);
    final regrasCopiadas =
        (OperacaoCalculadoraService.mapa(c.operacaoEvento['execucao'])['regras']
                as List)
            .where((r) =>
                ocorrencias.any((o) => o.id == r['premissas']['id_cardapio']))
            .toList();
    expect(regrasCopiadas.length, 4);
    for (final r in regrasCopiadas) {
      expect(r['premissas']['numero_servicos'], 1);
      expect(r['premissas']['numero_servicos_modelo'], 2);
    }
    final revisaoAntes = c.operacaoEvento['revisao'];
    final tentativa = OcorrenciaServico.fromMap({
      ...ocorrencias.last.toMap(),
      'id': '${evento}_rejeitada',
      'id_cardapio': '${evento}_rejeitada',
    });
    // A projeção vazia está desatualizada: o modelo contém arroz.
    await expectLater(
        c.confirmarOcorrencia(tentativa,
            revisao: (revisaoAntes as num).toInt(),
            pedido: const Uuid().v4(),
            config: {},
            itensModelo: []),
        throwsStateError);
    expect(
        (await db.doc('cardapios/${tentativa.cardapio}').get()).exists, false);
    expect(
        (await db.doc('calculadora_operacao/$evento').get()).data()!['revisao'],
        revisaoAntes);
    await expectLater(
        ds.alterarOperacaoEvento(evento, {
          'tipo': 'agenda',
          'pedido': const Uuid().v4(),
          'revisao': revisaoAntes,
          'ocorrencia': {...tentativa.toMap(), 'data_local': '2026-10-22'},
          'config': {},
          'fonte_itens': [],
          'somente_modelo': true,
        }),
        throwsStateError);
    final modeloDoc =
        (await db.doc('cardapios/${evento}_almoco').get()).data()!;
    expect(modeloDoc['somente_modelo'], true);
    final alvo = ocorrencias[0].cardapio;
    await db
        .doc('cardapios/$alvo/itens/arroz')
        .update({'quantidade_final': 3, 'confirmado': true});
    expect(
        (await db.doc('cardapios/${ocorrencias[2].cardapio}/itens/arroz').get())
            .data()!['quantidade_final'],
        0);
    final cfg = const OperacaoCalculadoraService()
        .refeicao(Map.of(c.operacaoEvento), alvo)
      ..remove('ocorrencia');
    await c.alterarOperacao({
      'tipo': 'refeicao',
      'id_cardapio': alvo,
      'config': {
        ...cfg,
        'grupos': [
          {
            'id': 'veg',
            'nome': 'Grupo sintético',
            'adultos': 2,
            'criancas': 0,
            'bebes': 0,
            'restricoes': ['vegetariano'],
            'itens': {}
          }
        ]
      }
    });
    expect(
        const OperacaoCalculadoraService().refeicao(
            Map.of(c.operacaoEvento), ocorrencias[1].cardapio)['grupos'],
        isNull);
    await c.alterarOperacao(
        {'tipo': 'lote', 'id_lote': 'arroz', 'lote': loteExec(10)});
    Future<void> reservar(int n, double quantidade) => c.alterarOperacao({
          'tipo': 'reservar',
          'id_lote': 'arroz',
          'reserva': {
            'refeicao': ocorrencias[n].cardapio,
            'item': 'arroz',
            'nome': 'Arroz',
            'publico': 'todos',
            'unidade': 'kg',
            'estado': 'cru',
            'quantidade': quantidade
          }
        });
    await reservar(0, 6);
    await expectLater(reservar(1, 5), throwsStateError);
    await reservar(1, 4);
    final reservas = OperacaoCalculadoraService.mapa(
        OperacaoCalculadoraService.mapa(
            c.operacaoEvento['lotes'])['arroz'])['reservas'] as Map;
    expect(reservas.length, 2);
    expect(reservas.values.fold<num>(0, (s, v) => s + (v as Map)['quantidade']),
        10);
    // A cópia continua editável sem o modelo e preserva execução e grupos.
    await db.doc('cardapios/${evento}_almoco/itens/arroz').delete();
    await db.doc('cardapios/${evento}_almoco').delete();
    final renomeada = OcorrenciaServico.fromMap({
      ...ocorrencias.first.toMap(),
      'titulo': 'Café livre',
      'hora_local': '12:00',
      'fuso': 'America/Sao_Paulo',
    });
    final revisaoEdicao = (c.operacaoEvento['revisao'] as num).toInt();
    await c.confirmarOcorrencia(renomeada,
        revisao: revisaoEdicao,
        pedido: const Uuid().v4(),
        config: {'servico': 'refeicao'},
        itensModelo: []);
    expect(
        (await db.doc('cardapios/$alvo/itens/arroz').get())
            .data()!['quantidade_final'],
        3);
    final preservada = const OperacaoCalculadoraService()
        .refeicao(Map.of(c.operacaoEvento), alvo);
    expect(preservada['servico'], 'refeicao');
    expect((preservada['grupos'] as List).length, 1);
    await expectLater(
        c.confirmarOcorrencia(renomeada,
            revisao: revisaoEdicao,
            pedido: const Uuid().v4(),
            config: {},
            itensModelo: []),
        throwsStateError);
    final novo = criar();
    await novo.prepararCalculadora(
        idEvento: evento,
        tipoEvento: 'Retiro',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    expect(novo.agendaServicos.length, 4);
    expect(novo.publicoDaRefeicao(ocorrencias[1].cardapio).adultos, 32);
    expect((await db.doc('evento/$evento').get()).data()!.containsKey('agenda'),
        false);
    c.onClose();
    novo.onClose();
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'agenda-other@example.test', password: 'TesteLocal123!');
    await expectLater(
        ds.alterarOperacaoEvento(evento, {
          'tipo': 'agenda',
          'pedido': 'intruso',
          'revisao': 0,
          'ocorrencia': ocorrencias.first.toMap(),
          'config': {}
        }),
        throwsStateError);
    await expectLater(db.doc('calculadora_operacao/$evento').get(),
        throwsA(isA<FirebaseException>()));
    await auth.signOut();
    Get.reset();
  });
}
