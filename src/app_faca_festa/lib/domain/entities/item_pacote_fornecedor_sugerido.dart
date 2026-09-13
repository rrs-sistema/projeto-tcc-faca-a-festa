class ItemPacoteFornecedorSugerido {
  const ItemPacoteFornecedorSugerido({
    required this.nome,
    this.quantidade,
    this.tipoMedida = '',
    this.valor,
  });

  final String nome;
  final num? quantidade;
  final String tipoMedida;
  final double? valor;
}
