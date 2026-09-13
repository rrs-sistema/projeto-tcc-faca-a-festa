class GatilhosSugestaoBaseFesta {
  const GatilhosSugestaoBaseFesta({
    this.diasAntesEvento,
    this.duracaoMinimaHoras,
    this.riscoMinimo,
    this.criancasMinimo,
    this.adultosMinimo,
    this.quantidadeMinimaConvidados,
    this.percentualCriancasMinimo,
    this.diferencaOrcamentoMaxima,
    this.fornecedoresPendentesMinimo,
    this.tarefasPendentesMinimo,
    this.convidadosEquivalentesMinimo,
  });

  static const empty = GatilhosSugestaoBaseFesta();

  final int? diasAntesEvento;
  final int? duracaoMinimaHoras;
  final int? riscoMinimo;
  final int? criancasMinimo;
  final int? adultosMinimo;
  final int? quantidadeMinimaConvidados;
  final int? percentualCriancasMinimo;
  final int? diferencaOrcamentoMaxima;
  final int? fornecedoresPendentesMinimo;
  final int? tarefasPendentesMinimo;
  final int? convidadosEquivalentesMinimo;

  factory GatilhosSugestaoBaseFesta.fromMap(Map<String, dynamic> map) {
    return GatilhosSugestaoBaseFesta(
      diasAntesEvento: _asInt(map['dias_antes_evento']),
      duracaoMinimaHoras: _asInt(map['duracao_minima_horas']),
      riscoMinimo: _asInt(map['risco_minimo']),
      criancasMinimo: _asInt(map['criancas_minimo']),
      adultosMinimo: _asInt(map['adultos_minimo']),
      quantidadeMinimaConvidados: _asInt(map['quantidade_minima_convidados']),
      percentualCriancasMinimo: _asInt(map['percentual_criancas_minimo']),
      diferencaOrcamentoMaxima: _asInt(map['diferenca_orcamento_maxima']),
      fornecedoresPendentesMinimo: _asInt(map['fornecedores_pendentes_minimo']),
      tarefasPendentesMinimo: _asInt(map['tarefas_pendentes_minimo']),
      convidadosEquivalentesMinimo:
          _asInt(map['convidados_equivalentes_minimo']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (diasAntesEvento != null) 'dias_antes_evento': diasAntesEvento,
      if (duracaoMinimaHoras != null)
        'duracao_minima_horas': duracaoMinimaHoras,
      if (riscoMinimo != null) 'risco_minimo': riscoMinimo,
      if (criancasMinimo != null) 'criancas_minimo': criancasMinimo,
      if (adultosMinimo != null) 'adultos_minimo': adultosMinimo,
      if (quantidadeMinimaConvidados != null)
        'quantidade_minima_convidados': quantidadeMinimaConvidados,
      if (percentualCriancasMinimo != null)
        'percentual_criancas_minimo': percentualCriancasMinimo,
      if (diferencaOrcamentoMaxima != null)
        'diferenca_orcamento_maxima': diferencaOrcamentoMaxima,
      if (fornecedoresPendentesMinimo != null)
        'fornecedores_pendentes_minimo': fornecedoresPendentesMinimo,
      if (tarefasPendentesMinimo != null)
        'tarefas_pendentes_minimo': tarefasPendentesMinimo,
      if (convidadosEquivalentesMinimo != null)
        'convidados_equivalentes_minimo': convidadosEquivalentesMinimo,
    };
  }

  GatilhosSugestaoBaseFesta copyWith({
    Object? diasAntesEvento = _unset,
    Object? duracaoMinimaHoras = _unset,
    Object? riscoMinimo = _unset,
    Object? criancasMinimo = _unset,
    Object? adultosMinimo = _unset,
    Object? quantidadeMinimaConvidados = _unset,
    Object? percentualCriancasMinimo = _unset,
    Object? diferencaOrcamentoMaxima = _unset,
    Object? fornecedoresPendentesMinimo = _unset,
    Object? tarefasPendentesMinimo = _unset,
    Object? convidadosEquivalentesMinimo = _unset,
  }) {
    return GatilhosSugestaoBaseFesta(
      diasAntesEvento: identical(diasAntesEvento, _unset)
          ? this.diasAntesEvento
          : diasAntesEvento as int?,
      duracaoMinimaHoras: identical(duracaoMinimaHoras, _unset)
          ? this.duracaoMinimaHoras
          : duracaoMinimaHoras as int?,
      riscoMinimo: identical(riscoMinimo, _unset)
          ? this.riscoMinimo
          : riscoMinimo as int?,
      criancasMinimo: identical(criancasMinimo, _unset)
          ? this.criancasMinimo
          : criancasMinimo as int?,
      adultosMinimo: identical(adultosMinimo, _unset)
          ? this.adultosMinimo
          : adultosMinimo as int?,
      quantidadeMinimaConvidados:
          identical(quantidadeMinimaConvidados, _unset)
              ? this.quantidadeMinimaConvidados
              : quantidadeMinimaConvidados as int?,
      percentualCriancasMinimo: identical(percentualCriancasMinimo, _unset)
          ? this.percentualCriancasMinimo
          : percentualCriancasMinimo as int?,
      diferencaOrcamentoMaxima: identical(diferencaOrcamentoMaxima, _unset)
          ? this.diferencaOrcamentoMaxima
          : diferencaOrcamentoMaxima as int?,
      fornecedoresPendentesMinimo:
          identical(fornecedoresPendentesMinimo, _unset)
              ? this.fornecedoresPendentesMinimo
              : fornecedoresPendentesMinimo as int?,
      tarefasPendentesMinimo: identical(tarefasPendentesMinimo, _unset)
          ? this.tarefasPendentesMinimo
          : tarefasPendentesMinimo as int?,
      convidadosEquivalentesMinimo:
          identical(convidadosEquivalentesMinimo, _unset)
              ? this.convidadosEquivalentesMinimo
              : convidadosEquivalentesMinimo as int?,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }
}

const Object _unset = Object();
