class SugestaoRespostaCotacaoAi {
  final String respostaSugerida;
  final String versaoCurta;
  final List<String> pontosParaRevisar;
  final List<String> perguntasFaltantes;
  final List<String> dadosUtilizados;
  final List<String> alertas;
  final String nivelConfianca;
  final String motivoNivelConfianca;

  const SugestaoRespostaCotacaoAi({
    required this.respostaSugerida,
    required this.versaoCurta,
    required this.pontosParaRevisar,
    required this.perguntasFaltantes,
    required this.dadosUtilizados,
    required this.alertas,
    required this.nivelConfianca,
    required this.motivoNivelConfianca,
  });

  const SugestaoRespostaCotacaoAi.empty()
      : respostaSugerida = '',
        versaoCurta = '',
        pontosParaRevisar = const [],
        perguntasFaltantes = const [],
        dadosUtilizados = const [],
        alertas = const [],
        nivelConfianca = 'baixo',
        motivoNivelConfianca = '';
}
