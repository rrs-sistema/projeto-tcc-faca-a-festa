import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'dart:async';
import 'package:app_faca_festa/data/services/calculadora/calculadora_festa_remote_ai_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/analise_calculadora_ia.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_festa_repository.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/services/calculadora_festa_ai_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';

class _Auth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _Itens extends Fake implements CalculadoraItensBaseRepositoryContract {}

class _Repo extends Fake implements CalculadoraFestaRepository {
  List<CalculadoraFestaItem> salvos = [];
  @override
  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(String id) async =>
      salvos;
}

class _Ai extends Fake implements ICalculadoraFestaAIService {
  final pendente = Completer<AnaliseCalculadoraIA>();
  Map<String, dynamic>? contexto;
  @override
  Future<AnaliseCalculadoraIA> analisarEstimativa({
    required EstimativaFinanceira estimativa,
    required List<CalculadoraFestaItem> itensCalculados,
    required String tipoEvento,
    double? orcamentoDisponivel,
    String? idCalculo,
    String? idEvento,
    String? idUsuario,
    Map<String, dynamic>? contextoPlanejamento,
  }) {
    contexto = contextoPlanejamento;
    return pendente.future;
  }
}

ItemEstimativaFinanceira regra(
        {String id = 'bolo',
        String publico = 'todos',
        UnidadeEstimativa unidade = UnidadeEstimativa.quilo,
        double consumo = .1,
        double preco = 80}) =>
    ItemEstimativaFinanceira(
        id: id,
        categoria: 'bolo',
        nome: 'Bolo',
        tipoItem: 'bolo',
        publicoAlvo: publico,
        unidade: unidade,
        quantidadePorConvidadoEquivalente: consumo,
        valorUnitarioMedio: preco);

CardapioItem menu(
        {String nome = 'Bolo',
        String unidade = 'kg',
        PublicoAlvoCardapio publico = PublicoAlvoCardapio.todos}) =>
    CardapioItem(
        idItem: 'item',
        idEvento: 'festa',
        idCardapio: 'almoco',
        nome: nome,
        unidade: unidade,
        tipo: TipoItemCardapio.bolo,
        publicoAlvo: publico,
        quantidadeFinal: 3,
        confirmado: true);

