import 'package:app_faca_festa/domain/services/referencia_porcao_service.dart';
import 'package:app_faca_festa/domain/services/composicao_refeicao_service.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/consumo_observado_service.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_operacao_dialog.dart';
import 'calculadora_integridade_ponta_a_ponta_test.dart'
    show controller, menu, Repo, regra;
import 'calculadora_calibracao_test.dart' show observacao, arrozObservado;

const ops = OperacaoCalculadoraService();
const pessoas = ConvidadosEquivalentes(adultos: 10, criancas: 0, bebes: 0);
Map<String, dynamic> lote(Map<String, dynamic> atual, {double total = 10}) =>
    ops.aplicar(atual, {
      'tipo': 'lote',
      'revisao': atual['revisao'] ?? 0,
      'id_lote': 'saco',
      'lote': {
        'nome': 'Arroz comprado para a festa',
        'total': total,
        'unidade': 'kg',
        'estado': 'cru'
      }
    });
Map<String, dynamic> reservar(
        Map<String, dynamic> atual, String ref, double qtd) =>
    ops.aplicar(atual, {
      'tipo': 'reservar',
      'revisao': atual['revisao'],
      'id_lote': 'saco',
      'reserva': {
        'refeicao': ref,
        'item': 'arroz',
        'nome': 'Arroz',
        'publico': 'todos',
        'quantidade': qtd
      }
    });

class RepoOperacao extends Repo {
  Map<String, dynamic> dados = {};
  @override
  Stream<Map<String, dynamic>> observarOperacaoEvento(String id) =>
      Stream.value(dados);
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
          String id, Map<String, dynamic> acao) async =>
      dados = ops.aplicar(dados, acao);
}

ItemEstimativaFinanceira principal() => regra.copyWith(premissas: {
      ...regra.premissas,
      'id_cardapio': 'almoco',
      'id_item_cardapio': 'arroz',
      'papel_na_refeicao': 'principal',
      'receita': 'Arroz com lentilha'
    });
Map<String, dynamic> grupo(ItemEstimativaFinanceira r,
        {double qtd = .2, bool conferido = true}) =>
    {
      'id': 'g',
      'nome': 'Vegetarianos sem leite',
      'adultos': 2,
      'criancas': 0,
      'bebes': 0,
      'restricoes': ['vegetariano', 'leite'],
      'itens': {
        'arroz': {
          'quantidade': qtd,
          'conferido': conferido,
          'assinatura': OperacaoCalculadoraService.assinatura(r)
        }
      }
    };
List<String> avaliar(
        Map<String, dynamic> config, List<ItemEstimativaFinanceira> regras) =>
    ops.analisarGrupos(config, regras, pessoas, PerfilFesta.padrao(), 4, 0);

