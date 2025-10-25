class ServicoCotado {
  final String idProduto;
  final String nomeProduto;
  final int quantidade;
  final double? valor;

  ServicoCotado({
    required this.idProduto,
    required this.nomeProduto,
    this.quantidade = 1,
    this.valor,
  });

  Map<String, dynamic> toMap() => {
        'id_produto': idProduto,
        'nome_produto': nomeProduto,
        'quantidade': quantidade,
        'valor': valor,
      };

  factory ServicoCotado.fromMap(Map<String, dynamic> map) => ServicoCotado(
        idProduto: map['id_produto'],
        nomeProduto: map['nome_produto'],
        quantidade: map['quantidade'] ?? 1,
        valor: (map['valor'] as num?)?.toDouble(),
      );
}
