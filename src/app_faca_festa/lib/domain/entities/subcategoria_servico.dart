class SubcategoriaServico {
  final String id;
  final String idCategoria;
  final String nome;
  final String? descricao;
  final bool ativo;
  final int ordem;
  final String icone;
  final DateTime? dataCadastro;
  final DateTime? dataAtualizacao;

  const SubcategoriaServico({
    required this.id,
    required this.idCategoria,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.ordem = 0,
    this.icone = 'category',
    this.dataCadastro,
    this.dataAtualizacao,
  });

  SubcategoriaServico copyWith({
    String? idCategoria,
    String? nome,
    String? descricao,
    bool? ativo,
    int? ordem,
    String? icone,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
  }) {
    return SubcategoriaServico(
      id: id,
      idCategoria: idCategoria ?? this.idCategoria,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      icone: icone ?? this.icone,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }
}
