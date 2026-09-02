class PlanejamentoFestaIAResponse {
  final String titulo;
  final String resumoExecutivo;
  final String diagnosticoFinanceiro;
  final String diagnosticoConsumo;
  final String recomendacaoFinal;

  final List<SugestaoPlanejamentoIA> sugestoes;
  final List<String> pontosDeAtencao;
  final List<String> proximasAcoes;

  const PlanejamentoFestaIAResponse({
    required this.titulo,
    required this.resumoExecutivo,
    required this.diagnosticoFinanceiro,
    required this.diagnosticoConsumo,
    required this.recomendacaoFinal,
    required this.sugestoes,
    required this.pontosDeAtencao,
    required this.proximasAcoes,
  });

  factory PlanejamentoFestaIAResponse.fromJson(Map<String, dynamic> json) {
    return PlanejamentoFestaIAResponse(
      titulo: json['titulo']?.toString() ?? '',
      resumoExecutivo: json['resumoExecutivo']?.toString() ?? '',
      diagnosticoFinanceiro: json['diagnosticoFinanceiro']?.toString() ?? '',
      diagnosticoConsumo: json['diagnosticoConsumo']?.toString() ?? '',
      recomendacaoFinal: json['recomendacaoFinal']?.toString() ?? '',
      sugestoes: ((json['sugestoes'] as List?) ?? [])
          .map((item) => SugestaoPlanejamentoIA.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      pontosDeAtencao: ((json['pontosDeAtencao'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
      proximasAcoes: ((json['proximasAcoes'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class SugestaoPlanejamentoIA {
  final String titulo;
  final String descricao;
  final String impacto;
  final String prioridade;
  final String? itemRelacionado;

  const SugestaoPlanejamentoIA({
    required this.titulo,
    required this.descricao,
    required this.impacto,
    required this.prioridade,
    this.itemRelacionado,
  });

  factory SugestaoPlanejamentoIA.fromJson(Map<String, dynamic> json) {
    return SugestaoPlanejamentoIA(
      titulo: json['titulo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      impacto: json['impacto']?.toString() ?? '',
      prioridade: json['prioridade']?.toString() ?? 'media',
      itemRelacionado: json['itemRelacionado']?.toString(),
    );
  }
}
