import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_jornada_test.dart' show BaseJornada, RepoJornada;
import 'calculadora_composicao_test.dart' show AiQA;
import 'package:app_faca_festa/domain/repositories/catalogo_contextual_repository.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/catalogo_contextual_admin_page.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/data/services/calculadora/catalogo_contextual_legado.dart';
import 'plano_evento_test.dart' show calculo;
import 'package:app_faca_festa/domain/services/rendimento_referencia_service.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';

class CatalogoEditorQA implements CatalogoContextualRepository {
  final pedidos = <String>[];
  bool falhar = true;
  int rascunhos = 0;
  @override
  Future<CatalogoContextual> carregarCatalogoContextual() async =>
      CatalogoContextual([referenciaQA()]);
  @override
  Future<ReferenciaContextual?> carregarReferencia(String id) async =>
      referenciaQA();
  @override
  Future<void> salvarRascunhoReferencia(
      ReferenciaContextual r, int esperada) async {
    rascunhos++;
  }

  @override
  Future<ReferenciaContextual> publicarReferencia(
      ReferenciaContextual r, int esperada, String pedido) async {
    pedidos.add(pedido);
    if (falhar) throw StateError('offline sintético');
    return r;
  }
}

class CatalogoLeituraQA extends BaseJornada
    implements CatalogoContextualRepository {
  Future<CatalogoContextual> Function() consultar =
      () async => CatalogoContextual([referenciaQA()]);
  @override
  Future<CatalogoContextual> carregarCatalogoContextual() => consultar();
  @override
  Future<ReferenciaContextual?> carregarReferencia(String id) async => null;
  @override
  Future<void> salvarRascunhoReferencia(ReferenciaContextual r, int e) async =>
      throw UnimplementedError();
  @override
  Future<ReferenciaContextual> publicarReferencia(
          ReferenciaContextual r, int e, String p) async =>
      throw UnimplementedError();
}

ReferenciaContextual referenciaQA(
        {int versao = 1,
        double porcao = .1,
        Map<String, dynamic> extra = const {}}) =>
    ReferenciaContextual({
      'schema': 1,
      'motor_minimo': 1,
      'id': 'teste_porcoes',
      'versao': versao,
      'tipo': 'porcao',
      'nome': 'Alimento sintético',
      'aliases': ['Alimento sintético'],
      'alimento_receita': 'Receita sintética',
      'servicos': ['lanche'],
      'formatos': ['buffet'],
      'periodos': ['qualquer'],
      'publicos': ['todos'],
      'obtencoes': ['servir', 'pronto', 'preparar'],
      'papel': 'outro',
      'unidade': 'quilo',
      'estado_consumo': 'pronto',
      'estado_compra': 'pronto',
      'contexto': 'Fixture sintética de teste, sem recomendação real.',
      'limitacoes': 'Somente cenário sintético.',
      'fonte': 'https://example.test/referencia',
      'verificado_em': null,
      'revisao_editorial': 'Fixture sintética.',
      'minimo': porcao,
      'maximo': porcao,
      'padrao': porcao,
      'aprovado_por': 'admin-qa',
      'aprovado_em': '2026-10-19T12:00:00Z',
      ...extra,
    });
const itemQA = CardapioItem(
    idEvento: 'evento',
    idCardapio: 'menu',
    idItem: 'item',
    nome: 'Alimento sintético',
    tipo: TipoItemCardapio.comida);
const contextoQA = {'servico': 'lanche', 'formato': 'buffet'};
Map<String, String> respostasQA(ReferenciaContextual r,
        {String obtencao = 'pronto'}) =>
    {'obtencao_item': obtencao, 'referencia_item': r.chave};
