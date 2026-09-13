import 'package:app_faca_festa/domain/entities/territorio.dart';


class TerritorioModel extends Territorio {
  const TerritorioModel({
    required super.idTerritorio,
    required super.idFornecedor,
    super.latitude,
    super.longitude,
    super.raioKm,
    super.descricao,
    super.ativo = true,
    super.tipoCobertura,
    super.regioes,
  });

  @override
  TerritorioModel copyWith({
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
    return TerritorioModel(
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

  Map<String, dynamic> toMap() => {
        'id_territorio': idTerritorio,
        'id_fornecedor': idFornecedor,
        'latitude': latitude,
        'longitude': longitude,
        'raio_km': raioKm,
        'descricao': descricao,
        'ativo': ativo,
        'tipo_cobertura': tipoCobertura,
        'regioes': regioes,
      };

  factory TerritorioModel.fromMap(Map<String, dynamic> map) => TerritorioModel(
        idTerritorio: map['id_territorio'] ?? '',
        idFornecedor: map['id_fornecedor'] ?? '',
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        raioKm: (map['raio_km'] as num?)?.toDouble(),
        descricao: map['descricao'],
        ativo: map['ativo'] ?? true,
        tipoCobertura: map['tipo_cobertura'],
        regioes:
            (map['regioes'] is List) ? List<String>.from(map['regioes']) : null,
      );

  factory TerritorioModel.fromEntity(Territorio territorio) {
    if (territorio is TerritorioModel) return territorio;

    return TerritorioModel(
      idTerritorio: territorio.idTerritorio,
      idFornecedor: territorio.idFornecedor,
      latitude: territorio.latitude,
      longitude: territorio.longitude,
      raioKm: territorio.raioKm,
      descricao: territorio.descricao,
      ativo: territorio.ativo,
      tipoCobertura: territorio.tipoCobertura,
      regioes: territorio.regioes,
    );
  }
}
