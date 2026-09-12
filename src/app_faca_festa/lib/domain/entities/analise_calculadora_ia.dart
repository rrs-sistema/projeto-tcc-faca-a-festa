enum TipoSugestaoCalculadoraIA {
  economia,
  alerta,
  melhoria,
  excesso,
  falta,
  planejamento,
}

enum PrioridadeSugestaoCalculadoraIA {
  baixa,
  media,
  alta,
}

extension TipoSugestaoCalculadoraIAExtension on TipoSugestaoCalculadoraIA {
  String get label {
    switch (this) {
      case TipoSugestaoCalculadoraIA.economia:
        return 'Economia';
      case TipoSugestaoCalculadoraIA.alerta:
        return 'Alerta';
      case TipoSugestaoCalculadoraIA.melhoria:
        return 'Melhoria';
      case TipoSugestaoCalculadoraIA.excesso:
        return 'Excesso';
      case TipoSugestaoCalculadoraIA.falta:
        return 'Falta';
      case TipoSugestaoCalculadoraIA.planejamento:
        return 'Planejamento';
    }
  }
}

extension PrioridadeSugestaoCalculadoraIAExtension
    on PrioridadeSugestaoCalculadoraIA {
  String get label {
    switch (this) {
      case PrioridadeSugestaoCalculadoraIA.baixa:
        return 'Baixa';
      case PrioridadeSugestaoCalculadoraIA.media:
        return 'Média';
      case PrioridadeSugestaoCalculadoraIA.alta:
        return 'Alta';
    }
  }
}

class SugestaoCalculadoraIA {
  final String id;
  final String titulo;
  final String descricao;
  final TipoSugestaoCalculadoraIA tipo;
  final PrioridadeSugestaoCalculadoraIA prioridade;
  final String? itemRelacionado;
  final double impactoEstimado;

  const SugestaoCalculadoraIA({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.prioridade,
    this.itemRelacionado,
    this.impactoEstimado = 0,
  });
}

class AnaliseCalculadoraIA {
  final String titulo;
  final String resumo;
  final double indiceEconomia;
  final double indiceRiscoFaltarItens;
  final double indiceConforto;
  final double custoTotalEstimado;
  final double? orcamentoDisponivel;
  final double diferencaOrcamento;
  final DateTime dataAnalise;
  final List<SugestaoCalculadoraIA> sugestoes;
  final String fonte;
  final String versaoSchema;
  final String versaoPrompt;
  final String nomePrompt;
  final String modeloIAUtilizado;
  final List<String> idsSugestoesBaseUtilizadas;
  final Map<String, int> versoesSugestoesBaseUtilizadas;
  final int totalSugestoesBaseUtilizadas;
  final DateTime? dataProcessamento;
  final String diagnosticoFinanceiro;
  final String diagnosticoConsumo;
  final String recomendacaoFinal;
  final List<String> pontosDeAtencao;
  final List<String> proximasAcoes;

  const AnaliseCalculadoraIA({
    required this.titulo,
    required this.resumo,
    required this.indiceEconomia,
    required this.indiceRiscoFaltarItens,
    required this.indiceConforto,
    required this.custoTotalEstimado,
    required this.orcamentoDisponivel,
    required this.diferencaOrcamento,
    required this.dataAnalise,
    required this.sugestoes,
    this.fonte = 'local',
    this.versaoSchema = '1.0.0',
    this.versaoPrompt = 'local',
    this.nomePrompt = 'analise_calculadora_local',
    this.modeloIAUtilizado = 'local',
    this.idsSugestoesBaseUtilizadas = const [],
    this.versoesSugestoesBaseUtilizadas = const <String, int>{},
    this.totalSugestoesBaseUtilizadas = 0,
    this.dataProcessamento,
    this.diagnosticoFinanceiro = '',
    this.diagnosticoConsumo = '',
    this.recomendacaoFinal = '',
    this.pontosDeAtencao = const [],
    this.proximasAcoes = const [],
  });

  bool get possuiSugestoes => sugestoes.isNotEmpty;

  bool get possuiOrcamento =>
      orcamentoDisponivel != null && orcamentoDisponivel! > 0;

  bool get acimaDoOrcamento => possuiOrcamento && diferencaOrcamento > 0;

  bool get dentroDoOrcamento => possuiOrcamento && diferencaOrcamento <= 0;

  bool get geradaPorIAGenerativa =>
      fonte.trim().toLowerCase() == 'ia_generativa';

  bool get geradaPorFallbackLocal =>
      fonte.trim().toLowerCase() == 'fallback_local';

  bool get possuiRastreabilidadeIA {
    return versaoPrompt.trim().isNotEmpty ||
        versaoSchema.trim().isNotEmpty ||
        idsSugestoesBaseUtilizadas.isNotEmpty ||
        modeloIAUtilizado.trim().isNotEmpty;
  }

  String get fonteLabel {
    if (geradaPorIAGenerativa) return 'IA generativa';
    if (geradaPorFallbackLocal) return 'Análise local';
    return 'Análise automática';
  }

  String get resumoPrincipal {
    if (resumo.trim().isNotEmpty) return resumo;
    if (diagnosticoFinanceiro.trim().isNotEmpty) return diagnosticoFinanceiro;
    if (diagnosticoConsumo.trim().isNotEmpty) return diagnosticoConsumo;
    if (recomendacaoFinal.trim().isNotEmpty) return recomendacaoFinal;
    return statusOrcamento;
  }

  String get statusOrcamento {
    if (!possuiOrcamento) return 'Sem orçamento informado';
    return acimaDoOrcamento ? 'Acima do orçamento' : 'Dentro do orçamento';
  }

  String get rastreabilidadeResumo {
    final partes = <String>[];

    if (versaoPrompt.trim().isNotEmpty) partes.add('Prompt $versaoPrompt');
    if (versaoSchema.trim().isNotEmpty) partes.add('Schema $versaoSchema');
    if (modeloIAUtilizado.trim().isNotEmpty) {
      partes.add('Modelo $modeloIAUtilizado');
    }
    if (totalSugestoesBaseUtilizadas > 0) {
      partes.add('$totalSugestoesBaseUtilizadas sugestões base');
    }

    return partes.join(' • ');
  }
}
