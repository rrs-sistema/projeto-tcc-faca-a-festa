class RankingServico {
  const RankingServico({
    required this.id,
    required this.idFornecedor,
    required this.idProdutoServico,
    required this.media,
    required this.totalAvaliacoes,
  });

  final String id;
  final String idFornecedor;
  final String idProdutoServico;
  final double media;
  final int totalAvaliacoes;
}
