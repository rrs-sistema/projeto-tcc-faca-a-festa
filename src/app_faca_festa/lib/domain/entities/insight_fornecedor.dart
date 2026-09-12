class InsightFornecedor {
  final String idInsight;
  final String idFornecedor;
  final String? idEvento;
  final String? idCotacao;
  final String tipo;
  final String titulo;
  final String descricao;
  final int prioridade;
  final double? score;
  final String? nivel;
  final List<String> motivos;
  final List<String> acoesSugeridas;
  final String origem;
  final String status;
  final String versaoRegra;
  final Map<String, dynamic>? metadados;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const InsightFornecedor({
    required this.idInsight,
    required this.idFornecedor,
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.origem,
    required this.status,
    required this.versaoRegra,
    required this.createdAt,
    this.idEvento,
    this.idCotacao,
    this.score,
    this.nivel,
    this.motivos = const [],
    this.acoesSugeridas = const [],
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });
}
