class ProximaAcaoFornecedor {
  final String idAcao;
  final String idFornecedor;
  final String? idEvento;
  final String? idCotacao;
  final String tipoAcao;
  final String titulo;
  final String descricao;
  final String acaoPrincipal;
  final List<String> acoesSecundarias;
  final List<String> motivos;
  final int prioridade;
  final bool urgente;
  final double? score;
  final String? statusCotacao;
  final String origem;
  final String versaoRegra;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const ProximaAcaoFornecedor({
    required this.idAcao,
    required this.idFornecedor,
    required this.tipoAcao,
    required this.titulo,
    required this.descricao,
    required this.acaoPrincipal,
    required this.prioridade,
    required this.urgente,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.idEvento,
    this.idCotacao,
    this.acoesSecundarias = const [],
    this.motivos = const [],
    this.score,
    this.statusCotacao,
    this.updatedAt,
    this.expiresAt,
  });
}
