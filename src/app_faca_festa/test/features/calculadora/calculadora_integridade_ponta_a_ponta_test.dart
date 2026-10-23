import 'package:app_faca_festa/data/models/evento/calculadora_festa_item_model.dart';
import 'package:app_faca_festa/data/services/calculadora/calculadora_festa_remote_ai_service.dart';
import 'package:app_faca_festa/domain/services/receitas_salvas_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/consumo_observado_service.dart';
import 'package:get/get.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/disponibilidade_cardapio.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_ai_service.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';
import 'package:app_faca_festa/domain/services/composicao_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:app_faca_festa/domain/services/analise_refeicao_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';

class Repo implements CalculadoraFestaRepository {
  List<CalculadoraFestaItem> salvos = [];
  @override
  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(String id) async =>
      salvos;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Base implements CalculadoraItensBaseRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class IA implements ICalculadoraFestaAIService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const regra = ItemEstimativaFinanceira(
    id: 'arroz',
    categoria: 'comida',
    nome: 'Arroz',
    tipoItem: 'comida',
    publicoAlvo: 'todos',
    unidade: UnidadeEstimativa.quilo,
    quantidadePorConvidadoEquivalente: .1,
    valorUnitarioMedio: 10,
    premissas: {
      'estado': 'cru',
      'estado_compra': 'cru',
      'papel_na_refeicao': 'acompanhamento'
    });
CalculadoraFesta calculo() => CalculadoraFesta(
    idCalculo: 'auditoria',
    idEvento: 'festa',
    idUsuario: 'audit',
    tipoEvento: 'almoco',
    baseCalculo: BaseCalculoFesta.manual,
    totalAdultos: 10,
    totalCriancas: 0,
    totalBebes: 0,
    duracaoHoras: 4,
    dataCalculo: DateTime(2026),
    dataAtualizacao: DateTime(2026),
    perfilFesta: PerfilFesta.padrao(),
    margemPersonalizada: 0);
CardapioItem menu({double? comprado, double estoque = 0}) => CardapioItem(
    idItem: 'arroz',
    idEvento: 'festa',
    idCardapio: 'almoco',
    nome: 'Arroz',
    unidade: 'kg',
    disponibilidade: comprado == null
        ? null
        : DisponibilidadeCardapio(
            comprado: comprado,
            estoque: estoque,
            unidade: 'kg',
            estado: 'cru',
            nome: 'Arroz',
            publico: 'todos'));
CalculadoraFestaController controller({bool disponivel = true, Repo? repo}) {
  final c = CalculadoraFestaController(
      aiService: IA(), repository: repo ?? Repo(), itensBaseRepository: Base());
  c.idEventoAtual.value = 'festa';
  c.tipoEventoAtual.value = 'almoco';
  c.alterarBaseCalculo(
      BaseCalculoFesta.manual); // Público definido explicitamente pela fixture.
  c.totalAdultos.value = 10;
  c.margemPersonalizada.value = 0;
  c.revisarCardapio.value = true;
  c.cardapioDisponivel.value = true;
  c.tituloCardapio = 'Almoço';
  c.calculoAtual.value = calculo();
  c.itensEstimativa
      .assignAll([regra.copyWith(quantidadePorConvidadoEquivalente: 1)]);
  c.itensCardapio.assignAll([menu(comprado: disponivel ? 2 : null)]);
  c.operacaoEvento.assignAll({
    'lotes': {
      'arroz': {
        'nome': 'Arroz',
        'total': 8,
        'unidade': 'kg',
        'estado': 'cru',
        'reservas': {
          '["almoco","arroz"]': {
            'nome': 'Arroz',
            'publico': 'todos',
            'refeicao': 'almoco',
            'item': 'arroz',
            'quantidade': 8
          }
        }
      }
    }
  });
  c.orcamentoDisponivel.value = 50;
  if (disponivel) {
    c.compromissosOrcamento.assignAll([
      {
        'id': 'g',
        'valor': 20.0,
        'pago': 20.0,
        'identidade': RevisaoCardapioService.identidade('Arroz', 'kg', 'todos'),
        'cobertura_identificavel': true,
        'conferencia_financeira': 'realizado',
        'cobre_itens': <String>[]
      }
    ]);
  }
  c.calcular();
  return c;
}

void main() {
  test('embalagem arredondada antes do estoque', () {
    final r = regra.copyWith(premissas: {...regra.premissas, 'embalagem': 2});
    final out = const CalculadoraFestaService()
        .calcularItens(calculo: calculo(), itensBase: [r]).single;
    final compra = const ListaComprasCalculadoraService().analisar(
        resultado: out,
        regra: r,
        cardapio: [menu(comprado: 1)],
        compromissos: [],
        convidados:
            const ConvidadosEquivalentes(adultos: 10, criancas: 0, bebes: 0),
        perfil: PerfilFesta.padrao(),
        duracao: 4,
        margem: 0);
    expect(compra.preparo, 1);
    expect(out.quantidade, 2);
    expect(out.quantidadeNecessaria, 1);
    expect(compra.falta, 0);
  });
  test('grupo com papeis diferentes ainda divide', () {
    final a = regra.copyWith(premissas: {
      ...regra.premissas,
      'grupo': 'refeicao',
      'dividir_grupo': true
    });
    final b = regra.copyWith(
        id: 'carne',
        nome: 'Carne',
        premissas: {...a.premissas, 'papel_na_refeicao': 'principal'});
    final itens = const ComposicaoRefeicaoService().compor([a, b]);
    expect(itens.first.fatorComposicao, 1);
    expect(itens.last.fatorComposicao, 1);
    expect(itens.first.premissas['grupo_incompativel'], true);
    expect(
        const AnaliseRefeicaoService()
            .analisar(itens, refeicao: 'Almoço')
            .pendencias
            .any((p) => p.contains('mistura papéis')),
        true);
  });
  test('financeiro da IA difere das compras', () {
    final c = controller();
    final resumo = c.resumoCompras;
    final contexto = c.contextoPlanejamento;
    expect(resumo.completo, true);
    expect(resumo.custoConhecido, 0);
    expect(resumo.saldoAposCompras, 30);
    expect(contexto['custo_projetado'], 20);
    expect(contexto['saldo_apos_planejamento'], 30);
  });
  test('disponibilidade pendente nao torna contrato IA parcial', () {
    final c = controller(disponivel: false);
    expect(c.resumoCompras.completo, false);
    expect(c.resumoCompras.quantidadesPendentes, 1);
    expect(c.contextoPlanejamento['estimativa_incompleta'], true);
  });

  test('cobertura nao distingue cardapios', () {
    final r = const CalculadoraFestaService()
        .calcularItens(calculo: calculo(), itensBase: [regra]).single;
    final jantar = menu(comprado: 0).copyWith(idCardapio: 'jantar');
    final cobertura = {
      'contratado': true,
      'descricao': 'Buffet do almoço',
      'cobre_itens': [RevisaoCardapioService.identidade('Arroz', 'kg', 'todos')]
    };
    final compra = const ListaComprasCalculadoraService().analisar(
        resultado: r,
        regra: regra,
        cardapio: [jantar],
        compromissos: [cobertura],
        convidados:
            const ConvidadosEquivalentes(adultos: 10, criancas: 0, bebes: 0),
        perfil: PerfilFesta.padrao(),
        duracao: 4,
        margem: 0);
    expect(compra.situacao, SituacaoCompra.revisarServico);
    expect(compra.falta, isNull);
  });

  test('contexto histórico invalida comparação ao mudar outros alimentos', () {
    final outro = regra.copyWith(
        id: 'feijao', nome: 'Feijão', quantidadePorConvidadoEquivalente: .05);
    final alterado = outro.copyWith(quantidadePorConvidadoEquivalente: .5);
    const service = ConsumoObservadoService();
    final antes = service.contexto(regra, [regra, outro],
        refeicao: 'Almoço', tipoEvento: 'Aniversário');
    final depois = service.contexto(regra, [regra, alterado],
        refeicao: 'Almoço', tipoEvento: 'Aniversário');
    expect(antes, isNot(depois));
  });

  test('cobertura exata do almoço não cobre jantar nem item renomeado', () {
    final c = controller();
    final r = c.itensCalculados.single;
    final almoco = c.itensCardapio.single;
    final cobertura = {
      'contratado': true,
      'descricao': 'Almoço',
      'cobre_itens': [RevisaoCardapioService.cobertura(almoco)]
    };
    ItemListaCompras analisar(CardapioItem item) =>
        const ListaComprasCalculadoraService().analisar(
            resultado: r.copyWith(
                idCardapio: item.idCardapio, idItemCardapio: item.idItem),
            regra: c.regraDoResultado(r),
            cardapio: [item],
            compromissos: [cobertura],
            convidados: c.convidadosEquivalentes,
            perfil: c.perfilSelecionado.value,
            duracao: 4,
            margem: 0);
    expect(analisar(almoco).situacao, SituacaoCompra.incluido);
    final jantar = almoco.copyWith(
        idCardapio: 'jantar',
        disponibilidade: const DisponibilidadeCardapio(
            comprado: 0,
            estoque: 0,
            unidade: 'kg',
            estado: 'cru',
            nome: 'Arroz',
            publico: 'todos'));
    expect(analisar(jantar).falta, 10);
  });
  test('necessidade, escopo e unidade sobrevivem ao modelo e copyWith', () {
    final c = controller();
    final r = c.itensCalculados.single;
    final model = CalculadoraFestaItemModel.fromEntity(r);
    final copia = CalculadoraFestaItemModel.fromMap(model.toMap())
        .copyWith(adicionadoAoCardapio: true);
    expect(copia.quantidadeNecessaria, 10);
    expect(copia.idCardapio, 'almoco');
    expect(copia.idItemCardapio, 'arroz');
    final legado = model.toMap()..remove('quantidade_necessaria');
    expect(
        CalculadoraFestaItemModel.fromMap(legado).quantidadeNecessaria, isNull);
  });
  test('financeiro consolida almoço e jantar sem descontar estoque duas vezes',
      () {
    final c = controller();
    final jantar = menu(comprado: 0).copyWith(idCardapio: 'jantar');
    c.atualizarCardapiosEvento({
      'almoco': c.itensCardapio.toList(),
      'jantar': [jantar]
    }, {
      'almoco': 'Almoço',
      'jantar': 'Jantar'
    }, completo: true);
    expect(c.listaComprasEvento.length, 2);
    expect(c.resumoCompras.custoConhecido, 100);
    expect(c.resumoCompras.orcado, 20);
    expect(c.resumoCompras.saldoAposCompras, -70);
    expect(c.contextoPlanejamento['custo_projetado'], 120);
    expect(
        (c.contextoPlanejamento['compras_restantes'] as Map)['custo_projetado'],
        120);
    c.consultaCardapiosCompleta.value = false;
    expect(c.resumoCompras.completo, false);
    expect(c.contextoPlanejamento['saldo_apos_planejamento'], isNull);
  });
  test('refeição sem regra torna o financeiro inteiro parcial', () {
    final c = controller();
    c.atualizarCardapiosEvento({
      'almoco': c.itensCardapio.toList(),
      'jantar': [
        menu(comprado: 0)
            .copyWith(idCardapio: 'jantar', nome: 'Receita desconhecida')
      ]
    }, {
      'almoco': 'Almoço',
      'jantar': 'Jantar'
    }, completo: true);
    expect(c.itensSemRegraEvento.length, 1);
    expect(c.resumoCompras.completo, false);
    expect(c.contextoPlanejamento['estimativa_incompleta'], true);
  });
  test('histórico restaura todas as refeições e o financeiro conciliado',
      () async {
    final repo = Repo();
    final c = controller(repo: repo);
    c.atualizarCardapiosEvento({
      'almoco': c.itensCardapio.toList(),
      'jantar': [menu(comprado: 0).copyWith(idCardapio: 'jantar')]
    }, {
      'almoco': 'Almoço',
      'jantar': 'Jantar'
    }, completo: true);
    c.calcular();
    final salvo = c.calculoAtual.value!;
    repo.salvos = c.itensCalculados.toList();
    c.cardapiosEvento.clear();
    await c.carregarSimulacaoNoEditor(salvo);
    expect(c.usandoContextoHistorico.value, true);
    expect(c.cardapiosEvento.length, 2);
    expect(c.resumoCompras.custoConhecido, 100);
    expect(c.resumoCompras.saldoAposCompras, -70);
  });
  test('histórico anterior não recebe análise com o contrato atual', () async {
    final repo = Repo();
    final c = controller(repo: repo);
    c.calcular();
    final salvo = c.calculoAtual.value!;
    repo.salvos = c.itensCalculados.toList();
    await c.carregarSimulacaoNoEditor(salvo.copyWith(contextoPlanejamento: {
      ...salvo.contextoPlanejamento,
      'versao_motor': 4,
    }));
    await c.tentarAnaliseIA();
    expect(c.analiseIA.value, isNull);
    expect(c.erroAnaliseIA.value, contains('versão anterior'));
  });
  test(
      'receita privada reutiliza porção e rendimento, mas não preço nem vínculos',
      () {
    final r = regra.copyWith(premissas: {
      ...regra.premissas,
      'receita': 'Arroz da família',
      'rendimento': 2,
      'grupo': 'acompanhamentos',
      'dividir_grupo': true,
      'id_cardapio': 'antigo'
    });
    final receitas = const ReceitasSalvasCalculadoraService().extrair([
      {
        'id_calculo': 'nova',
        'contexto_planejamento': {
          'regras_manuais': [r.toPlanejamento()]
        }
      },
      {
        'id_calculo': 'velha',
        'contexto_planejamento': {
          'regras_manuais': [
            r.copyWith(quantidadePorConvidadoEquivalente: 2).toPlanejamento()
          ]
        }
      },
    ]);
    expect(receitas.length, 1);
    expect(receitas.single.quantidadePorConvidadoEquivalente, .1);
    expect(receitas.single.rendimento, 2);
    expect(receitas.single.valorUnitarioMedio, 0);
    expect(receitas.single.premissas['id_cardapio'], isNull);
    expect(receitas.single.dividirGrupo, false);
  });
  test('análise remota reutiliza cenário idêntico e não mistura alterações',
      () async {
    final c = controller();
    var chamadas = 0;
    final remoto = CalculadoraFestaRemoteAIService(executor: (payload) async {
      chamadas++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return {'titulo': 'Análise', 'resumo': 'Dados', 'sugestoes': []};
    });
    Future<void> pedir(double limite) async {
      await remoto.analisarEstimativa(
          estimativa: c.estimativaAtual.value!,
          itensCalculados: c.itensCalculados.toList(),
          tipoEvento: 'Almoço',
          idUsuario: 'audit',
          orcamentoDisponivel: limite,
          contextoPlanejamento: c.contextoPlanejamento);
    }

    await Future.wait([pedir(50), pedir(50)]);
    expect(chamadas, 1);
    await pedir(50);
    expect(chamadas, 1);
    await pedir(60);
    expect(chamadas, 2);
  });
}
