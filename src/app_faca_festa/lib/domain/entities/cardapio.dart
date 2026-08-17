enum PublicoAlvoCardapio {
  todos,
  adultos,
  criancas,
  bebes;

  static PublicoAlvoCardapio fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'adultos':
        return PublicoAlvoCardapio.adultos;
      case 'criancas':
      case 'crianças':
        return PublicoAlvoCardapio.criancas;
      case 'bebes':
      case 'bebês':
        return PublicoAlvoCardapio.bebes;
      default:
        return PublicoAlvoCardapio.todos;
    }
  }
}

class Cardapio {
  final String idCardapio;
  final String idEvento;
  final String titulo;
  final PublicoAlvoCardapio publicoAlvo;
  final String? icone;
  final String? corHex;
  final int totalItens;
  final int totalComidas;
  final int totalBebidas;
  final int totalSobremesas;
  final bool ativo;

  const Cardapio({
    required this.idCardapio,
    required this.idEvento,
    required this.titulo,
    this.publicoAlvo = PublicoAlvoCardapio.todos,
    this.icone,
    this.corHex,
    this.totalItens = 0,
    this.totalComidas = 0,
    this.totalBebidas = 0,
    this.totalSobremesas = 0,
    this.ativo = true,
  });

  Cardapio copyWith({
    String? idCardapio,
    String? idEvento,
    String? titulo,
    PublicoAlvoCardapio? publicoAlvo,
    String? icone,
    String? corHex,
    int? totalItens,
    int? totalComidas,
    int? totalBebidas,
    int? totalSobremesas,
    bool? ativo,
  }) {
    return Cardapio(
      idCardapio: idCardapio ?? this.idCardapio,
      idEvento: idEvento ?? this.idEvento,
      titulo: titulo ?? this.titulo,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      icone: icone ?? this.icone,
      corHex: corHex ?? this.corHex,
      totalItens: totalItens ?? this.totalItens,
      totalComidas: totalComidas ?? this.totalComidas,
      totalBebidas: totalBebidas ?? this.totalBebidas,
      totalSobremesas: totalSobremesas ?? this.totalSobremesas,
      ativo: ativo ?? this.ativo,
    );
  }
}
