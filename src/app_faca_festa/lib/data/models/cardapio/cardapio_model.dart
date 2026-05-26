enum PublicoAlvoCardapio {
  todos,
  adultos,
  criancas,
  bebes;

  String get firestoreValue {
    switch (this) {
      case PublicoAlvoCardapio.todos:
        return 'todos';
      case PublicoAlvoCardapio.adultos:
        return 'adultos';
      case PublicoAlvoCardapio.criancas:
        return 'criancas';
      case PublicoAlvoCardapio.bebes:
        return 'bebes';
    }
  }

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
      case 'todos':
      default:
        return PublicoAlvoCardapio.todos;
    }
  }
}

class CardapioModel {
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

  const CardapioModel({
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

  Map<String, dynamic> toMap() {
    return {
      'id_cardapio': idCardapio,
      'id_evento': idEvento,
      'titulo': titulo,
      'publico_alvo': publicoAlvo.firestoreValue,
      'icone': icone,
      'cor_hex': corHex,
      'total_itens': totalItens,
      'total_comidas': totalComidas,
      'total_bebidas': totalBebidas,
      'total_sobremesas': totalSobremesas,
      'ativo': ativo,
    };
  }

  factory CardapioModel.fromMap(Map<String, dynamic> map) {
    return CardapioModel(
      idCardapio: map['id_cardapio']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      titulo: map['titulo']?.toString() ?? '',
      publicoAlvo: PublicoAlvoCardapio.fromString(map['publico_alvo']),
      icone: map['icone']?.toString(),
      corHex: map['cor_hex']?.toString(),
      totalItens: map['total_itens'] is num ? (map['total_itens'] as num).toInt() : 0,
      totalComidas: map['total_comidas'] is num ? (map['total_comidas'] as num).toInt() : 0,
      totalBebidas: map['total_bebidas'] is num ? (map['total_bebidas'] as num).toInt() : 0,
      totalSobremesas:
          map['total_sobremesas'] is num ? (map['total_sobremesas'] as num).toInt() : 0,
      ativo: map['ativo'] ?? true,
    );
  }

  CardapioModel copyWith({
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
    return CardapioModel(
      idCardapio: idCardapio,
      idEvento: idEvento,
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
