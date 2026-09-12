class CategoriaServico {
  final String id;
  final String nome;
  final String? descricao;
  final bool ativo;
  final int ordem;
  final String icone;
  final DateTime? dataCadastro;
  final DateTime? dataAtualizacao;

  const CategoriaServico({
    required this.id,
    required this.nome,
    this.descricao,
    this.ativo = true,
    this.ordem = 0,
    this.icone = 'category',
    this.dataCadastro,
    this.dataAtualizacao,
  });

  CategoriaServico copyWith({
    String? nome,
    String? descricao,
    bool? ativo,
    int? ordem,
    String? icone,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
  }) {
    return CategoriaServico(
      id: id,
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
