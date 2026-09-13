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
}

const Object _unset = Object();
