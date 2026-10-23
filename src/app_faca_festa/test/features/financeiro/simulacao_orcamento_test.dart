import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/domain/services/precificacao_fornecedor_service.dart';
import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/domain/services/simulacao_orcamento_evento_service.dart';

void main() {
  const sim = SimulacaoOrcamentoEventoService();

  test('limite 20k comprometido 15k → 5k livres; sem exposição a fornecedor',
      () {
    final livres = sim.orcamentoLivreAntesDespesas(
      limiteCentavos: 2000000,
      comprometidoCentavos: 1500000,
    );
    expect(livres, 500000);

    final r = sim.simular(
      limiteConfirmadoCentavos: 2000000,
      compromissos: [
        {
          'id': 'c1',
          'id_necessidade': 'n1',
          'contratado': true,
          'valor_contratado': 15000,
          'pago': 0,
          'financeiro_valido': true,
        },
      ],
      necessidades: const [],
      alternativasPorNecessidade: const {},
    );
    expect(r.orcamentoLivreAntesDespesasCentavos, 500000);
    expect(r.alteraFinanceiro, isFalse);

    final teto = sim.tetoParaFornecedor(
      idFornecedor: 'f1',
      idNecessidade: 'decor',
      tetoCentavosCompartilhado: 300000,
      compartilhadoExplicitamente: true,
      solicitanteUid: 'f1',
    );
    expect(teto?.tetoCentavos, 300000);
    expect(
      sim.tetoParaFornecedor(
        idFornecedor: 'f1',
        idNecessidade: 'decor',
        tetoCentavosCompartilhado: null,
        compartilhadoExplicitamente: false,
        solicitanteUid: 'f1',
      ),
      isNull,
    );
  });

  test('cotações alternativas não são somadas na previsão', () {
    final r = sim.simular(
      limiteConfirmadoCentavos: 5000000,
      compromissos: const [],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(id: 'som', descricao: 'Som'),
      ],
      alternativasPorNecessidade: {
        'som': [
          const AlternativaCobertura(
            id: 'a1',
            idNecessidade: 'som',
            rotulo: 'Barato',
            precoCentavos: 100000,
            fonte: 'catalogo',
            versaoFonte: '1',
          ),
          const AlternativaCobertura(
            id: 'a2',
            idNecessidade: 'som',
            rotulo: 'Caro',
            precoCentavos: 300000,
            fonte: 'catalogo',
            versaoFonte: '1',
          ),
        ],
      },
    );
    final eco =
        r.cenarios.firstWhere((c) => c.tipo == CenarioSimulacao.economico);
    expect(eco.previsaoCentavos, 100000);
    expect(eco.previsaoCentavos, isNot(400000));
  });

  test('custos 700, margem 20%, taxa 10% → preço 1000', () {
    final p = PrecificacaoFornecedorService.precoPorMargemSobreVenda(
      custosMonetariosCentavos: 70000,
      margemSobreVenda: 0.20,
      taxasSobreVenda: 0.10,
    );
    expect(p.precoCentavos, 100000);
    expect(p.premissas, isNotEmpty);
    expect(
      () => PrecificacaoFornecedorService.precoPorMargemSobreVenda(
        custosMonetariosCentavos: 70000,
        margemSobreVenda: 0.80,
        taxasSobreVenda: 0.30,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('preço ausente / histórico incompatível → projeção parcial', () {
    final r = sim.simular(
      limiteConfirmadoCentavos: 1000000,
      compromissos: const [],
      necessidades: const [
        NecessidadeFinanceiraDescoberta(id: 'luz', descricao: 'Iluminação'),
      ],
      alternativasPorNecessidade: {
        'luz': [
          const AlternativaCobertura(
            id: 'x',
            idNecessidade: 'luz',
            rotulo: 'Inválida',
            precoCentavos: 50000,
            fonte: 'historico',
            versaoFonte: '0',
            historicoValido: false,
          ),
        ],
      },
    );
    expect(r.completo, isFalse);
    expect(r.cenarios.first.itensSemPrecoOuDisponivel, isTrue);
  });

  test('simulação não gera fatos financeiros', () {
    final r = sim.simular(
      limiteConfirmadoCentavos: 100000,
      compromissos: const [],
      necessidades: const [],
      alternativasPorNecessidade: const {},
    );
    expect(r.alteraFinanceiro, isFalse);
    expect(r.premissas.any((p) => p.contains('não altera')), isTrue);

    final com = sim.previsaoComercial(hipoteses: [
      {'valor_centavos': 100000, 'probabilidade': 0.5},
      {'valor_centavos': 200000, 'probabilidade': 0.5},
    ]);
    expect(com.receitaGarantida, isFalse);
    expect(com.valorPonderadoCentavos, 150000);
  });
}

extension on CenarioSimulado {
  bool get itensSemPrecoOuDisponivel =>
      !disponivel || itens.any((i) => i.precoAusente);
}
