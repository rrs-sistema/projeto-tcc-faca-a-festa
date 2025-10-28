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
}
