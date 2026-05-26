import 'cardapio_model.dart';

enum TipoItemCardapio {
  comida,
  bebida,
  sobremesa,
  bolo,
  descartavel,
  outro;

  String get firestoreValue {
    switch (this) {
      case TipoItemCardapio.comida:
        return 'comida';
      case TipoItemCardapio.bebida:
        return 'bebida';
      case TipoItemCardapio.sobremesa:
        return 'sobremesa';
      case TipoItemCardapio.bolo:
        return 'bolo';
      case TipoItemCardapio.descartavel:
        return 'descartavel';
      case TipoItemCardapio.outro:
        return 'outro';
    }
  }

  static TipoItemCardapio fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'comida':
        return TipoItemCardapio.comida;
      case 'bebida':
        return TipoItemCardapio.bebida;
      case 'sobremesa':
        return TipoItemCardapio.sobremesa;
      case 'bolo':
        return TipoItemCardapio.bolo;
      case 'descartavel':
      case 'descartável':
        return TipoItemCardapio.descartavel;
      default:
        return TipoItemCardapio.outro;
    }
  }
}

class CardapioItemModel {
  final String idItem;
  final String idEvento;
  final String idCardapio;

  final String nome;
  final TipoItemCardapio tipo;
  final PublicoAlvoCardapio publicoAlvo;

  final double quantidadeSugerida;
  final double quantidadeFinal;
  final String unidade;

  final bool confirmado;
  final bool geradoPelaCalculadora;

  final String? observacao;

  const CardapioItemModel({
    required this.idItem,
    required this.idEvento,
    required this.idCardapio,
    required this.nome,
    this.tipo = TipoItemCardapio.outro,
    this.publicoAlvo = PublicoAlvoCardapio.todos,
    this.quantidadeSugerida = 0,
    this.quantidadeFinal = 0,
    this.unidade = 'un',
    this.confirmado = false,
    this.geradoPelaCalculadora = false,
    this.observacao,
  });

  Map<String, dynamic> toMap() {
    return {
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
  }

  factory CardapioItemModel.fromMap(Map<String, dynamic> map) {
    return CardapioItemModel(
      idItem: map['id_item']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      idCardapio: map['id_cardapio']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      tipo: TipoItemCardapio.fromString(map['tipo']),
      publicoAlvo: PublicoAlvoCardapio.fromString(map['publico_alvo']),
      quantidadeSugerida:
          map['quantidade_sugerida'] is num ? (map['quantidade_sugerida'] as num).toDouble() : 0,
      quantidadeFinal:
          map['quantidade_final'] is num ? (map['quantidade_final'] as num).toDouble() : 0,
      unidade: map['unidade']?.toString() ?? 'un',
      confirmado: map['confirmado'] ?? false,
      geradoPelaCalculadora: map['gerado_pela_calculadora'] ?? false,
      observacao: map['observacao']?.toString(),
    );
  }

  CardapioItemModel copyWith({
    String? nome,
    TipoItemCardapio? tipo,
    PublicoAlvoCardapio? publicoAlvo,
    double? quantidadeSugerida,
    double? quantidadeFinal,
    String? unidade,
    bool? confirmado,
    bool? geradoPelaCalculadora,
    String? observacao,
  }) {
    return CardapioItemModel(
      idItem: idItem,
      idEvento: idEvento,
      idCardapio: idCardapio,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      quantidadeSugerida: quantidadeSugerida ?? this.quantidadeSugerida,
      quantidadeFinal: quantidadeFinal ?? this.quantidadeFinal,
      unidade: unidade ?? this.unidade,
      confirmado: confirmado ?? this.confirmado,
      geradoPelaCalculadora: geradoPelaCalculadora ?? this.geradoPelaCalculadora,
      observacao: observacao ?? this.observacao,
    );
  }
}
