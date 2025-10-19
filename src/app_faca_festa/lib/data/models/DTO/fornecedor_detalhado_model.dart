import '../model.dart';

class FornecedorDetalhadoModel {
  final FornecedorModel fornecedor;
  final TerritorioModel? territorio;
  final String categoriaNome;
  final double? distanciaKm;

  FornecedorDetalhadoModel({
    required this.fornecedor,
    required this.categoriaNome,
    this.territorio,
    this.distanciaKm,
  });
}
