class ServicoProduto {
  final String id;
  final String nome;
  final String? tipoMedida;
  final String? descricao;
  final String? idSubcategoria;
  final bool ativo;

  const ServicoProduto({
    required this.id,
    required this.nome,
    this.tipoMedida,
    this.descricao,
    this.idSubcategoria,
    required this.ativo,
  });

  ServicoProduto copyWith({
    String? nome,
    String? tipoMedida,
    String? descricao,
    String? idSubcategoria,
    bool? ativo,
  }) {
    return ServicoProduto(
      id: id,
      nome: nome ?? this.nome,
      tipoMedida: tipoMedida ?? this.tipoMedida,
      descricao: descricao ?? this.descricao,
      idSubcategoria: idSubcategoria ?? this.idSubcategoria,
      ativo: ativo ?? this.ativo,
    );
  }
}
