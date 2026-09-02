import '../../data/models/evento/analise_calculadora_ia_model.dart';
import '../../data/models/evento/calculadora_festa_item_model.dart';
import '../../data/models/evento/estimativa_financeira_model.dart';
import '../../data/models/evento/perfil_festa_model.dart';
import '../../domain/services/calculadora_festa_ai_service.dart';

class CalculadoraFestaAIService implements ICalculadoraFestaAIService {
  const CalculadoraFestaAIService();

  @override
  Future<AnaliseCalculadoraIAModel> analisarEstimativa({
    required EstimativaFinanceiraModel estimativa,
    required List<CalculadoraFestaItemModel> itensCalculados,
    required String tipoEvento,
    double? orcamentoDisponivel,
  }) async {
    final custoTotal = itensCalculados.fold<double>(
      0,
      (total, item) => total + item.custoEstimado,
    );

    final sugestoes = <SugestaoCalculadoraIAModel>[];
    final convidados = estimativa.convidados;
    final totalConvidados = convidados.totalInformado;
    final totalEquivalente = convidados.totalEquivalenteArredondado;
    final margem = estimativa.margemPersonalizada ??
        estimativa.perfil.margemSegurancaPadrao;
    final duracaoHoras = estimativa.duracaoHoras;
    final orcamento = _normalizarOrcamento(orcamentoDisponivel);
    final diferencaOrcamento = orcamento == null ? 0.0 : custoTotal - orcamento;

    if (totalConvidados <= 0 || itensCalculados.isEmpty) {
      return AnaliseCalculadoraIAModel(
        titulo: 'Informe os dados da festa',
        resumo:
            'A análise inteligente será gerada quando houver convidados e pelo menos um item selecionado.',
        indiceEconomia: 0,
        indiceRiscoFaltarItens: 0,
        indiceConforto: 0,
        custoTotalEstimado: custoTotal,
        orcamentoDisponivel: orcamento,
        diferencaOrcamento: diferencaOrcamento.roundToDouble(),
        dataAnalise: DateTime.now(),
        sugestoes: const [],
      );
    }

    final nomesSelecionados =
        itensCalculados.map((item) => _normalize(item.nome)).toList();
    final possuiAgua = _containsAny(nomesSelecionados, const ['agua', 'água']);
    final possuiSuco = _containsAny(nomesSelecionados, const ['suco']);
    final possuiRefrigerante =
        _containsAny(nomesSelecionados, const ['refrigerante', 'refri']);
    final possuiSalgadinhos =
        _containsAny(nomesSelecionados, const ['salgadinho', 'salgadinhos']);
    final possuiDocinhos =
        _containsAny(nomesSelecionados, const ['docinho', 'docinhos']);
    final possuiBolo = _containsAny(nomesSelecionados, const ['bolo']);
    final possuiLembrancinhas = _containsAny(
        nomesSelecionados, const ['lembrancinha', 'lembrancinhas']);

    final percentualCriancas =
        totalConvidados == 0 ? 0.0 : convidados.criancas / totalConvidados;
    final percentualBebes =
        totalConvidados == 0 ? 0.0 : convidados.bebes / totalConvidados;
    final itemMaisCaro = _itemMaisCaro(itensCalculados);
    final percentualItemMaisCaro = custoTotal <= 0 || itemMaisCaro == null
        ? 0.0
        : itemMaisCaro.custoEstimado / custoTotal;

    if (orcamento == null) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'orcamento-nao-informado',
          titulo: 'Informe um orçamento disponível',
          descricao:
              'Com o orçamento informado, a IA consegue indicar se a festa está econômica, equilibrada ou acima do limite planejado.',
          tipo: TipoSugestaoCalculadoraIA.planejamento,
          prioridade: PrioridadeSugestaoCalculadoraIA.media,
        ),
      );
    } else if (diferencaOrcamento > 0) {
      sugestoes.add(
        SugestaoCalculadoraIAModel(
          id: 'orcamento-acima',
          titulo: 'Estimativa acima do orçamento',
          descricao:
              'O custo estimado está ${_formatMoney(diferencaOrcamento.roundToDouble())} acima do orçamento disponível. Considere reduzir itens opcionais, ajustar o perfil da festa ou rever valores médios.',
          tipo: TipoSugestaoCalculadoraIA.alerta,
          prioridade: PrioridadeSugestaoCalculadoraIA.alta,
          impactoEstimado: diferencaOrcamento.roundToDouble(),
        ),
      );
    } else {
      sugestoes.add(
        SugestaoCalculadoraIAModel(
          id: 'orcamento-dentro',
          titulo: 'Estimativa dentro do orçamento',
          descricao:
              'A festa está dentro do orçamento informado, com uma folga aproximada de ${_formatMoney(diferencaOrcamento.roundToDouble().abs())}.',
          tipo: TipoSugestaoCalculadoraIA.melhoria,
          prioridade: PrioridadeSugestaoCalculadoraIA.baixa,
          impactoEstimado: diferencaOrcamento.roundToDouble().abs(),
        ),
      );
    }

    if (estimativa.perfil.tipo == TipoPerfilFesta.premium &&
        orcamento != null &&
        custoTotal > orcamento) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'perfil-premium-orcamento',
          titulo: 'Perfil Premium pode estar elevando o custo',
          descricao:
              'Como o orçamento foi ultrapassado, uma alternativa é testar o perfil Padrão para manter uma boa margem com menor custo estimado.',
          tipo: TipoSugestaoCalculadoraIA.economia,
          prioridade: PrioridadeSugestaoCalculadoraIA.alta,
        ),
      );
    }

    if (estimativa.perfil.tipo == TipoPerfilFesta.economico &&
        duracaoHoras >= 5 &&
        margem < 0.10) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'economico-festa-longa',
          titulo: 'Atenção à margem em festas longas',
          descricao:
              'Para festas com 5 horas ou mais, o perfil Econômico com margem baixa aumenta o risco de faltar comida ou bebida.',
          tipo: TipoSugestaoCalculadoraIA.falta,
          prioridade: PrioridadeSugestaoCalculadoraIA.media,
        ),
      );
    }

    if (duracaoHoras >= 5 && !possuiAgua) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'agua-festa-longa',
          titulo: 'Inclua água para eventos mais longos',
          descricao:
              'A duração informada é alta. Adicionar água reduz o risco de faltar bebida e melhora o conforto dos convidados.',
          tipo: TipoSugestaoCalculadoraIA.falta,
          prioridade: PrioridadeSugestaoCalculadoraIA.alta,
          itemRelacionado: 'Água',
        ),
      );
    }

    if (percentualCriancas >= 0.35 && !possuiSuco) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'suco-criancas',
          titulo: 'Considere incluir suco',
          descricao:
              'Há uma participação relevante de crianças. O suco pode complementar ou reduzir a dependência de refrigerante.',
          tipo: TipoSugestaoCalculadoraIA.melhoria,
          prioridade: PrioridadeSugestaoCalculadoraIA.media,
          itemRelacionado: 'Suco',
        ),
      );
    }

    if (percentualBebes >= 0.20) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'bebes-consumo',
          titulo: 'Bebês têm baixo impacto no consumo',
          descricao:
              'A estimativa já considera bebês com peso menor. Isso evita superestimar comida, bebida e doces.',
          tipo: TipoSugestaoCalculadoraIA.planejamento,
          prioridade: PrioridadeSugestaoCalculadoraIA.baixa,
        ),
      );
    }

    if (!possuiSalgadinhos && !possuiBolo && !possuiDocinhos) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'sem-itens-recepcao',
          titulo: 'Poucos itens de recepção selecionados',
          descricao:
              'A festa não possui salgadinhos, bolo ou docinhos selecionados. Verifique se a estimativa representa o cardápio real do evento.',
          tipo: TipoSugestaoCalculadoraIA.alerta,
          prioridade: PrioridadeSugestaoCalculadoraIA.alta,
        ),
      );
    }

    if (!possuiRefrigerante && !possuiSuco && !possuiAgua) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'sem-bebidas',
          titulo: 'Nenhuma bebida selecionada',
          descricao:
              'Sem bebidas no cálculo, a estimativa pode ficar abaixo do custo real da festa.',
          tipo: TipoSugestaoCalculadoraIA.falta,
          prioridade: PrioridadeSugestaoCalculadoraIA.alta,
        ),
      );
    }

    if (itemMaisCaro != null && percentualItemMaisCaro >= 0.35) {
      sugestoes.add(
        SugestaoCalculadoraIAModel(
          id: 'item-maior-impacto',
          titulo: '${itemMaisCaro.nome} concentra boa parte do custo',
          descricao:
              'Esse item representa aproximadamente ${(percentualItemMaisCaro * 100).round()}% da estimativa. Negociar esse item pode trazer economia relevante.',
          tipo: TipoSugestaoCalculadoraIA.economia,
          prioridade: PrioridadeSugestaoCalculadoraIA.media,
          itemRelacionado: itemMaisCaro.nome,
          impactoEstimado: itemMaisCaro.custoEstimado,
        ),
      );
    }

    if (percentualCriancas >= 0.30 && !possuiLembrancinhas) {
      sugestoes.add(
        const SugestaoCalculadoraIAModel(
          id: 'lembrancinhas-criancas',
          titulo: 'Lembrancinhas podem ser avaliadas',
          descricao:
              'Como há muitas crianças, o sistema pode simular lembrancinhas para comparar o impacto no orçamento.',
          tipo: TipoSugestaoCalculadoraIA.planejamento,
          prioridade: PrioridadeSugestaoCalculadoraIA.baixa,
          itemRelacionado: 'Lembrancinhas',
        ),
      );
    }

    final indiceRisco = _calcularIndiceRisco(
      duracaoHoras: duracaoHoras,
      margem: margem,
      perfil: estimativa.perfil,
      possuiAgua: possuiAgua,
      possuiBebidas: possuiAgua || possuiSuco || possuiRefrigerante,
      possuiItensRecepcao: possuiSalgadinhos || possuiBolo || possuiDocinhos,
      percentualCriancas: percentualCriancas,
    );

    final indiceEconomia = _calcularIndiceEconomia(
      perfil: estimativa.perfil,
      custoTotal: custoTotal,
      orcamentoDisponivel: orcamento,
    );

    final indiceConforto = _calcularIndiceConforto(
      perfil: estimativa.perfil,
      indiceRisco: indiceRisco,
      margem: margem,
      possuiBebidas: possuiAgua || possuiSuco || possuiRefrigerante,
    );

    final titulo = _montarTitulo(
      orcamento: orcamento,
      diferencaOrcamento: diferencaOrcamento.roundToDouble(),
      indiceRisco: indiceRisco,
    );

    final resumo = _montarResumo(
      tipoEvento: tipoEvento,
      perfil: estimativa.perfil,
      totalConvidados: totalConvidados,
      totalEquivalente: totalEquivalente,
      custoTotal: custoTotal,
      orcamento: orcamento,
      indiceRisco: indiceRisco,
      quantidadeSugestoes: sugestoes.length,
    );

    return AnaliseCalculadoraIAModel(
      titulo: titulo,
      resumo: resumo,
      indiceEconomia: indiceEconomia,
      indiceRiscoFaltarItens: indiceRisco,
      indiceConforto: indiceConforto,
      custoTotalEstimado: custoTotal,
      orcamentoDisponivel: orcamento,
      diferencaOrcamento: diferencaOrcamento,
      dataAnalise: DateTime.now(),
      sugestoes: sugestoes,
    );
  }

  double _calcularIndiceRisco({
    required int duracaoHoras,
    required double margem,
    required PerfilFestaModel perfil,
    required bool possuiAgua,
    required bool possuiBebidas,
    required bool possuiItensRecepcao,
    required double percentualCriancas,
  }) {
    var risco = 18.0;

    if (duracaoHoras >= 5) {
      risco += 14;
    }
    if (duracaoHoras >= 7) {
      risco += 8;
    }
    if (margem < 0.08) {
      risco += 15;
    }
    if (margem >= 0.15) {
      risco -= 8;
    }
    if (!possuiBebidas) {
      risco += 25;
    }
    if (duracaoHoras >= 5 && !possuiAgua) {
      risco += 12;
    }
    if (!possuiItensRecepcao) {
      risco += 20;
    }
    if (percentualCriancas >= 0.35) {
      risco += 6;
    }

    switch (perfil.tipo) {
      case TipoPerfilFesta.economico:
        risco += 8;
        break;
      case TipoPerfilFesta.padrao:
        break;
      case TipoPerfilFesta.premium:
        risco -= 10;
        break;
    }

    return risco.clamp(0, 100).toDouble();
  }

  double _calcularIndiceEconomia({
    required PerfilFestaModel perfil,
    required double custoTotal,
    required double? orcamentoDisponivel,
  }) {
    if (orcamentoDisponivel == null || orcamentoDisponivel <= 0) {
      switch (perfil.tipo) {
        case TipoPerfilFesta.economico:
          return 85;
        case TipoPerfilFesta.padrao:
          return 65;
        case TipoPerfilFesta.premium:
          return 40;
      }
    }

    if (custoTotal <= 0) {
      return 0;
    }

    final ratio = custoTotal / orcamentoDisponivel;

    if (ratio <= 0.75) {
      return 92;
    }
    if (ratio <= 1.0) {
      return (85 - ((ratio - 0.75) * 100)).clamp(60, 85).toDouble();
    }

    return (55 - ((ratio - 1.0) * 80)).clamp(10, 55).toDouble();
  }

  double _calcularIndiceConforto({
    required PerfilFestaModel perfil,
    required double indiceRisco,
    required double margem,
    required bool possuiBebidas,
  }) {
    var conforto = 100 - indiceRisco;

    if (margem >= 0.10) {
      conforto += 6;
    }
    if (possuiBebidas) {
      conforto += 5;
    }

    switch (perfil.tipo) {
      case TipoPerfilFesta.economico:
        conforto -= 5;
        break;
      case TipoPerfilFesta.padrao:
        conforto += 4;
        break;
      case TipoPerfilFesta.premium:
        conforto += 12;
        break;
    }

    return conforto.clamp(0, 100).toDouble();
  }

  String _montarTitulo({
    required double? orcamento,
    required double diferencaOrcamento,
    required double indiceRisco,
  }) {
    if (orcamento != null && diferencaOrcamento > 0) {
      return 'Ajustes recomendados no orçamento';
    }

    if (indiceRisco >= 65) {
      return 'Risco elevado de faltar itens';
    }

    if (indiceRisco >= 40) {
      return 'Estimativa equilibrada com pontos de atenção';
    }

    return 'Estimativa saudável para a festa';
  }

  String _montarResumo({
    required String tipoEvento,
    required PerfilFestaModel perfil,
    required int totalConvidados,
    required int totalEquivalente,
    required double custoTotal,
    required double? orcamento,
    required double indiceRisco,
    required int quantidadeSugestoes,
  }) {
    final buffer = StringBuffer();
    buffer.write(
      'Para $tipoEvento, no perfil ${perfil.nome}, a IA analisou $totalConvidados convidados ',
    );
    buffer.write(
        '($totalEquivalente equivalentes) e estimou ${_formatMoney(custoTotal)}. ');

    if (orcamento != null && orcamento > 0) {
      final diferenca = custoTotal - orcamento;
      if (diferenca > 0) {
        buffer.write(
            'O cálculo ultrapassa o orçamento em ${_formatMoney(diferenca)}. ');
      } else {
        buffer.write(
            'O cálculo está dentro do orçamento com folga de ${_formatMoney(diferenca.abs())}. ');
      }
    }

    buffer.write('Risco de faltar itens: ${indiceRisco.round()}%. ');
    buffer.write('$quantidadeSugestoes recomendação(ões) gerada(s).');

    return buffer.toString();
  }

  CalculadoraFestaItemModel? _itemMaisCaro(
      List<CalculadoraFestaItemModel> itens) {
    if (itens.isEmpty) {
      return null;
    }

    final ordenados = [...itens]
      ..sort((a, b) => b.custoEstimado.compareTo(a.custoEstimado));
    return ordenados.first;
  }

  bool _containsAny(List<String> values, List<String> tokens) {
    return values.any(
        (value) => tokens.any((token) => value.contains(_normalize(token))));
  }

  double? _normalizarOrcamento(double? value) {
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  String _formatMoney(double value) {
    final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = normalized.split(',');
    final integer = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $integer,${parts.last}';
  }
}
