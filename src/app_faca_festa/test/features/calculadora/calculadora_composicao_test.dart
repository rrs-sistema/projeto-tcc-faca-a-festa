import 'package:app_faca_festa/domain/services/conversao_orcamento_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/models/calculadora/calculadora_evento_item_model.dart';
import 'package:app_faca_festa/data/models/evento/calculadora_festa_model.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_ai_service.dart';
import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/composicao_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';

class AuthQA extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class RepositoryQA extends Fake implements CalculadoraFestaRepository {
  List<CalculadoraFestaItem> itens = [];
  @override
  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(String id) async =>
      itens;
}

class BaseQA extends Fake implements CalculadoraItensBaseRepositoryContract {}

class AiQA extends Fake implements ICalculadoraFestaAIService {}

List<CalculadoraEventoItemModel> catalogoQA() => (jsonDecode(
        File('config/calculadora_catalogo_v1.json').readAsStringSync()) as List)
    .map((r) =>
        CalculadoraEventoItemModel.fromMap(Map<String, dynamic>.from(r as Map)))
    .toList();

ItemEstimativaFinanceira regraQA(String nome,
        {double consumo = .1, Map<String, dynamic> premissas = const {}}) =>
    ItemEstimativaFinanceira(
        id: nome,
        categoria: 'comida',
        nome: nome,
        tipoItem: 'comida',
        publicoAlvo: 'todos',
        unidade: UnidadeEstimativa.quilo,
        quantidadePorConvidadoEquivalente: consumo,
        valorUnitarioMedio: 10,
        premissas: premissas);

