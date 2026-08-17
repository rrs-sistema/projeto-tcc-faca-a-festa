import 'cardapio.dart';

enum TipoItemCardapio {
  comida,
  bebida,
  sobremesa,
  bolo,
  descartavel,
  outro;

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

class CardapioItem {
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

  const CardapioItem({
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

  CardapioItem copyWith({
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
  }) {
    return CardapioItem(
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
}
