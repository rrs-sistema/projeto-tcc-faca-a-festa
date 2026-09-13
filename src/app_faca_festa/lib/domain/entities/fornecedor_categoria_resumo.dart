class FornecedorCategoriaResumo {
  const FornecedorCategoriaResumo({
    this.idCategoria = '',
    this.nomeCategoria = '',
    this.descricao,
    this.subcategorias = const [],
    this.dataCadastro,
  });

  final String idCategoria;
  final String nomeCategoria;
  final String? descricao;
  final List<FornecedorSubcategoriaResumo> subcategorias;
  final DateTime? dataCadastro;

  Iterable<String> get termosBusca sync* {
    final nome = nomeCategoria.trim();
    if (nome.isNotEmpty) yield nome;

    final textoDescricao = descricao?.trim();
    if (textoDescricao != null && textoDescricao.isNotEmpty) {
      yield textoDescricao;
    }

    for (final subcategoria in subcategorias) {
      final nomeSub = subcategoria.nomeSubcategoria.trim();
      if (nomeSub.isNotEmpty) yield nomeSub;
    }
  }
}

class FornecedorSubcategoriaResumo {
  const FornecedorSubcategoriaResumo({
    this.idSubcategoria = '',
    this.nomeSubcategoria = '',
  });

  final String idSubcategoria;
  final String nomeSubcategoria;
}
