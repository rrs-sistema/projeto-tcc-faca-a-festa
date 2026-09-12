import 'fornecedor.dart';
import 'territorio.dart';

class FornecedorDetalhado {
  final Fornecedor fornecedor;
  final Territorio? territorio;
  final String categoriaId;
  final String categoriaNome;
  final double? distanciaKm;

  const FornecedorDetalhado({
    required this.fornecedor,
    required this.categoriaId,
    required this.categoriaNome,
    this.territorio,
    this.distanciaKm,
  });

  FornecedorDetalhado copyWith({
    Fornecedor? fornecedor,
    Territorio? territorio,
    String? categoriaId,
    String? categoriaNome,
    double? distanciaKm,
  }) {
    return FornecedorDetalhado(
      fornecedor: fornecedor ?? this.fornecedor,
      territorio: territorio ?? this.territorio,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNome: categoriaNome ?? this.categoriaNome,
      distanciaKm: distanciaKm ?? this.distanciaKm,
    );
  }
}
