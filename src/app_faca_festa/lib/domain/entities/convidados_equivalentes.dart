class ConvidadosEquivalentes {
  final int adultos;
  final int criancas;
  final int bebes;
  final double pesoAdulto;
  final double pesoCrianca;
  final double pesoBebe;

  const ConvidadosEquivalentes({
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
}
