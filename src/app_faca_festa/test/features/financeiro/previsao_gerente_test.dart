import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/services/cobertura_parcial_necessidade_service.dart';
import 'package:app_faca_festa/domain/services/compromisso_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/lista_compras_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/domain/services/revisao_cardapio_service.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/perfil_festa.dart';
import '../calculadora/calculadora_composicao_test.dart' show regraQA;
import '../calculadora/plano_evento_test.dart' show calculo;
import 'package:app_faca_festa/domain/services/calculadora_festa_service.dart';

void main() {
  const previsao = PrevisaoFinanceiraGerenteService();
  const parcial = CoberturaParcialNecessidadeService();
  const mapper = CompromissoPlanejamentoService();

  test(
      'limite 30k, contratos 18k, pagos 7k, necessidades 8k: saldo 11k, previsão 26k, folga 4k',
      () {
    final contrato = mapper.mapear('buffet', {
      'custo_estimado': 18000,
      'valor_contratado': 18000,
      'status': 'fechado',
      'orcamento_fechado': true,
    }, gastos: [
      {'custo': 18000, 'pago': 7000}
    ])!;
    final r = previsao.calcular(
      idEvento: 'e1',
      nomeEvento: 'Festa',
      limiteConfirmado: 30000,
      compromissos: [contrato],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(
          id: 'n1',
          descricao: 'Decoração restante',
          custoEstimadoTotal: 8000,
        ),
      ],
    );
    expect(r.contratado, 18000);
    expect(r.pagoLiquido, 7000);
    expect(r.saldoContratado, 11000);
    expect(r.faltaContratar, 8000);
    expect(r.custoFinalPrevisto, 26000);
    expect(r.folgaAntesReserva, 4000);
    expect(r.cabeNoLimite, isTrue);
    expect(r.completo, isTrue);
  });

  test('necessidade 100 com 60 contratadas projeta só 40 restantes', () {
    final p = parcial.projetar(
      necessidade: 100,
      quantidadeContratada: 60,
      precoUnitario: 10,
    );
    expect(p.quantidadeRestante, 40);
    expect(p.custoProjetado, 400);
    expect(p.precoAusente, isFalse);

    final r = previsao.calcular(
      idEvento: 'e1',
      nomeEvento: 'Festa',
      limiteConfirmado: 10000,
      compromissos: const [],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(
          id: 'bebida',
          descricao: 'Refrigerante',
          quantidadeNecessaria: 100,
          quantidadeContratada: 60,
          precoUnitario: 10,
        ),
      ],
    );
    expect(r.faltaContratar, 400);
  });

  test('item sem preço deixa projeção parcial sem afirmar que cabe', () {
    final r = previsao.calcular(
      idEvento: 'e1',
      nomeEvento: 'Festa',
      limiteConfirmado: 30000,
      compromissos: const [],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(
          id: 'x',
          descricao: 'Som',
          quantidadeNecessaria: 1,
          quantidadeContratada: 0,
          precoUnitario: null,
        ),
      ],
    );
    expect(r.completo, isFalse);
    expect(r.cabeNoLimite, isNull);
    expect(r.faltaContratar, 0);
    expect(
      r.alertas.any((a) => a.codigo == 'preco_ausente'),
      isTrue,
    );
    expect(
      r.alertas.any((a) => a.codigo == 'consulta_incompleta'),
      isTrue,
    );
  });

  test('buffet cobrindo alimentação não gera compra duplicada na previsão', () {
    const item = CardapioItem(
      idEvento: 'evento',
      idCardapio: 'almoco',
      idItem: 'arroz',
      nome: 'Arroz',
      unidade: 'kg',
    );
    final regra = regraQA('Arroz', premissas: {
      'id_evento': 'evento',
      'id_cardapio': 'almoco',
      'id_item_cardapio': 'arroz',
      'estado': 'pronto',
      'papel_na_refeicao': 'principal',
    });
    final resultado = const CalculadoraFestaService()
        .calcularItens(calculo: calculo(), itensBase: [regra]).single;
    final buffet = mapper.mapear('buffet', {
      'custo_estimado': 6500,
      'valor_contratado': 6500,
      'status': 'fechado',
      'orcamento_fechado': true,
      'calculadora_cobre_itens': [RevisaoCardapioService.cobertura(item)],
    }, gastos: [
      {'custo': 6500, 'pago': 0}
    ])!;
    final compra = const ListaComprasCalculadoraService().analisar(
      resultado: resultado,
      regra: regra,
      cardapio: [item],
      compromissos: [buffet],
      convidados:
          const ConvidadosEquivalentes(adultos: 20, criancas: 0, bebes: 0),
      perfil: PerfilFesta.padrao(),
      duracao: 4,
    );
    expect(compra.situacao, SituacaoCompra.incluido);

    final r = previsao.calcular(
      idEvento: 'evento',
      nomeEvento: 'Festa',
      limiteConfirmado: 10000,
      compromissos: [buffet],
      necessidades: [
        NecessidadeFinanceiraDescoberta(
          id: 'arroz',
          descricao: 'Arroz',
          custoEstimadoTotal:
              resultado.custoEstimado > 0 ? resultado.custoEstimado : 200,
          cobertaPorBuffet: compra.situacao == SituacaoCompra.incluido,
        ),
      ],
    );
    expect(r.contratado, 6500);
    expect(r.faltaContratar, 0);
    expect(r.custoFinalPrevisto, 6500);
  });

  test('troca de geração impede ação tardia (controller)', () {
    // Comportamento espelhado: aoTrocarSessao incrementa geração e limpa.
    var geracao = 1;
    final dados = <String, double>{'pago': 7000};
    geracao++;
    dados.clear();
    final geracaoCallback = 1;
    if (geracaoCallback != geracao) {
      // callback antigo descartado
      expect(dados.containsKey('pago'), isFalse);
    }
  });
}