void main() {
  const pessoas = ConvidadosEquivalentes(adultos: 20, criancas: 10, bebes: 5);
  final perfil = PerfilFesta.padrao();
  const revisao = RevisaoCardapioService();

  test('consumo respeita o público e custo acompanha quantidade de compra', () {
    expect(
        regra(publico: 'adultos')
            .calcularQuantidadeArredondada(convidados: pessoas, perfil: perfil),
        2.2);
    expect(
        regra(publico: 'criancas')
            .calcularQuantidadeArredondada(convidados: pessoas, perfil: perfil),
        .66);
    expect(
        regra(publico: 'bebes')
            .calcularQuantidadeArredondada(convidados: pessoas, perfil: perfil),
        .11);
    final item = regra(consumo: .071);
    final quantidade =
        item.calcularQuantidadeArredondada(convidados: pessoas, perfil: perfil);
    expect(quantidade, 2.11);
    expect(item.calcularCusto(convidados: pessoas, perfil: perfil),
        closeTo(quantidade * 80, 1e-8));
    expect(
        regra(unidade: UnidadeEstimativa.unidade, consumo: .071)
            .calcularQuantidadeArredondada(convidados: pessoas, perfil: perfil),
        3);
  });

  test('preço cadastrado não recebe um segundo multiplicador de perfil', () {
    final item = regra();
    final premium = PerfilFesta.premium();
    final quantidade = item.calcularQuantidadeArredondada(
        convidados: pessoas, perfil: premium);
    expect(item.calcularCusto(convidados: pessoas, perfil: premium),
        quantidade * 80);
  });

  test(
      'correspondência normaliza unidade mas exige regra para nomes desconhecidos',
      () {
    expect(revisao.regraPara(menu(unidade: 'quilo'), [regra()])?.id,
        'menu_almoco_item');
    expect(revisao.regraPara(menu(nome: 'Almoço completo'), [regra()]), isNull);
    expect(revisao.regraPara(menu(unidade: 'un'), [regra()]), isNull);
    expect(revisao.regraPara(menu(), [regra(), regra(id: 'outra')]), isNull);
    expect(
        revisao.regraPara(
            menu(publico: PublicoAlvoCardapio.adultos), [regra()])?.publicoAlvo,
        'adultos');
  });

  test('regra manual resolve item sem catálogo sem inventar preço', () {
    final manual = regra(id: 'menu_almoco_item', preco: 0);
    final vinculada = revisao.regraPara(menu(), [manual])!;
    expect(vinculada.id, manual.id);
    expect(vinculada.premissas['id_cardapio'], 'almoco');
    expect(vinculada.quantidadePorConvidadoEquivalente,
        manual.quantidadePorConvidadoEquivalente);
    expect(
        manual.calcularQuantidadeArredondada(
            convidados: pessoas, perfil: perfil),
        2.97);
    expect(manual.calcularCusto(convidados: pessoas, perfil: perfil), 0);
  });

  group('controller de planejamento', () {
    late CalculadoraFestaController c;
    late _Repo repo;
    late _Ai ai;
    setUp(() {
      Get.put<FirebaseAuth>(_Auth());
      repo = _Repo();
      ai = _Ai();
      c = CalculadoraFestaController(
          aiService: ai, repository: repo, itensBaseRepository: _Itens());
      c.estimativaSemEvento.value = true;
      c.alterarBaseCalculo(
          BaseCalculoFesta.manual); // Fixture define público manual confirmado.
      c.totalAdultos.value = 20;
      c.tipoEventoAtual.value = 'Casamento';
      c.itensEstimativa.add(regra());
    });
    tearDown(() async {
      c.onClose();
      Get.reset();
    });

    test('revisão usa somente o cardápio e informa regras pendentes', () {
      c.atualizarCardapio([menu(), menu(nome: 'Almoço completo')],
          titulo: 'Almoço', disponivel: true);
      c.alterarModoCardapio(true);
      expect(c.itensCalculados.length, 1);
      expect(c.itensSemRegra.single.nome, 'Almoço completo');
      expect(c.estimativaIncompleta, isTrue);
      c.atualizarCardapio([], titulo: '', disponivel: false);
      expect(c.possuiResultado, isFalse);
    });

    test(
        'sem disponibilidade o financeiro preserva gastos e mantém saldo pendente',
        () {
      c.calcular(); // 2,2 kg x 80 = 176
      c.compromissosOrcamento.assignAll([
        {
          'identidade':
              RevisaoCardapioService.identidade('Bolo', 'kg', 'todos'),
          'valor': 100
        },
        {'identidade': 'local', 'valor': 500},
      ]);
      c.atualizarOrcamentoDisponivel(1000);
      expect(c.contextoPlanejamento['gastos_existentes'], 600);
      expect(c.custoTotalEstimado, closeTo(176, 1e-8));
      expect(c.contextoPlanejamento['custo_adicional_estimado'], 0);
      expect(c.contextoPlanejamento['custo_projetado'], 600);
      expect(c.contextoPlanejamento['saldo_apos_planejamento'], isNull);
      expect(c.contextoPlanejamento['estimativa_incompleta'], isTrue);
    });

    test('edição manual substitui uma regra em vez de duplicar o cálculo', () {
      c.adicionarItemManual(regra(consumo: .2));
      expect(c.itensCalculados.length, 1);
      expect(c.itensCalculados.single.quantidade, 4.4);
    });

    test('resposta antiga da IA não restaura análise após mudar pessoas',
        () async {
      c.calcular();
      final analise = c.tentarAnaliseIA();
      c.atualizarTotaisManuais(adultos: 30, criancas: 0, bebes: 0);
      ai.pendente.complete(AnaliseCalculadoraIA(
          titulo: 'Antiga',
          resumo: 'Antiga',
          indiceEconomia: 0,
          indiceRiscoFaltarItens: 0,
          indiceConforto: 0,
          custoTotalEstimado: 1,
          orcamentoDisponivel: null,
          diferencaOrcamento: 0,
          dataAnalise: DateTime(2026),
          sugestoes: const []));
      await analise;
      expect(c.analiseIA.value, isNull);
      expect(ai.contexto?['modo'], 'estimar_do_zero');
    });

    test('contrato remoto mantém frações e contexto do cardápio', () async {
      c.calcular();
      Map<String, dynamic>? recebido;
      final remoto = CalculadoraFestaRemoteAIService(executor: (payload) async {
        recebido = payload;
        return {'titulo': 'Análise', 'resumo': 'Teste', 'sugestoes': []};
      });
      await remoto.analisarEstimativa(
        estimativa: c.estimativaAtual.value!,
        itensCalculados: c.itensCalculados.toList(),
        tipoEvento: 'Casamento',
        contextoPlanejamento: c.contextoPlanejamento,
      );
      expect((recebido!['itens'] as List).single['quantidade'], 2.2);
      expect(recebido!['planejamento']['modo'], 'estimar_do_zero');
      expect(recebido!['perfil_festa']['tipo'], 'padrao');
    });

    test('reabrir histórico restaura regras e preços da simulação', () async {
      c.calcular();
      final simulacao = c.calculoAtual.value!;
      repo.salvos = c.itensCalculados.toList();
      c.itensEstimativa.assignAll([regra(preco: 999, consumo: 10)]);
      await c.carregarSimulacaoNoEditor(simulacao);
      c.calcular();
      expect(c.itensCalculados.single.quantidade, 2.2);
      expect(c.itensCalculados.single.valorUnitarioMedio, 80);
    });
  });
}