void main() {
  test(
      'alternativas dividem consumo; porções independentes permanecem integrais',
      () {
    final itens = const ComposicaoRefeicaoService().compor([
      regraQA('Arroz', premissas: {
        'papel_na_refeicao': 'acompanhamento',
        'grupo': 'acompanhamentos',
        'participacao': 1,
        'dividir_grupo': true
      }),
      regraQA('Massa', premissas: {
        'papel_na_refeicao': 'acompanhamento',
        'grupo': 'acompanhamentos',
        'participacao': 3,
        'dividir_grupo': true
      }),
      regraQA('Carne'),
    ]);
    expect(itens[0].fatorComposicao, .25);
    expect(itens[1].fatorComposicao, .75);
    expect(itens[2].fatorComposicao, 1);
  });
  test('itens desmarcados não reduzem as porções selecionadas', () {
    final r = regraQA('Arroz',
        premissas: {'grupo': 'acompanhamentos', 'dividir_grupo': true});
    final itens = const ComposicaoRefeicaoService()
        .compor([r, r.copyWith(id: 'massa', selecionado: false)]);
    expect(itens.first.fatorComposicao, 1);
  });
  test('rendimento e embalagem geram compra e custo coerentes', () {
    final regra = regraQA('Arroz servido',
        consumo: .3, premissas: {'rendimento': 3, 'embalagem': 5});
    const pessoas = ConvidadosEquivalentes(adultos: 60, criancas: 0, bebes: 0);
    expect(
        regra.calcularQuantidadeArredondada(
            convidados: pessoas,
            perfil: PerfilFesta.padrao(),
            margemPersonalizada: 0),
        10);
    expect(
        regra.calcularCusto(
            convidados: pessoas,
            perfil: PerfilFesta.padrao(),
            margemPersonalizada: 0),
        100);
  });
  test('catálogo tem fonte por regra, aliases e nenhum preço fictício', () {
    final catalogo = catalogoQA();
    expect(catalogo.length, greaterThanOrEqualTo(5));
    for (final item in catalogo) {
      expect(item.valorUnitarioMedio, 0);
      expect(item.quantidadePorConvidadoEquivalente, greaterThan(0));
      expect(item.premissas['fonte'], startsWith('https://'));
      expect(CalculadoraEventoItemModel.fromMap(item.toMap()).premissas,
          item.premissas);
    }
  });
  test(
      'unidade inicial sem quantidade usa proposta rastreável sem mudar o cardápio',
      () {
    const revisao = RevisaoCardapioService();
    const menu = CardapioItem(
        idItem: 'arroz',
        idEvento: 'qa',
        idCardapio: 'almoco',
        nome: 'Arroz 🍚');
    final referencia =
        regraQA('Arroz', premissas: {'fonte': 'https://www.assai.com.br/'});
    final proposta = revisao.regraPara(menu, [referencia])!;
    expect(proposta.unidade, UnidadeEstimativa.quilo);
    expect(proposta.premissas['unidade_original'], 'un');
    expect(menu.unidade, 'un');
    expect(revisao.regraPara(menu.copyWith(quantidadeFinal: 1), [referencia]),
        isNull);
    expect(revisao.regraPara(menu.copyWith(confirmado: true), [referencia]),
        isNull);
    expect(
        revisao.regraPara(menu.copyWith(quantidadeSugerida: 1), [referencia]),
        isNull);
    final resultado = CalculadoraFestaItem(
        idItemResultado: 'calc_menu_almoco_arroz',
        idCalculo: 'calc',
        idEvento: 'qa',
        categoria: 'comida',
        nome: menu.nome,
        tipoItem: 'comida',
        publicoAlvo: 'todos',
        quantidade: 3,
        unidade: 'kg',
        regraAplicada: 'Proposta rastreável');
    expect(revisao.correspondente(resultado, [menu]), same(menu));
    expect(
        revisao.podeAjustarUnidade(
            menu.copyWith(quantidadeFinal: 1), resultado),
        isFalse);
    expect(
        revisao
            .regraPara(menu.copyWith(unidade: 'kg'), [proposta])!
            .premissas
            .containsKey('unidade_original'),
        isFalse);
  });

  test('conversão reutiliza o mesmo serviço coberto para vários alimentos', () {
    const conversao = ConversaoOrcamentoService();
    final itens = ['Arroz', 'Macarrão']
        .map((nome) => CalculadoraFestaItem(
            idItemResultado: nome,
            idCalculo: 'calc',
            idEvento: 'qa',
            idCardapio: 'almoco',
            idItemCardapio: nome,
            categoria: 'comida',
            nome: nome,
            tipoItem: 'comida',
            publicoAlvo: 'todos',
            quantidade: 5,
            unidade: 'kg',
            regraAplicada: 'regra',
            custoEstimado: 100))
        .toList();
    final cobertura = itens
        .map((i) => RevisaoCardapioService.coberturaResultado(i)!)
        .toList();
    final destinos = conversao.destinos('qa', itens, [
      {
        '__id': 'buffet',
        'id_evento': 'qa',
        'custo_estimado': 6500,
        'calculadora_cobre_itens': cobertura
      },
    ]);
    expect(destinos.values.toSet(), {'buffet'});
    final propostas = conversao.propostas(itens, destinos);
    expect(propostas['buffet']!.length, 2);
    expect(
        propostas['buffet']!.values.fold<double>(
            0, (s, p) => s + ((p as Map)['custo'] as num).toDouble()),
        200);
    expect(
        () => conversao.destinos('qa', itens, [
              {'__id': 'buffet', 'calculadora_cobre_itens': cobertura},
              {'__id': 'duplicado', 'calculadora_cobre_itens': cobertura},
            ]),
        throwsStateError);
  });

  test(
      'pagamentos são separados do valor contratado, sem somar detalhe duas vezes',
      () {
    final gasto = const CompromissoPlanejamentoService().mapear('buffet', {
      'custo_estimado': 6500,
      'orcamento_fechado': true,
      'calculadora_cobre_itens': ['arroz|kg|todos']
    }, gastos: [
      {'custo': 6500, 'pago': 1500}
    ])!;
    expect(gasto['valor'], 6500);
    expect(gasto['pago'], 1500);
    expect(gasto['contratado'], isTrue);
    expect(gasto['cobertura_identificavel'], isTrue);
  });
  test(
      'cardápio das imagens calcula, cenário não altera estado e histórico mantém pendências',
      () async {
    Get.put<FirebaseAuth>(AuthQA());
    final repo = RepositoryQA();
    final c = CalculadoraFestaController(
        aiService: AiQA(), repository: repo, itensBaseRepository: BaseQA());
    addTearDown(() {
      c.onClose();
      Get.reset();
    });
    c.idEventoAtual.value = 'qa';
    c.totalAdultos.value = 100;
    c.itensEstimativa.assignAll(catalogoQA().map((i) => regraQA(i.nome,
            consumo: i.quantidadePorConvidadoEquivalente,
            premissas: i.premissas)
        .copyWith(
            id: i.id,
            tipoItem: i.categoria,
            unidade: i.unidade == 'L'
                ? UnidadeEstimativa.litro
                : UnidadeEstimativa.quilo,
            valorUnitarioMedio: 0)));
    final menus = [
      'Churrasco 🥩',
      'Macarrão 🍝',
      'Arroz 🍚',
      'Refrigerante',
      'Prato desconhecido'
    ]
        .map((nome) => CardapioItem(
            idItem: nome,
            idEvento: 'qa',
            idCardapio: 'almoco',
            nome: nome,
            unidade: nome == 'Refrigerante' ? 'L' : 'un'))
        .toList();
    c.atualizarCardapio(menus, titulo: 'Almoço', disponivel: true);
    expect(c.itensCalculados.length, 4);
    expect(c.itensCalculados.firstWhere((i) => i.nome == 'Arroz 🍚').quantidade,
        5.5);
    expect(c.estimativaIncompleta, isTrue);
    final antes = c.itensCalculados.toList();
    final cenario = c.simularPerfil(PerfilFesta.economico());
    expect(cenario.first.quantidade, lessThan(antes.first.quantidade));
    expect(c.itensCalculados, antes);
    c.compromissosOrcamento.add({
      'id': 'buffet',
      'valor': 6500.0,
      'pago': 1500.0,
      'contratado': true,
      'identidade': '',
      'cobertura_identificavel': true,
      'cobre_itens': antes
          .map((i) => RevisaoCardapioService.identidade(
              i.nome, i.unidade, i.publicoAlvo))
          .toList()
    });
    expect(c.contextoPlanejamento['custo_adicional_estimado'], 0);
    c.calcular();
    final novoMapa =
        CalculadoraFestaModel.fromEntity(c.calculoAtual.value!).toMap();
    final mesclado = {
      'analise_ia': {'titulo': 'Análise de parâmetros antigos'},
      'analiseIA': {'titulo': 'Alias antigo'},
      ...novoMapa
    };
    expect(CalculadoraFestaModel.fromMap(mesclado).analiseIA, isNull);
    final salvo = CalculadoraFestaModel.fromMap(novoMapa);
    repo.itens = c.itensCalculados.toList();
    c.itensEstimativa.clear();
    c.itensCardapio.clear();
    await c.carregarSimulacaoNoEditor(salvo);
    expect(c.revisarCardapio.value, isTrue);
    expect(c.itensSemRegra.single.nome, 'Prato desconhecido');
    expect(c.compromissosOrcamento.single['pago'], 1500);
    c.calcular();
    expect(c.itensCalculados.firstWhere((i) => i.nome == 'Arroz 🍚').quantidade,
        5.5);
  });
}
