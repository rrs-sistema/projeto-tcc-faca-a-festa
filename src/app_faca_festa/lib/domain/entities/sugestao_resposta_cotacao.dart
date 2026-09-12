class SugestaoRespostaCotacao {
  final String idSugestao;
  final String idCotacao;
  final String idFornecedor;
  final String? idEvento;
  final String titulo;
  final String mensagem;
  final String tom;
  final String templateKey;
  final List<String> camposUsados;
  final List<String> camposAusentes;
  final bool precisaRevisao;
  final String origem;
  final String versaoRegra;
  final String status;
  final Map<String, dynamic>? metadados;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const SugestaoRespostaCotacao({
    required this.idSugestao,
    required this.idCotacao,
    required this.idFornecedor,
    required this.titulo,
    required this.mensagem,
    required this.tom,
    required this.templateKey,
    required this.precisaRevisao,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.idEvento,
    this.camposUsados = const [],
    this.camposAusentes = const [],
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });
}
