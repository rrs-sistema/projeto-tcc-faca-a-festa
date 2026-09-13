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

  factory ItemPacoteFornecedorSugerido.fromMap(Map<String, dynamic> map) {
    return ItemPacoteFornecedorSugerido(
      nome: (map['nome'] ?? '').toString().trim(),
      quantidade: map['quantidade'] is num ? map['quantidade'] as num : null,
      tipoMedida: (map['tipo_medida'] ?? map['tipoMedida'] ?? '').toString().trim(),
      valor: map['valor'] is num ? (map['valor'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      if (quantidade != null) 'quantidade': quantidade,
      if (tipoMedida.isNotEmpty) 'tipo_medida': tipoMedida,
      if (valor != null) 'valor': valor,
    };
  }
}