void main() {
  test(
      'mudar formato regenera regra de catálogo já adotada e libera nova aplicação',
      () {
    final ref = referenciaQA(extra: {
      'formatos': ['buffet', 'autosservico'],
    });
    final cat = CatalogoContextual([ref]);
    final buffet = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [],
        catalogo: cat,
        contexto: {'servico': 'lanche'},
        respostas: {
          'formato': 'buffet',
          ...respostasQA(ref),
        });
    expect(buffet.regras, hasLength(1));
    expect(buffet.preservados, isEmpty);
    final adotada = buffet.regras.single.copyWith(premissas: {
      ...buffet.regras.single.premissas,
      'revisada_pelo_organizador': true,
      'proposta_respostas': buffet.respostas,
    });
    final mesma = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [adotada],
        catalogo: cat,
        contexto: {'servico': 'lanche'},
        respostas: {
          'formato': 'buffet',
          ...respostasQA(ref),
        });
    expect(mesma.preservados, contains(adotada.id));
    final troca = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [adotada],
        catalogo: cat,
        contexto: {'servico': 'lanche'},
        respostas: {
          'formato': 'autosservico',
          ...respostasQA(ref),
        });
    expect(troca.preservados, isEmpty);
    expect(troca.regras, hasLength(1));
    expect(troca.regras.single.premissas['contexto_referencia']['formato'],
        'autosservico');
  });

  testWidgets(
      'editor manual preserva rendimento publicado válido e invalida origem ao trocar receita',
      (tester) async {
    final porcao = referenciaQA(extra: {'estado_compra': 'cru'});
    final rendimento = referenciaQA(porcao: .7, extra: {
      'id': 'rendimento_editor',
      'tipo': 'rendimento',
      'estado_compra': 'cru'
    });
    final inicial = const PropostaRefeicaoService()
        .gerar(
            itens: [itemQA],
            regras: [],
            catalogo: CatalogoContextual([porcao, rendimento]),
            contexto: contextoQA,
            respostas: {
              ...respostasQA(porcao, obtencao: 'preparar'),
              'rendimento_item': rendimento.chave
            })
        .regras
        .single;
    for (final mudar in [false, true]) {
      ItemEstimativaFinanceira? salva;
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (ctx) => Scaffold(
                  body: TextButton(
                      onPressed: () => showDialog<void>(
                          context: ctx,
                          builder: (_) => CalculadoraRegraManualDialog(
                              inicial: inicial,
                              onSalvar: (r) async {
                                salva = r;
                              })),
                      child: const Text('Abrir regra'))))));
      await tester.tap(find.text('Abrir regra'));
      await tester.pumpAndSettle();
      if (mudar) {
        await tester.enterText(
            find.byType(TextFormField).first, 'Outra receita');
      }
      await tester.tap(find.text('Usar no cálculo'));
      await tester.pumpAndSettle();
      expect(salva, isNotNull);
      expect(salva!.rendimento, .7);
      expect(const RendimentoReferenciaService().valida(salva!), !mudar);
      expect(
          salva!.premissas['referencia_snapshot'], mudar ? isNull : isNotNull);
      expect(tester.takeException(), isNull);
    }
  });
  test(
      'erro de catálogo usa apenas versão conhecida identificada; primeira falha fica indisponível',
      () async {
    Get.testMode = true;
    final repo = CatalogoLeituraQA();
    final c = CalculadoraFestaController(
        repository: RepoJornada(),
        itensBaseRepository: repo,
        aiService: AiQA());
    await c.atualizarCatalogoContextual();
    expect(c.catalogoContextual.value.referencias.single.versao, 1);
    repo.consultar = () async => throw StateError('offline');
    await c.atualizarCatalogoContextual();
    expect(c.catalogoContextual.value.estado, 'contingencia');
    expect(c.catalogoContextual.value.aviso, contains('teste_porcoes@1'));
    final novo = CalculadoraFestaController(
        repository: RepoJornada(),
        itensBaseRepository: repo,
        aiService: AiQA());
    await novo.atualizarCatalogoContextual();
    expect(novo.catalogoContextual.value.estado, 'indisponivel');
    expect(novo.catalogoContextual.value.referencias, isEmpty);
    c.onClose();
    novo.onClose();
    Get.reset();
  });
  test('resposta tardia do catálogo não entra após troca de evento', () async {
    Get.testMode = true;
    final completar = Completer<CatalogoContextual>(),
        repo = CatalogoLeituraQA();
    repo.consultar = () => completar.future;
    final c = CalculadoraFestaController(
        repository: RepoJornada(),
        itensBaseRepository: repo,
        aiService: AiQA());
    c.idEventoAtual.value = 'anterior';
    final pendente = c.atualizarCatalogoContextual();
    c.idEventoAtual.value = 'outro';
    completar.complete(CatalogoContextual([referenciaQA()]));
    await pendente;
    expect(c.catalogoContextual.value.referencias, isEmpty);
    expect(c.carregandoCatalogo.value, false);
    c.onClose();
    Get.reset();
  });
  testWidgets(
      'editor pequeno permite revisar, cancelar sem gravar e repetir falha mantendo campos e pedido',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final repo = CatalogoEditorQA();
    Future<void> abrir() async {
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => ReferenciaContextualEditor(
                              repository: repo, inicial: referenciaQA())),
                      child: const Text('Abrir'))))));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    await abrir();
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();
    expect(repo.pedidos, isEmpty);
    expect(repo.rascunhos, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.pedidos, isEmpty);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revisar'));
    await tester.pumpAndSettle();
    final publicar = find.text('Aprovar e publicar');
    await tester.ensureVisible(publicar);
    await tester.tap(publicar);
    await tester.pumpAndSettle();
    expect(find.textContaining('Seus campos foram mantidos'), findsOneWidget);
    expect(repo.pedidos, hasLength(1));
    repo.falhar = false;
    await tester.ensureVisible(publicar);
    await tester.tap(publicar);
    await tester.pumpAndSettle();
    expect(repo.pedidos, hasLength(2));
    expect(repo.pedidos.toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
  test(
      'casamento corporativo retiro e churrasco exigem modelo em vez de lanche automático',
      () {
    for (final tipo in ['Casamento', 'Corporativo', 'Retiro', 'Churrasco']) {
      final p = const PlanoEventoService().gerar(
          calculo: calculo().copyWith(tipoEvento: tipo),
          cardapios: [],
          itensPorCardapio: {},
          regras: [],
          catalogo: const CatalogoContextual([]));
      expect(p.destinos, isEmpty);
      expect(p.pendencias.join(' '), contains('Escolha um modelo'));
    }
  });
  test('referência publicada é usada por schema e contexto, sem nome de evento',
      () {
    final ref = referenciaQA();
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [],
        catalogo: CatalogoContextual([ref]),
        contexto: contextoQA,
        respostas: respostasQA(ref));
    expect(p.regras.single.quantidadePorConvidadoEquivalente, .1);
    expect(p.regras.single.premissas['referencia_snapshot'], ref.dados);
    expect(p.regras.single.valorUnitarioMedio, 0);
    final q = const PropostaRefeicaoService().gerar(
        itens: [
          itemQA.copyWith(nome: 'Alimento sintético especial desconhecido')
        ],
        regras: [],
        catalogo: CatalogoContextual([ref]),
        contexto: contextoQA,
        respostas: respostasQA(ref));
    expect(q.regras, isEmpty);
  });
  test(
      'serviço, hora, duração, público e obtenção incompatíveis não recebem número',
      () {
    final ref = referenciaQA(extra: {
      'hora_inicio': '09:00',
      'hora_fim': '10:00',
      'duracao_minima': 30,
      'duracao_maxima': 40
    });
    for (final ctx in [
      contextoQA,
      {...contextoQA, 'hora_local': '12:00', 'duracao_minutos': 35},
      {...contextoQA, 'hora_local': '09:30', 'duracao_minutos': 180},
      {
        ...contextoQA,
        'servico': 'refeicao',
        'hora_local': '09:30',
        'duracao_minutos': 35
      }
    ]) {
      expect(
          const PropostaRefeicaoService().gerar(
              itens: [itemQA],
              regras: [],
              catalogo: CatalogoContextual([ref]),
              contexto: ctx,
              respostas: respostasQA(ref)).regras,
          isEmpty);
    }
    expect(
        const PropostaRefeicaoService()
            .gerar(
                itens: [itemQA],
                regras: [],
                catalogo: CatalogoContextual([ref]),
                contexto: {
                  ...contextoQA,
                  'hora_local': '09:30',
                  'duracao_minutos': 35
                },
                respostas: respostasQA(ref))
            .regras,
        hasLength(1));
    final adulto = referenciaQA(extra: {
      'publicos': ['adultos']
    });
    expect(
        const PropostaRefeicaoService().gerar(
            itens: [itemQA],
            regras: [],
            catalogo: CatalogoContextual([adulto]),
            contexto: contextoQA,
            respostas: respostasQA(adulto)).regras,
        isEmpty);
  });
  test(
      'peso pronto não vira compra crua e catálogo indisponível não inventa regra',
      () {
    final ref = referenciaQA(extra: {'estado_compra': 'cru'});
    expect(
        const PropostaRefeicaoService().gerar(
            itens: [itemQA],
            regras: [],
            catalogo: CatalogoContextual([ref]),
            contexto: contextoQA,
            respostas: respostasQA(ref, obtencao: 'preparar')).regras,
        isEmpty);
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [],
        catalogo: CatalogoContextual.indisponivel,
        contexto: contextoQA);
    expect(p.regras, isEmpty);
    expect(p.pendencias.join(' '), contains('indisponíveis'));
  });
  test('nova publicação preserva regra confirmada e snapshot anterior', () {
    final a = referenciaQA(), b = referenciaQA(versao: 2, porcao: .2);
    final antiga = const PropostaRefeicaoService()
        .gerar(
            itens: [itemQA],
            regras: [],
            catalogo: CatalogoContextual([a]),
            contexto: contextoQA,
            respostas: respostasQA(a))
        .regras
        .single;
    final confirmada = antiga.copyWith(
        premissas: {...antiga.premissas, 'revisada_pelo_organizador': true});
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [confirmada],
        catalogo: CatalogoContextual([b]),
        contexto: contextoQA,
        respostas: respostasQA(b));
    expect(p.regras.single.quantidadePorConvidadoEquivalente, .1);
    expect(p.regras.single.premissas['referencia_versao'], 1);
  });
  test(
      'conversão usa rendimento publicado compatível escolhido, sem nome fechado',
      () {
    final porcao = referenciaQA(extra: {'estado_compra': 'cru'});
    final rendimento = referenciaQA(porcao: .7, extra: {
      'id': 'rendimento_novo',
      'tipo': 'rendimento',
      'estado_compra': 'cru'
    });
    final p = const PropostaRefeicaoService().gerar(
        itens: [itemQA],
        regras: [],
        catalogo: CatalogoContextual([porcao, rendimento]),
        contexto: contextoQA,
        respostas: {
          ...respostasQA(porcao, obtencao: 'preparar'),
          'rendimento_item': rendimento.chave
        });
    expect(p.regras.single.rendimento, .7);
    expect(const RendimentoReferenciaService().valida(p.regras.single), true);
    expect(p.regras.single.premissas['rendimento_medido'], false);
    expect(p.regras.single.premissas['rendimento_snapshot'], rendimento.dados);
  });
  test(
      'migração oferece versões rastreáveis não aprovadas e sem novas verificações',
      () {
    final refs = CatalogoContextualLegado.propostas();
    expect(refs.length, greaterThan(20));
    expect(refs.map((r) => r.id).toSet().length, refs.length);
    for (final r in refs) {
      r.validar();
      expect(r.dados['aprovado_por'], isNull);
      expect(r.dados['aprovado_em'], isNull);
    }
  });
  test(
      'modelo publicado novo gera composição sem APK e leva snapshot editorial',
      () {
    final m = referenciaQA(extra: {
      'id': 'modelo_teste',
      'tipo': 'modelo',
      'itens': [
        {'nome': 'Alimento sintético', 'tipo': 'comida'}
      ]
    });
    final p = const PlanoEventoService().gerar(
        calculo: calculo(),
        cardapios: [],
        itensPorCardapio: {},
        regras: [],
        catalogo: CatalogoContextual([m]),
        modeloReferencia: m.chave);
    expect(p.destinos.single.itens.single.nome, 'Alimento sintético');
    expect(p.destinos.single.resultados, isEmpty);
  });
}
