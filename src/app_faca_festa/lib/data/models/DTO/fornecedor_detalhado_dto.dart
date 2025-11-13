import '../model.dart';

class FornecedorDetalhadoDto {
  final FornecedorModel fornecedor;
  final TerritorioModel? territorio;
  final String categoriaId;
  final String categoriaNome;
  final double? distanciaKm;

  FornecedorDetalhadoDto({
    required this.fornecedor,
    required this.categoriaId,
    required this.categoriaNome,
    this.territorio,
    this.distanciaKm,
  });

  // 🔹 Método copyWith elegante e completo
  FornecedorDetalhadoDto copyWith({
    FornecedorModel? fornecedor,
    TerritorioModel? territorio,
    String? categoriaId,
    String? categoriaNome,
    double? distanciaKm,
  }) {
    return FornecedorDetalhadoDto(
      fornecedor: fornecedor ?? this.fornecedor,
      territorio: territorio ?? this.territorio,
      categoriaId: categoriaId ?? this.categoriaId,
      categoriaNome: categoriaNome ?? this.categoriaNome,
      distanciaKm: distanciaKm ?? this.distanciaKm,
    );
  }
}
