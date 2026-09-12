class Territorio {
  const Territorio({
    required this.idTerritorio,
    required this.idFornecedor,
    this.latitude,
    this.longitude,
    this.raioKm,
    this.descricao,
    this.ativo = true,
    this.tipoCobertura,
    this.regioes,
  });

  final String idTerritorio;
  final String idFornecedor;
  final double? latitude;
  final double? longitude;
  final double? raioKm;
  final String? descricao;
  final bool ativo;
  final String? tipoCobertura;
  final List<String>? regioes;

  Territorio copyWith({
    String? idTerritorio,
    String? idFornecedor,
    double? latitude,
    double? longitude,
    double? raioKm,
    String? descricao,
    bool? ativo,
    String? tipoCobertura,
    List<String>? regioes,
  }) {
    return Territorio(
      idTerritorio: idTerritorio ?? this.idTerritorio,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      raioKm: raioKm ?? this.raioKm,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      tipoCobertura: tipoCobertura ?? this.tipoCobertura,
      regioes: regioes ?? this.regioes,
    );
  }
}
