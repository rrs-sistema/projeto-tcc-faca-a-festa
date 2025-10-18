class TerritorioModel {
  final String idTerritorio;
  final String idFornecedor;
  final double? latitude;
  final double? longitude;
  final double? raioKm;
  final String? descricao;
  final bool ativo;

  const TerritorioModel({
    required this.idTerritorio,
    required this.idFornecedor,
    this.latitude,
    this.longitude,
    this.raioKm,
    this.descricao,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_territorio': idTerritorio,
      'id_fornecedor': idFornecedor,
      'latitude': latitude,
      'longitude': longitude,
      'raio_km': raioKm,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  factory TerritorioModel.fromMap(Map<String, dynamic> map) {
    return TerritorioModel(
      idTerritorio: map['id_territorio'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      raioKm: (map['raio_km'] as num?)?.toDouble(),
      descricao: map['descricao'],
      ativo: map['ativo'] ?? true,
    );
  }
}
