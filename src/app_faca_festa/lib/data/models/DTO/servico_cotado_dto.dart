class ServicoCotadoDto {
  final String idProduto;
  final String nomeProduto;
  final int quantidade;
  final double? valor;

  ServicoCotadoDto({
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

  factory ServicoCotadoDto.fromMap(Map<String, dynamic> map) =>
      ServicoCotadoDto(
        idProduto: map['id_produto'],
        nomeProduto: map['nome_produto'],
        quantidade: map['quantidade'] ?? 1,
        valor: (map['valor'] as num?)?.toDouble(),
      );
}
