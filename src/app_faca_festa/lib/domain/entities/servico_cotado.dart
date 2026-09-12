class ServicoCotado {
  final String idProduto;
  final String nomeProduto;
  final int quantidade;
  final double? valor;

  const ServicoCotado({
    required this.idProduto,
    required this.nomeProduto,
    this.quantidade = 1,
    this.valor,
  });
}
