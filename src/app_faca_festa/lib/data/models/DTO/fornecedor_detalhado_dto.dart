import 'package:app_faca_festa/domain/entities/fornecedor_detalhado.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';

export 'package:app_faca_festa/domain/entities/fornecedor_detalhado.dart';

class FornecedorDetalhadoDto extends FornecedorDetalhado {
  FornecedorDetalhadoDto({
    required super.fornecedor,
    required super.categoriaId,
    required super.categoriaNome,
    super.territorio,
    super.distanciaKm,
  });

  factory FornecedorDetalhadoDto.fromEntity(FornecedorDetalhado entity) {
    if (entity is FornecedorDetalhadoDto) {
      return entity;
    }

    return FornecedorDetalhadoDto(
      fornecedor: entity.fornecedor,
      categoriaId: entity.categoriaId,
      categoriaNome: entity.categoriaNome,
      territorio: entity.territorio,
      distanciaKm: entity.distanciaKm,
    );
  }

  @override
  FornecedorDetalhadoDto copyWith({
    Fornecedor? fornecedor,
    Territorio? territorio,
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
