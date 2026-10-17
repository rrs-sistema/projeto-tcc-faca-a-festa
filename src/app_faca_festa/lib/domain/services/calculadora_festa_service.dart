import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';

class CalculadoraFestaService {
  const CalculadoraFestaService();

  EstimativaFinanceira calcularEstimativa({
    required CalculadoraFesta calculo,
    required List<ItemEstimativaFinanceira> itensBase,
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
      itens: itensBase,
      dataSimulacao: calculo.dataAtualizacao,
      duracaoHoras: calculo.duracaoHoras,
      margemPersonalizada: calculo.margemPersonalizada,
    );
  }

  List<CalculadoraFestaItem> calcularItens({
    required CalculadoraFesta calculo,
    required List<ItemEstimativaFinanceira> itensBase,
  }) {
    if (calculo.totalConvidados <= 0) return [];

    final estimativa = calcularEstimativa(
      calculo: calculo,
      itensBase: itensBase,
    );

    if (!estimativa.podeCalcular) return [];

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
        quantidadeNecessaria: item.calcularQuantidadeComMargem(
            convidados: estimativa.convidados,
            perfil: estimativa.perfil,
            duracaoHoras: estimativa.duracaoHoras,
            margemPersonalizada: estimativa.margemPersonalizada),
        idCardapio: item.premissas['id_cardapio']?.toString() ?? '',
        idItemCardapio: item.premissas['id_item_cardapio']?.toString() ?? '',
        unidade: item.unidade.label,
        regraAplicada:
            '${item.porcaoReferenciaFormatada} por ${item.descartavel ? 'pessoa' : 'adulto equivalente'} por serviço.\n'
            '${item.publicoEfetivo(estimativa.convidados).resumoInformado}. '
            'Público ${item.publicoAlvo}: ${item.publicoEquivalente(estimativa.convidados).g} ${item.descartavel ? 'pessoas' : 'equivalentes'}. '
            '${item.descartavel ? '' : 'Pesos: adulto 1; criança ${item.pesoCrianca.g}; bebê ${item.pesoBebe.g} (premissas de planejamento). '}\n'
            'Conta: ${item.publicoEquivalente(estimativa.convidados).g} × '
            '${item.quantidadePorConvidadoEquivalente.g} × '
            '${item.numeroServicos.g} serviço(s) × '
            '${item.fatorComposicao.g} participação × '
            '${item.fatorPerfil(estimativa.perfil).g} perfil × '
            '${item.fatorDuracaoAplicado(estimativa.duracaoHoras).g} duração ÷ '
            '${item.rendimento.g} rendimento × ${(1 + margem).g} reserva '
            '= ${quantidade.g} ${item.unidade.label} após arredondamento.\n'
            '${item.ajustarPorDuracao && !item.descartavel ? 'Ajuste por duração ativado: ${estimativa.duracaoHoras}h; escala heurística do aplicativo.' : 'A duração da festa não multiplica esta porção; informe o número de serviços se houver repetição.'}\n'
            'Perfil ${estimativa.perfil.nome}: ajuste de quantidade e ${(margem * 100).round()}% de reserva; não é medida de necessidade alimentar. '
            'Estado: ${item.premissas['estado'] ?? 'informado pelo organizador'}. '
            'Papel: ${item.premissas['papel_na_refeicao'] ?? 'a confirmar'}. '
            '${item.premissas['origem'] == 'consumo_observado' ? 'Base retrospectiva: disponibilizado menos sobra não servida; o desperdício medido nos pratos foi preservado na porção de preparo. ' : ''}'
            '${item.premissas['ajustar_por_perfil'] == false ? 'Esta referência não recebe multiplicador de quantidade do perfil; a reserva continua aplicada. ' : ''}'
            '${item.premissas['unidade_original'] != null ? 'Unidade proposta ${item.unidade.label} para item inicialmente em ${item.premissas['unidade_original']}, ainda sem quantidade final. ' : ''}'
            'Participação ${(item.fatorComposicao * 100).round()}%${item.dividirGrupo ? ' (divisão ativada)' : ' (sem divisão automática)'}; rendimento ${item.rendimento}; '
            'embalagem ${item.tamanhoEmbalagem > 0 ? '${item.tamanhoEmbalagem} ${item.unidade.label}' : 'avulso'}. '
            'Referência: ${item.premissas['fonte'] ?? 'regra informada pelo organizador'}${item.premissas['revisada_pelo_organizador'] == true ? ' (revisada pelo organizador)' : ''}. '
            'Quantidade de compra arredondada conforme a unidade.',
        valorUnitarioMedio: item.valorUnitarioMedio,
        custoEstimado: custo,
        quantidadePorConvidadoEquivalente:
            item.quantidadePorConvidadoEquivalente,
      );
    }).toList();
  }

  double calcularCustoTotal({
    required CalculadoraFesta calculo,
    required List<ItemEstimativaFinanceira> itensBase,
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
    return toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceAll('.', ',');
  }
}
