import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';

class FornecedorCategoria {
  final String idFornecedor;
  final String idCategoria;
  final String? nomeCategoria;
  final List<FornecedorSubcategoriaResumo> subcategorias;
  final DateTime? dataCadastro;

  const FornecedorCategoria({
    required this.idFornecedor,
    required this.idCategoria,
    this.nomeCategoria,
    this.subcategorias = const [],
    this.dataCadastro,
  });

  FornecedorCategoria copyWith({
    String? idFornecedor,
    String? idCategoria,
    String? nomeCategoria,
    List<FornecedorSubcategoriaResumo>? subcategorias,
    DateTime? dataCadastro,
  }) {
    return FornecedorCategoria(
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idCategoria: idCategoria ?? this.idCategoria,
      nomeCategoria: nomeCategoria ?? this.nomeCategoria,
      subcategorias: subcategorias ?? this.subcategorias,
      dataCadastro: dataCadastro ?? this.dataCadastro,
    );
  }
}
