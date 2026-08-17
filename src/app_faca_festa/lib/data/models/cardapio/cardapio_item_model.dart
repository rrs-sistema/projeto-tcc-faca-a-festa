import '../../../domain/entities/cardapio_item.dart';
import 'cardapio_model.dart';

export '../../../domain/entities/cardapio_item.dart';

extension TipoItemCardapioPersistence on TipoItemCardapio {
  String get firestoreValue => name;
}

class CardapioItemModel extends CardapioItem {
  const CardapioItemModel({
    required super.idItem,
    required super.idEvento,
    required super.idCardapio,
    required super.nome,
    super.tipo,
    super.publicoAlvo,
    super.quantidadeSugerida,
    super.quantidadeFinal,
    super.unidade,
    super.confirmado,
    super.geradoPelaCalculadora,
    super.observacao,
  });

  factory CardapioItemModel.fromEntity(CardapioItem item) => CardapioItemModel(
        idItem: item.idItem,
        idEvento: item.idEvento,
        idCardapio: item.idCardapio,
        nome: item.nome,
        tipo: item.tipo,
        publicoAlvo: item.publicoAlvo,
        quantidadeSugerida: item.quantidadeSugerida,
        quantidadeFinal: item.quantidadeFinal,
        unidade: item.unidade,
        confirmado: item.confirmado,
        geradoPelaCalculadora: item.geradoPelaCalculadora,
        observacao: item.observacao,
      );

  Map<String, dynamic> toMap() => {
        'id_item': idItem,
        'id_evento': idEvento,
        'id_cardapio': idCardapio,
        'nome': nome,
        'tipo': tipo.firestoreValue,
        'publico_alvo': publicoAlvo.firestoreValue,
        'quantidade_sugerida': quantidadeSugerida,
        'quantidade_final': quantidadeFinal,
        'unidade': unidade,
        'confirmado': confirmado,
        'gerado_pela_calculadora': geradoPelaCalculadora,
        'observacao': observacao,
      };

  factory CardapioItemModel.fromMap(Map<String, dynamic> map) =>
      CardapioItemModel(
        idItem: map['id_item']?.toString() ?? '',
        idEvento: map['id_evento']?.toString() ?? '',
        idCardapio: map['id_cardapio']?.toString() ?? '',
        nome: map['nome']?.toString() ?? '',
        tipo: TipoItemCardapio.fromString(map['tipo']),
        publicoAlvo: PublicoAlvoCardapio.fromString(map['publico_alvo']),
        quantidadeSugerida: _doubleValue(map['quantidade_sugerida']),
        quantidadeFinal: _doubleValue(map['quantidade_final']),
        unidade: map['unidade']?.toString() ?? 'un',
        confirmado: map['confirmado'] ?? false,
        geradoPelaCalculadora: map['gerado_pela_calculadora'] ?? false,
        observacao: map['observacao']?.toString(),
      );

  static double _doubleValue(dynamic value) =>
      value is num ? value.toDouble() : 0;

  @override
  CardapioItemModel copyWith({
    String? idItem,
    String? idEvento,
    String? idCardapio,
    String? nome,
    TipoItemCardapio? tipo,
    PublicoAlvoCardapio? publicoAlvo,
    double? quantidadeSugerida,
    double? quantidadeFinal,
    String? unidade,
    bool? confirmado,
    bool? geradoPelaCalculadora,
    String? observacao,
  }) =>
      CardapioItemModel(
        idItem: idItem ?? this.idItem,
        idEvento: idEvento ?? this.idEvento,
        idCardapio: idCardapio ?? this.idCardapio,
        nome: nome ?? this.nome,
        tipo: tipo ?? this.tipo,
        publicoAlvo: publicoAlvo ?? this.publicoAlvo,
        quantidadeSugerida: quantidadeSugerida ?? this.quantidadeSugerida,
        quantidadeFinal: quantidadeFinal ?? this.quantidadeFinal,
        unidade: unidade ?? this.unidade,
        confirmado: confirmado ?? this.confirmado,
        geradoPelaCalculadora:
            geradoPelaCalculadora ?? this.geradoPelaCalculadora,
        observacao: observacao ?? this.observacao,
      );
}
