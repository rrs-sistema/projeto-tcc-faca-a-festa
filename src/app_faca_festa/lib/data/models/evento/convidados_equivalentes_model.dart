import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';


class ConvidadosEquivalentesModel extends ConvidadosEquivalentes {
  const ConvidadosEquivalentesModel({
    required super.adultos,
    required super.criancas,
    required super.bebes,
    super.pesoAdulto = 1.0,
    super.pesoCrianca = 0.6,
    super.pesoBebe = 0.2,
  });

  factory ConvidadosEquivalentesModel.fromEntity(
    ConvidadosEquivalentes entity,
  ) {
    if (entity is ConvidadosEquivalentesModel) return entity;

    return ConvidadosEquivalentesModel(
      adultos: entity.adultos,
      criancas: entity.criancas,
      bebes: entity.bebes,
      pesoAdulto: entity.pesoAdulto,
      pesoCrianca: entity.pesoCrianca,
      pesoBebe: entity.pesoBebe,
    );
  }

  ConvidadosEquivalentesModel copyWith({
    int? adultos,
    int? criancas,
    int? bebes,
    double? pesoAdulto,
    double? pesoCrianca,
    double? pesoBebe,
  }) {
    return ConvidadosEquivalentesModel(
      adultos: adultos ?? this.adultos,
      criancas: criancas ?? this.criancas,
      bebes: bebes ?? this.bebes,
      pesoAdulto: pesoAdulto ?? this.pesoAdulto,
      pesoCrianca: pesoCrianca ?? this.pesoCrianca,
      pesoBebe: pesoBebe ?? this.pesoBebe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adultos': adultos,
      'criancas': criancas,
      'bebes': bebes,
      'peso_adulto': pesoAdulto,
      'peso_crianca': pesoCrianca,
      'peso_bebe': pesoBebe,
      'total_informado': totalInformado,
      'total_equivalente': totalEquivalente,
      'total_equivalente_arredondado': totalEquivalenteArredondado,
    };
  }

  factory ConvidadosEquivalentesModel.fromMap(Map<String, dynamic> map) {
    return ConvidadosEquivalentesModel(
      adultos: _asInt(map['adultos']),
      criancas: _asInt(map['criancas']),
      bebes: _asInt(map['bebes']),
      pesoAdulto: _asDouble(map['peso_adulto'] ?? map['pesoAdulto'], 1.0),
      pesoCrianca: _asDouble(map['peso_crianca'] ?? map['pesoCrianca'], 0.6),
      pesoBebe: _asDouble(map['peso_bebe'] ?? map['pesoBebe'], 0.2),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ??
        fallback;
  }
}
