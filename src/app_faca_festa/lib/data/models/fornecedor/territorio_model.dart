import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory TerritorioModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) =>
      TerritorioModel(
        idTerritorio: _texto(
          map,
          ['id_territorio', 'idTerritorio'],
          fallback: documentId ?? '',
        ),
        idFornecedor: _texto(map, ['id_fornecedor', 'idFornecedor']),
        latitude: _double(map, ['latitude', 'lat']),
        longitude: _double(map, ['longitude', 'lng', 'lon']),
        raioKm: _double(map, ['raio_km', 'raioKm']),
        descricao: _textoOpcional(map, ['descricao']),
        ativo: _bool(map, ['ativo'], fallback: true),
        tipoCobertura: _textoOpcional(
          map,
          ['tipo_cobertura', 'tipoCobertura'],
        ),
        regioes: _regioes(map['regioes']),
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

  static String _texto(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String? _textoOpcional(Map<String, dynamic> map, List<String> keys) {
    final value = _texto(map, keys);
    return value.isEmpty ? null : value;
  }

  static bool _bool(
    Map<String, dynamic> map,
    List<String> keys, {
    bool fallback = false,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final n = value.trim().toLowerCase();
        if (['true', '1', 's', 'sim'].contains(n)) return true;
        if (['false', '0', 'n', 'nao', 'não'].contains(n)) return false;
      }
    }
    return fallback;
  }

  static double? _double(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static List<String>? _regioes(dynamic value) {
    if (value is! List) return null;
    final itens = <String>[];
    for (final item in value) {
      if (item is String && item.trim().isNotEmpty) {
        itens.add(item.trim());
        continue;
      }
      if (item is GeoPoint) {
        itens.add('${item.latitude},${item.longitude}');
        continue;
      }
      if (item is Map) {
        final mapa = Map<String, dynamic>.from(item);
        final lat = mapa['latitude'] ?? mapa['lat'];
        final lon = mapa['longitude'] ?? mapa['lng'] ?? mapa['lon'];
        if (lat != null && lon != null) {
          itens.add('$lat,$lon');
        }
      }
    }
    return itens.isEmpty ? null : itens;
  }
}
