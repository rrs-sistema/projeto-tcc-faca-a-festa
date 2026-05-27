import '../../data/models/evento/calculadora_festa_item_model.dart';
import '../../data/models/evento/calculadora_festa_model.dart';
import '../../data/models/evento/convidados_equivalentes_model.dart';
import '../../data/models/evento/estimativa_financeira_model.dart';

class CalculadoraFestaService {
  const CalculadoraFestaService();

  static List<ItemEstimativaFinanceiraModel> get itensPadraoEstimativa => const [
        ItemEstimativaFinanceiraModel(
          id: 'salgadinhos',
          categoria: 'Recepção',
          nome: 'Salgadinhos',
          tipoItem: 'comida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.unidade,
          quantidadePorConvidadoEquivalente: 12,
          valorUnitarioMedio: 0.90,
        ),
        ItemEstimativaFinanceiraModel(
          id: 'docinhos',
          categoria: 'Recepção',
          nome: 'Docinhos',
          tipoItem: 'sobremesa',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.unidade,
          quantidadePorConvidadoEquivalente: 6,
          valorUnitarioMedio: 1.20,
        ),
        ItemEstimativaFinanceiraModel(
          id: 'bolo',
          categoria: 'Recepção',
          nome: 'Bolo',
          tipoItem: 'bolo',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.quilo,
          quantidadePorConvidadoEquivalente: 0.10,
          valorUnitarioMedio: 80.00,
        ),
        ItemEstimativaFinanceiraModel(
          id: 'refrigerante',
          categoria: 'Bebidas',
          nome: 'Refrigerante',
          tipoItem: 'bebida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.litro,
          quantidadePorConvidadoEquivalente: 0.60,
          valorUnitarioMedio: 8.00,
        ),
        ItemEstimativaFinanceiraModel(
          id: 'agua',
          categoria: 'Bebidas',
          nome: 'Água',
          tipoItem: 'bebida',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.litro,
          quantidadePorConvidadoEquivalente: 0.30,
          valorUnitarioMedio: 3.00,
        ),
        ItemEstimativaFinanceiraModel(
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
        ItemEstimativaFinanceiraModel(
          id: 'descartaveis',
          categoria: 'Estrutura',
          nome: 'Descartáveis',
          tipoItem: 'descartavel',
          publicoAlvo: 'todos',
          unidade: UnidadeEstimativa.pacote,
          quantidadePorConvidadoEquivalente: 0.08,
          valorUnitarioMedio: 12.00,
        ),
        ItemEstimativaFinanceiraModel(
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

  EstimativaFinanceiraModel calcularEstimativa({
    required CalculadoraFestaModel calculo,
    List<ItemEstimativaFinanceiraModel>? itensBase,
  }) {
    final convidados = ConvidadosEquivalentesModel(
      adultos: calculo.totalAdultos,
      criancas: calculo.totalCriancas,
      bebes: calculo.totalBebes,
    );

    return EstimativaFinanceiraModel(
      idEvento: calculo.idEvento,
      perfil: calculo.perfilFesta,
      convidados: convidados,
      itens: itensBase ?? itensPadraoEstimativa,
      dataSimulacao: calculo.dataAtualizacao,
      duracaoHoras: calculo.duracaoHoras,
      margemPersonalizada: calculo.margemPersonalizada,
    );
  }

  List<CalculadoraFestaItemModel> calcularItens({
    required CalculadoraFestaModel calculo,
    List<ItemEstimativaFinanceiraModel>? itensBase,
  }) {
    if (calculo.totalConvidados <= 0) return [];

    final estimativa = calcularEstimativa(
      calculo: calculo,
      itensBase: itensBase,
    );

    if (!estimativa.podeCalcular) return [];

    final convidadosEquivalentes = estimativa.convidados.totalEquivalenteArredondado;
    final margem = estimativa.margemPersonalizada ?? estimativa.perfil.margemSegurancaPadrao;

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

      return CalculadoraFestaItemModel(
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
        quantidadePorConvidadoEquivalente: item.quantidadePorConvidadoEquivalente,
      );
    }).toList();
  }

  double calcularCustoTotal({
    required CalculadoraFestaModel calculo,
    List<ItemEstimativaFinanceiraModel>? itensBase,
  }) {
    final estimativa = calcularEstimativa(
      calculo: calculo,
      itensBase: itensBase,
    );

    if (!estimativa.podeCalcular) return 0;
    return estimativa.custoTotal;
  }

  Map<String, double> calcularCustoPorCategoria({
    required List<CalculadoraFestaItemModel> itens,
  }) {
    final result = <String, double>{};

    for (final item in itens) {
      result[item.categoria] = (result[item.categoria] ?? 0) + item.custoEstimado;
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
