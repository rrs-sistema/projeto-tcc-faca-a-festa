class ReferenciaEvento {
  final String id;
  final String eventoId;
  final String userId;
  final String inspiracaoId;
  final String titulo;
  final String descricao;
  final String imagemUrl;
  final String categoriaId;
  final String categoria;
  final List<String> tags;
  final List<String> galeriaUrls;
  final List<String> paletaCores;
  final bool favorito;
  final String status;
  final String prioridade;
  final String origem;
  final String anotacao;
  final bool ativo;
  final bool deletado;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  const ReferenciaEvento({
    required this.id,
    required this.eventoId,
    required this.userId,
    required this.inspiracaoId,
    required this.titulo,
    required this.descricao,
    required this.imagemUrl,
    required this.categoriaId,
    required this.categoria,
    required this.tags,
    required this.galeriaUrls,
    required this.paletaCores,
    required this.favorito,
    required this.status,
    required this.prioridade,
    required this.origem,
    required this.anotacao,
    required this.ativo,
    required this.deletado,
    this.criadoEm,
    this.atualizadoEm,
  });
}
