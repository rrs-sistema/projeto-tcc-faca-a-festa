import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';

class CalculadoraFestaService {
  const CalculadoraFestaService();

  static List<ItemEstimativaFinanceira> get itensPadraoEstimativa => const [
        ItemEstimativaFinanceira(
          id: 'salgadinhos',
          categoria: 'Recepção',
          nome: 'Salgadinhos',
          tipoItem: 'comida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.unidade,
          quantidadePorConvidadoEquivalente: 12,
          valorUnitarioMedio: 0.90,
        ),
        ItemEstimativaFinanceira(
          id: 'docinhos',
          categoria: 'Recepção',
          nome: 'Docinhos',
          tipoItem: 'sobremesa',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.unidade,
          quantidadePorConvidadoEquivalente: 6,
          valorUnitarioMedio: 1.20,
        ),
        ItemEstimativaFinanceira(
          id: 'bolo',
          categoria: 'Recepção',
          nome: 'Bolo',
          tipoItem: 'bolo',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.quilo,
          quantidadePorConvidadoEquivalente: 0.10,
          valorUnitarioMedio: 80.00,
        ),
        ItemEstimativaFinanceira(
          id: 'refrigerante',
          categoria: 'Bebidas',
          nome: 'Refrigerante',
          tipoItem: 'bebida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.litro,
          quantidadePorConvidadoEquivalente: 0.60,
          valorUnitarioMedio: 8.00,
        ),
        ItemEstimativaFinanceira(
          id: 'agua',
          categoria: 'Bebidas',
          nome: 'Água',
          tipoItem: 'bebida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.litro,
          quantidadePorConvidadoEquivalente: 0.30,
          valorUnitarioMedio: 3.00,
        ),
        ItemEstimativaFinanceira(
          id: 'suco',
          categoria: 'Bebidas',
          nome: 'Suco',
          tipoItem: 'bebida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.litro,
          quantidadePorConvidadoEquivalente: 0.25,
          valorUnitarioMedio: 7.00,
          selecionado: false,
        ),
        ItemEstimativaFinanceira(
          id: 'descartaveis',
          categoria: 'Estrutura',
          nome: 'Descartáveis',
          tipoItem: 'descartavel',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.pacote,
          quantidadePorConvidadoEquivalente: 0.08,
          valorUnitarioMedio: 12.00,
        ),
        ItemEstimativaFinanceira(
          id: 'lembrancinhas',
          categoria: 'Lembrancinhas',
          nome: 'Lembrancinhas',
          tipoItem: 'outros',
          publicoAlvo: 'crianca',
          unidade: UnidadeEstimativa.unidade,
          quantidadePorConvidadoEquivalente: 0.60,
          valorUnitarioMedio: 5.00,
          selecionado: false,
        ),
      ];

  EstimativaFinanceira calcularEstimativa({
    required CalculadoraFesta calculo,
    List<ItemEstimativaFinanceira>? itensBase,
  }) {
    final convidados = ConvidadosEquivalentes(
      adultos: calculo.totalAdultos,
      criancas: calculo.totalCriancas,
      bebes: calculo.totalBebes,
    );

    return EstimativaFinanceira(
      idEvento: calculo.idEvento,
      perfil: calculo.perfilFesta,
      convidados: convidados,
      itens: itensBase ?? itensPadraoEstimativa,
      dataSimulacao: calculo.dataAtualizacao,
      duracaoHoras: calculo.duracaoHoras,
      margemPersonalizada: calculo.margemPersonalizada,
    );
  }

  List<CalculadoraFestaItem> calcularItens({
    required CalculadoraFesta calculo,
    List<ItemEstimativaFinanceira>? itensBase,
  }) {
    if (calculo.totalConvidados <= 0) return [];

    final estimativa = calcularEstimativa(
      calculo: calculo,
      itensBase: itensBase,
    );

    if (!estimativa.podeCalcular) return [];

    final convidadosEquivalentes =
        estimativa.convidados.totalEquivalenteArredondado;
    final margem = estimativa.margemPersonalizada ??
        estimativa.perfil.margemSegurancaPadrao;

    return estimativa.itensSelecionados.map((item) {
      final quantidade = item.calcularQuantidadeArredondada(
        convidados: estimativa.convidados,
        perfil: estimativa.perfil,
        duracaoHoras: estimativa.duracaoHoras,
        margemPersonalizada: estimativa.margemPersonalizada,
      );

      final custo = item.calcularCusto(
        convidados: estimativa.convidados,
        perfil: estimativa.perfil,
        duracaoHoras: estimativa.duracaoHoras,
        margemPersonalizada: estimativa.margemPersonalizada,
      );

      return CalculadoraFestaItem(
        idItemResultado: '${calculo.idCalculo}_${item.id}',
        idCalculo: calculo.idCalculo,
        idEvento: calculo.idEvento,
        categoria: item.categoria,
        nome: item.nome,
        tipoItem: item.tipoItem,
        publicoAlvo: item.publicoAlvo,
        quantidade: quantidade.toDouble(),
        unidade: item.unidade.label,
        regraAplicada:
            '${item.quantidadePorConvidadoEquivalente.g} ${item.unidade.label} por convidado equivalente '
            'x $convidadosEquivalentes convidados equivalentes '
            '+ ${(margem * 100).round()}% de margem. Perfil ${estimativa.perfil.nome}.',
        valorUnitarioMedio: item.valorUnitarioMedio,
        custoEstimado: custo,
        quantidadePorConvidadoEquivalente:
            item.quantidadePorConvidadoEquivalente,
      );
    }).toList();
  }

  double calcularCustoTotal({
    required CalculadoraFesta calculo,
    List<ItemEstimativaFinanceira>? itensBase,
  }) {
    final estimativa = calcularEstimativa(
      calculo: calculo,
      itensBase: itensBase,
    );

    if (!estimativa.podeCalcular) return 0;
    return estimativa.custoTotal;
  }

  Map<String, double> calcularCustoPorCategoria({
    required List<CalculadoraFestaItem> itens,
  }) {
    final result = <String, double>{};

    for (final item in itens) {
      result[item.categoria] =
          (result[item.categoria] ?? 0) + item.custoEstimado;
    }

    return result;
  }
}

extension _DoubleRuleExtension on double {
  String get g {
    if (this == roundToDouble()) return toInt().toString();
    return toStringAsFixed(2).replaceAll('.', ',');
  }
}
