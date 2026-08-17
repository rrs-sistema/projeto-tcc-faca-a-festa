import '../../../domain/entities/cardapio.dart';

export '../../../domain/entities/cardapio.dart';

extension PublicoAlvoCardapioPersistence on PublicoAlvoCardapio {
  String get firestoreValue => name;
}

class CardapioModel extends Cardapio {
  const CardapioModel({
    required super.idCardapio,
    required super.idEvento,
    required super.titulo,
    super.publicoAlvo,
    super.icone,
    super.corHex,
    super.totalItens,
    super.totalComidas,
    super.totalBebidas,
    super.totalSobremesas,
    super.ativo,
  });

  factory CardapioModel.fromEntity(Cardapio cardapio) => CardapioModel(
        idCardapio: cardapio.idCardapio,
        idEvento: cardapio.idEvento,
        titulo: cardapio.titulo,
        publicoAlvo: cardapio.publicoAlvo,
        icone: cardapio.icone,
        corHex: cardapio.corHex,
        totalItens: cardapio.totalItens,
        totalComidas: cardapio.totalComidas,
        totalBebidas: cardapio.totalBebidas,
        totalSobremesas: cardapio.totalSobremesas,
        ativo: cardapio.ativo,
      );

  Map<String, dynamic> toMap() => {
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

  factory CardapioModel.fromMap(Map<String, dynamic> map) => CardapioModel(
        idCardapio: map['id_cardapio']?.toString() ?? '',
        idEvento: map['id_evento']?.toString() ?? '',
        titulo: map['titulo']?.toString() ?? '',
        publicoAlvo: PublicoAlvoCardapio.fromString(map['publico_alvo']),
        icone: map['icone']?.toString(),
        corHex: map['cor_hex']?.toString(),
        totalItens: _intValue(map['total_itens']),
        totalComidas: _intValue(map['total_comidas']),
        totalBebidas: _intValue(map['total_bebidas']),
        totalSobremesas: _intValue(map['total_sobremesas']),
        ativo: map['ativo'] ?? true,
      );

  static int _intValue(dynamic value) => value is num ? value.toInt() : 0;

  @override
  CardapioModel copyWith({
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
  }) =>
      CardapioModel(
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
