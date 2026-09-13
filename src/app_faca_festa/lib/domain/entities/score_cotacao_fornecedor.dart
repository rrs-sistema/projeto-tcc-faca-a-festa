class ScoreCotacaoFornecedor {
  final String idScore;
  final String idCotacao;
  final String idFornecedor;
  final String idEvento;
  final double score;
  final String nivel;
  final double compatibilidadeTipoEvento;
  final double compatibilidadeCategoria;
  final double compatibilidadeOrcamento;
  final double compatibilidadeLocalizacao;
  final double scoreUrgencia;
  final double scoreInteracao;
  final double scoreReputacao;
  final List<String> motivosPositivos;
  final List<String> alertas;
  final List<String> penalidades;
  final String origem;
  final String versaoRegra;
  final DateTime calculadoEm;
  final DateTime? expiresAt;

  const ScoreCotacaoFornecedor({
    required this.idScore,
    required this.idCotacao,
    required this.idFornecedor,
    required this.idEvento,
    required this.score,
    required this.nivel,
    required this.compatibilidadeTipoEvento,
    required this.compatibilidadeCategoria,
    required this.compatibilidadeOrcamento,
    required this.compatibilidadeLocalizacao,
    required this.scoreUrgencia,
    required this.scoreInteracao,
    required this.scoreReputacao,
    required this.origem,
    required this.versaoRegra,
    required this.calculadoEm,
    this.motivosPositivos = const [],
    this.alertas = const [],
    this.penalidades = const [],
    this.expiresAt,
  });
}
