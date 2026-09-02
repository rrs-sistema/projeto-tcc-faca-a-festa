class ConvidadosEquivalentesModel {
  final int adultos;
  final int criancas;
  final int bebes;

  /// Pesos de consumo usados para transformar pessoas em consumo equivalente.
  final double pesoAdulto;
  final double pesoCrianca;
  final double pesoBebe;

  const ConvidadosEquivalentesModel({
    required this.adultos,
    required this.criancas,
    required this.bebes,
    this.pesoAdulto = 1.0,
    this.pesoCrianca = 0.6,
    this.pesoBebe = 0.2,
  });

  int get totalInformado => adultos + criancas + bebes;

  double get totalEquivalente {
    return (adultos * pesoAdulto) +
        (criancas * pesoCrianca) +
        (bebes * pesoBebe);
  }

  int get totalEquivalenteArredondado => totalEquivalente.ceil();

  bool get possuiConvidados => totalInformado > 0;

  String get resumoInformado {
    return '$adultos adultos, $criancas crianças e $bebes bebês';
  }

  String get resumoEquivalente {
    return '$totalEquivalenteArredondado convidados equivalentes';
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
