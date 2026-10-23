import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_agenda_dialog.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'calculadora_jornada_test.dart' show BaseJornada, CardapioQA;
import 'calculadora_composicao_test.dart' show AiQA;
import 'configuracao_duravel_test.dart' show RepoConfiguracao;
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'plano_evento_test.dart' show calculo;
import 'plano_execucao_test.dart'
    show regraExec, contextoExec, loteExec, proporExec;
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/services/analise_refeicao_service.dart';
import 'package:app_faca_festa/domain/entities/ocorrencia_servico.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';

OcorrenciaServico o(String id,
        {String? data,
        String? hora,
        String? fuso,
        int? minutos,
        String modelo = 'modelo'}) =>
    OcorrenciaServico(
        id: id,
        evento: 'evento',
        modelo: modelo,
        cardapio: id,
        titulo: 'Serviço',
        dataLocal: data,
        horaLocal: hora,
        fuso: fuso,
        duracaoMinutos: minutos);
void main() {
  test('renomear não reinterpreta o tipo declarado do serviço', () {
    const analise = AnaliseRefeicaoService();
    for (final servico in ['refeicao', 'lanche', 'nao_definido']) {
      expect(
          analise.analisar([], refeicao: 'Almoço', servico: servico).pendencias,
          analise.analisar([],
              refeicao: 'Café livre', servico: servico).pendencias);
    }
    expect(
        analise.analisar([], refeicao: 'Café', servico: 'refeicao').pendencias,
        isNotEmpty);
  });
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());
  testWidgets(
      'proposta de ocorrência permite cancelar e retomar falha sem gravar nem perder campos',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.resetViewInsets();
    });
    final repo = RepoConfiguracao();
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'evento', tipoEvento: 'Retiro', adultosEvento: 40);
    final menus = CardapioController(repository: CardapioQA());
    addTearDown(menus.onClose);
    menus.cardapios.add(const Cardapio(
        idCardapio: 'modelo', idEvento: 'evento', titulo: 'Almoço'));
    menus.itensPorCardapio['modelo'] = [
      const CardapioItem(
          idItem: 'arroz',
          idEvento: 'evento',
          idCardapio: 'modelo',
          nome: 'Arroz',
          tipo: TipoItemCardapio.comida,
          unidade: 'kg')
    ];
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) => CalculadoraOcorrenciaEditor(
                            controller: c,
                            cardapios: menus,
                            modeloInicial: 'modelo')),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();
    expect(find.text('Cancelar').hitTestable(), findsOneWidget);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar ocorrência'));
    await tester.pumpAndSettle();
    expect(repo.gravacoes, 0);
    expect(find.text('Confirmar ocorrência'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(c.agendaServicos, isEmpty);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar ocorrência'));
    await tester.pumpAndSettle();
    repo.falhar = true;
    await tester.tap(find.text('Confirmar ocorrência'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraOcorrenciaEditor), findsOneWidget);
    expect(find.textContaining('Sem conexão'), findsOneWidget);
    expect(repo.gravacoes, 0);
    repo.falhar = false;
    await tester.tap(find.text('Confirmar ocorrência'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraOcorrenciaEditor), findsNothing);
    expect(c.agendaServicos.length, 1);
    expect(c.agendaServicos.single.horaLocal, isNull);
    expect(tester.takeException(), isNull);
  });

  test(
      'agenda permite campos desconhecidos, valida período, intervalo, calendário e fuso',
      () {
    o('a').validar(
        inicioEvento: DateTime(2026, 10, 20),
        fimEvento: DateTime(2026, 10, 21));
    expect(o('a').dataLocal, isNull);
    expect(o('a').horaLocal, isNull);
    for (final registro in [
      o('a', data: '2026-02-30'),
      o('a', hora: '24:00'),
      o('a', fuso: 'Inventado/Fuso'),
      o('a', minutos: 0),
      o('a', data: '2026-10-19'),
      o('a', data: '2026-10-21', hora: '23:30', minutos: 60)
    ]) {
      expect(
          () => registro.validar(
              inicioEvento: DateTime(2026, 10, 20),
              fimEvento: DateTime(2026, 10, 21)),
          throwsArgumentError);
    }
    expect(
        () => o('dst',
                data: '2026-03-08', hora: '02:30', fuso: 'America/New_York')
            .validar(),
        throwsArgumentError);
    o('parcial', hora: '12:00', fuso: 'America/Sao_Paulo', minutos: 90)
        .validar();
  });
  test(
      'retiro mantém quatro identidades e públicos, modelos não entram na soma',
      () {
    const motor = OperacaoCalculadoraService();
    final ocorrencias = [
      for (var i = 0; i < 4; i++)
        o('oc_$i',
            data: i < 2 ? '2026-10-20' : '2026-10-21',
            modelo: i.isEven ? 'almoco' : 'jantar')
    ];
    final op = {
      'agenda': ocorrencias.map((o) => o.toMap()).toList(),
      'refeicoes': {
        for (var i = 0; i < 4; i++)
          ocorrencias[i].id: {
            'publico': {'adultos': 20 + i * 10, 'criancas': 0, 'bebes': 0},
            'publico_extra': {
              'adultos': i == 0 ? 2 : 0,
              'criancas': 0,
              'bebes': 0
            }
          }
      }
    };
    final menus = [
      const Cardapio(
          idCardapio: 'almoco',
          idEvento: 'evento',
          titulo: 'Almoço',
          somenteModelo: true),
      const Cardapio(
          idCardapio: 'jantar',
          idEvento: 'evento',
          titulo: 'Jantar',
          somenteModelo: true),
      for (final a in ocorrencias)
        Cardapio(
            idCardapio: a.cardapio,
            idEvento: 'evento',
            titulo: 'Nome livre',
            escopo: EscopoCardapio.refeicao,
            idModelo: a.modelo)
    ];
    final plano = const PlanoEventoService().gerar(
        calculo: calculo(pessoas: 40)
            .copyWith(duracaoHoras: 24, margemPersonalizada: 0),
        cardapios: menus,
        itensPorCardapio: {
          for (final a in ocorrencias)
            a.cardapio: [
              CardapioItem(
                  idItem: 'arroz',
                  idEvento: 'evento',
                  idCardapio: a.cardapio,
                  nome: 'Arroz',
                  tipo: TipoItemCardapio.comida,
                  unidade: 'kg')
            ]
        },
        regras: [for (final a in ocorrencias) regraExec(a.cardapio)],
        operacao: op);
    expect(plano.destinos.length, 4);
    expect(plano.destinos.map((d) => d.cardapio.idCardapio).toSet().length, 4);
    expect(plano.destinos.map((d) => d.pessoas), [22, 30, 40, 50]);
    expect(
        plano.destinos
            .expand((d) => d.resultados)
            .fold<double>(0, (s, r) => s + r.quantidadeNecessaria!),
        closeTo(14.2, 1e-9));
    final renomeado = menus[2].copyWith(titulo: 'Qualquer nome');
    expect(motor.refeicao(op, renomeado.idCardapio)['servico'], isNull);
    expect(motor.refeicao(op, ocorrencias[1].cardapio)['grupos'], isNull);
  });
  test(
      'três intervalos agregam compras por ocorrência sem duração global adicional e sem reutilizar lote',
      () {
    final ids = ['intervalo_1', 'intervalo_2', 'intervalo_3'];
    final op = {
      'agenda': [for (final id in ids) o(id).toMap()],
      'refeicoes': {
        for (final id in ids) id: {'servico': 'lanche'}
      },
      'lotes': {'arroz': loteExec(5)}
    };
    final ctx = contextoExec(menus: ids, operacao: op);
    final proposta = proporExec(ctx);
    final lotes = OperacaoCalculadoraService.mapa(proposta.operacao['lotes']);
    final reservas = OperacaoCalculadoraService.mapa(
        OperacaoCalculadoraService.mapa(lotes['arroz'])['reservas']);
    expect(
        reservas.values
            .fold<double>(0, (s, r) => s + (r['quantidade'] as num).toDouble()),
        5);
    expect(
        proposta.compras
            .fold<double>(0, (s, r) => s + (r['quantidade'] as num).toDouble()),
        1);
    expect(reservas.values.map((r) => r['refeicao']).toSet().length, 3);
    for (final minutos in [null, 120]) {
      final config = {'ocorrencia': o('intervalo_1', minutos: minutos).toMap()};
      final regra = regraExec('intervalo_1').copyWith(premissas: {
        ...regraExec('intervalo_1').premissas,
        'ajustar_por_duracao': true
      });
      final local = const OperacaoCalculadoraService()
          .regraComPublico(regra, config, calculo().convidadosEquivalentes);
      expect(local.fatorDuracaoAplicado(2), local.fatorDuracaoAplicado(24));
      expect(local.fatorDuracaoAplicado(24), minutos == null ? 1 : .85);
    }
  });

  test('ocorrência tem identidade própria e gravação independente do modelo',
      () {
    const o = OcorrenciaServico(
        id: 'oc_1',
        evento: 'festa',
        modelo: 'modelo_almoco',
        cardapio: 'oc_1',
        titulo: 'Almoço do dia 1');
    final op = const OperacaoCalculadoraService().aplicar({}, {
      'tipo': 'agenda',
      'revisao': 0,
      'ocorrencia': o.toMap(),
      'config': {}
    });
    expect((op['agenda'] as List).single['id'], 'oc_1');
  });
}