void main() {
  tearDown(() => Get.reset());
  test('saldo único rejeita dupla reserva, mantém destinos e permite liberação',
      () {
    final a = reservar(lote({}), 'almoco', 8);
    expect(() => reservar(a, 'jantar', 3), throwsStateError);
    final b = reservar(a, 'jantar', 2);
    expect(ops.reservado(b, menu(), 'kg', 'cru'), 8);
    expect(ops.reservado(b, menu().copyWith(idCardapio: 'jantar'), 'kg', 'cru'),
        2);
    final livre = reservar(b, 'almoco', 0);
    expect(ops.reservado(livre, menu(), 'kg', 'cru'), 0);
    expect(() => lote(b, total: 9), throwsStateError);
    expect(() => ops.reservado(b, menu(), 'L', 'pronto'), throwsStateError);
  });
  test('escrita com revisão desatualizada não apaga uma reserva concorrente',
      () {
    final a = reservar(lote({}), 'almoco', 8);
    expect(
        () => ops.aplicar(a, {'tipo': 'lote', 'id_lote': 'saco', 'revisao': 0}),
        throwsStateError);
    expect(() => lote({}, total: double.nan), throwsArgumentError);
  });
  test(
      'público por refeição altera quantidade e financeiro sem alterar público da festa',
      () {
    final c = controller();
    addTearDown(c.onClose);
    c.atualizarCardapiosEvento({
      'almoco': c.itensCardapio.toList(),
      'jantar': [menu(comprado: 0).copyWith(idCardapio: 'jantar')]
    }, {
      'almoco': 'Almoço',
      'jantar': 'Jantar'
    }, completo: true);
    c.operacaoEvento['refeicoes'] = {
      'jantar': {
        'publico': {'adultos': 3, 'criancas': 1, 'bebes': 0}
      }
    };
    c.calcular();
    expect(c.publicoEvento.adultos, 10);
    final j = c.listaComprasEvento
        .singleWhere((i) => i.cardapio?.idCardapio == 'jantar');
    expect(j.resultado.quantidadeNecessaria, closeTo(3.6, 1e-9));
    expect(c.resumoCompras.custoConhecido, 36);
    c.idCardapioAtual = 'jantar';
    c.itensCardapio.assignAll(c.cardapiosEvento['jantar']!);
    c.calcular();
    expect(c.itensCalculados.single.quantidadeNecessaria, closeTo(3.6, 1e-9));
    expect(c.convidadosEquivalentes.criancas, 1);
    final referencia = c.itensEstimativa.single;
    c.itensEstimativa.assignAll([
      referencia.copyWith(premissas: {
        ...referencia.premissas,
        'consumo_min': 1,
        'consumo_max': 2,
      })
    ]);
    c.calcular();
    expect(
        c.faixaDoResultado(c.itensCalculados.single), contains('3,60–7,20 kg'));
  });
  test('estoque local legado não reduz silenciosamente a lista', () {
    final c = controller();
    addTearDown(c.onClose);
    c.itensCardapio.assignAll([menu(comprado: 2, estoque: 8)]);
    c.calcular();
    expect(c.listaCompras.single.precisaConferir, true);
    expect(c.listaCompras.single.orientacao, contains('Estoque antigo'));
    expect(c.resumoCompras.completo, false);
  });
  test('estoque central e público específico persistem no snapshot histórico',
      () async {
    final repo = RepoOperacao();
    final c = controller(repo: repo);
    addTearDown(c.onClose);
    c.operacaoEvento['refeicoes'] = {
      'almoco': {
        'publico': {'adultos': 4, 'criancas': 0, 'bebes': 0}
      }
    };
    c.calcular();
    final salvo = c.calculoAtual.value!;
    repo.salvos = c.itensCalculados.toList();
    await c.carregarSimulacaoNoEditor(salvo);
    expect(c.publicoEvento.adultos, 10);
    expect(c.convidadosEquivalentes.adultos, 4);
    expect(c.operacaoEvento['lotes'], isNotEmpty);
  });
  test('grupos estruturados não presumem adequação pelo nome', () {
    final r = principal();
    final g = grupo(r, conferido: false);
    expect(
        avaliar({
          'grupos': [g]
        }, [
          r
        ]).join(' '),
        contains('ingredientes'));
    expect(
        avaliar({
          'grupos': [g]
        }, [
          r
        ]).join(' '),
        contains('insuficiente'));
    expect(
        avaliar({
          'grupos': [grupo(r)]
        }, [
          r
        ]),
        isEmpty);
    final mudou = r.copyWith(quantidadePorConvidadoEquivalente: .2);
    expect(
        avaliar({
          'grupos': [grupo(r)]
        }, [
          mudou
        ]).join(' '),
        contains('alterado'));
  });
  test(
      'grupo não pode superar público nem destinar mais que a quantidade total',
      () {
    final r = principal();
    final g = grupo(r, qtd: 2);
    expect(
        avaliar({
          'grupos': [g]
        }, [
          r
        ]).join(' '),
        contains('mais que a quantidade'));
    expect(
        () => ops.validarRefeicao({
              'publico': {'adultos': 1, 'criancas': 0, 'bebes': 0},
              'grupos': [g]
            }),
        throwsArgumentError);
    final outro = grupo(r)..['id'] = 'outro';
    expect(
        () => ops.validarRefeicao({
              'publico': {'adultos': 3, 'criancas': 0, 'bebes': 0},
              'grupos': [g, outro]
            }),
        throwsArgumentError);
  });
  test('alterar apenas preço não invalida conferência alimentar', () {
    final r = principal();
    expect(
        OperacaoCalculadoraService.assinatura(
            r.copyWith(valorUnitarioMedio: 99)),
        OperacaoCalculadoraService.assinatura(r));
  });
  test('histórico informa recência, datas ausentes e não adota amostra atípica',
      () {
    final r = arrozObservado();
    final contexto = const ConsumoObservadoService().contexto(r, [r]);
    final registros = [
      for (var i = 1; i <= 5; i++) observacao('e$i', i == 5 ? 20 : 2, dia: i)
    ];
    final resumo = const ConsumoObservadoService().resumir(
        registros: registros,
        contexto: contexto,
        eventoAtual: 'atual',
        pessoas: pessoas,
        agora: DateTime.utc(2026, 10, 16));
    expect(resumo.atipicos, 1);
    expect(resumo.podeAdotar, false);
    final antigo = const ConsumoObservadoService().resumir(
        registros: registros,
        contexto: contexto,
        eventoAtual: 'atual',
        pessoas: pessoas,
        agora: DateTime.utc(2028));
    expect(antigo.antigos, 5);
    expect(antigo.amostras, isEmpty);
  });
  test('avaliação temporal não usa a própria medição para prever o evento', () {
    final r = arrozObservado();
    final contexto = const ConsumoObservadoService().contexto(r, [r]);
    final resumo = const ConsumoObservadoService().resumir(
        registros: [
          observacao('a', 2, dia: 1),
          observacao('b', 2, dia: 2),
          observacao('c', 2, dia: 3),
          observacao('d', 4, dia: 4)
        ],
        contexto: contexto,
        eventoAtual: 'atual',
        pessoas: pessoas,
        agora: DateTime.utc(2026, 10, 16));
    expect(resumo.eventosAvaliados, 1);
    expect(resumo.erroMedianoPercentual, 50);
  });
  test(
      'item exclusivo usa apenas seu grupo e alternativas de públicos diferentes não dividem porções',
      () {
    final base = principal();
    final g = grupo(base);
    final cfg = {
      'grupos': [g],
      'destinos_itens': {
        'arroz': {
          'modo': 'grupos',
          'grupos': ['g']
        }
      }
    };
    final exclusiva = ops.regraComPublico(base, cfg, pessoas);
    expect(exclusiva.publicoEquivalente(pessoas), 2);
    final demais = ops.regraComPublico(
        base,
        {
          'grupos': [g],
          'destinos_itens': {
            'arroz': {'modo': 'demais', 'grupos': []}
          }
        },
        pessoas);
    expect(demais.publicoEquivalente(pessoas), 8);
    final misturadas = const ComposicaoRefeicaoService().compor([
      exclusiva.copyWith(premissas: {
        ...exclusiva.premissas,
        'grupo': 'proteinas',
        'dividir_grupo': true
      }),
      demais.copyWith(id: 'carne', premissas: {
        ...demais.premissas,
        'grupo': 'proteinas',
        'dividir_grupo': true
      }),
    ]);
    expect(
        misturadas.every((r) =>
            r.fatorComposicao == 1 &&
            r.premissas['grupo_incompativel'] == true),
        true);
    final conferido = grupo(exclusiva);
    expect(
        avaliar({
          'grupos': [conferido],
          'destinos_itens': cfg['destinos_itens']
        }, [
          exclusiva
        ]).join(' '),
        contains('Demais participantes'));
  });
  test(
      'consumo observado usa participantes reais, sem reaplicar público planejado do grupo',
      () {
    final r = arrozObservado().copyWith(premissas: {
      ...arrozObservado().premissas,
      'publico_refeicao': {'adultos': 2, 'criancas': 0, 'bebes': 0}
    });
    final registro = observacao('real', 2, regra: r, adultos: 10);
    expect(registro.porcaoObservada, .2);
  });
  test(
      'referências verificadas distinguem estado, ocasião e total das variedades',
      () {
    const refs = ReferenciaPorcaoService();
    final churrasco = refs.buscar('Churrasco', 'principal').single;
    expect(churrasco.estado, 'pronto');
    expect(churrasco.minimo, .30);
    expect(churrasco.contexto, contains('total'));
    expect(refs.buscar('Água', 'bebida').length, 2);
    expect(refs.buscar('Salgadinhos', 'outro').map((r) => r.minimo), [8, 6]);
    expect(refs.buscar('Docinhos', 'outro').single.maximo, 5);
    expect(refs.buscar('Bolo', 'outro').single.maximo, .15);
  });
  test('histórico sem data do consumo não calibra uma porção', () {
    final r = arrozObservado();
    final registro = observacao('sem-data', 2);
    final legado = RegistroConsumoCalculadora.fromMap(
        {...registro.toMap(), 'data_consumo': null});
    final resumo = const ConsumoObservadoService().resumir(
        registros: [legado],
        contexto: const ConsumoObservadoService().contexto(r, [r]),
        eventoAtual: 'atual',
        pessoas: pessoas,
        agora: DateTime.utc(2026, 10, 16));
    expect(resumo.semData, 1);
    expect(resumo.podeAdotar, false);
  });
  testWidgets('grupos alimentares salvam necessidades e porções conferidas',
      (tester) async {
    final repo = RepoOperacao();
    final c = controller(repo: repo);
    addTearDown(c.onClose);
    c.idCardapioAtual = 'almoco';
    c.itensEstimativa.assignAll([principal()]);
    c.calcular();
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            CalculadoraOperacaoDialog(controller: c)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Adicionar grupo alimentar'));
    await tester.tap(find.text('Adicionar grupo alimentar'));
    await tester.pumpAndSettle();
    Finder campo(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label);
    await tester.ensureVisible(campo('Nome do grupo'));
    await tester.enterText(campo('Nome do grupo'), 'Vegetarianos');
    await tester.ensureVisible(campo('Adultos').last);
    await tester.enterText(campo('Adultos').last, '2');
    await tester.pumpAndSettle();
    final vegetariano = find.widgetWithText(FilterChip, 'Vegetariano');
    final chip = tester.widget<FilterChip>(vegetariano);
    expect(chip.labelStyle?.color, const Color(0xFF173C2B));
    expect(chip.backgroundColor, const Color(0xFFF5F8F6));
    expect(chip.selectedColor, const Color(0xFFDCEEDD));
    await tester.ensureVisible(vegetariano);
    await tester.pumpAndSettle();
    await tester.tap(vegetariano);
    await tester.pumpAndSettle();
    final destinar = find.text('Destinar porções ao grupo');
    await tester.ensureVisible(destinar);
    await tester.tap(destinar);
    await tester.pumpAndSettle();
    await tester.ensureVisible(campo('Arroz'));
    await tester.enterText(campo('Arroz'), '0,2');
    final confirmar = find.byType(CheckboxListTile).first;
    await tester.ensureVisible(confirmar);
    await tester.pumpAndSettle();
    await tester.tap(confirmar);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar ajustes'));
    await tester.pumpAndSettle();
    expect(repo.dados['refeicoes']['almoco']['grupos'].single['restricoes'],
        ['vegetariano']);
    expect(c.pendenciasAlimentaresEvento, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'editor de público salva por refeição em tela pequena com texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final repo = RepoOperacao();
    final c = controller(repo: repo);
    addTearDown(c.onClose);
    c.idCardapioAtual = 'almoco';
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            CalculadoraOperacaoDialog(controller: c)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar público da festa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('publico-adultos')), '6');
    await tester.tap(find.text('Salvar ajustes'));
    await tester.pumpAndSettle();
    expect(repo.dados['refeicoes']['almoco']['publico']['adultos'], 6);
    expect(c.convidadosEquivalentes.adultos, 6);
    expect(tester.takeException(), isNull);
  });
}
