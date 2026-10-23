enum EscopoCardapio {
  naoDefinido,
  refeicao,
  categoria,
  compartilhado;

  String get label => switch (this) {
        naoDefinido => 'Ainda não definido',
        refeicao => 'Refeição (almoço, lanche ou jantar)',
        categoria => 'Categoria (comidas, bebidas e outros)',
        compartilhado => 'Serviço para várias refeições',
      };
  static EscopoCardapio fromString(String? valor) =>
      EscopoCardapio.values.firstWhere((e) => e.name == valor,
          orElse: () => EscopoCardapio.naoDefinido);
}

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
  final EscopoCardapio escopo;
  final PublicoAlvoCardapio publicoAlvo;
  final String? icone;
  final String? corHex;
  final int totalItens;
  final int totalComidas;
  final int totalBebidas;
  final int totalSobremesas;
  final bool ativo;
  final bool somenteModelo;
  final String? idModelo;

  const Cardapio({
    required this.idCardapio,
    required this.idEvento,
    required this.titulo,
    this.escopo = EscopoCardapio.naoDefinido,
    this.publicoAlvo = PublicoAlvoCardapio.todos,
    this.icone,
    this.corHex,
    this.totalItens = 0,
    this.totalComidas = 0,
    this.totalBebidas = 0,
    this.totalSobremesas = 0,
    this.ativo = true,
    this.somenteModelo = false,
    this.idModelo,
  });

  Cardapio copyWith({
    String? idCardapio,
    String? idEvento,
    String? titulo,
    EscopoCardapio? escopo,
    PublicoAlvoCardapio? publicoAlvo,
    String? icone,
    String? corHex,
    int? totalItens,
    int? totalComidas,
    int? totalBebidas,
    int? totalSobremesas,
    bool? ativo,
    bool? somenteModelo,
    String? idModelo,
  }) {
    return Cardapio(
      idCardapio: idCardapio ?? this.idCardapio,
      idEvento: idEvento ?? this.idEvento,
      titulo: titulo ?? this.titulo,
      escopo: escopo ?? this.escopo,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      icone: icone ?? this.icone,
      corHex: corHex ?? this.corHex,
      totalItens: totalItens ?? this.totalItens,
      totalComidas: totalComidas ?? this.totalComidas,
      totalBebidas: totalBebidas ?? this.totalBebidas,
      totalSobremesas: totalSobremesas ?? this.totalSobremesas,
      ativo: ativo ?? this.ativo,
      somenteModelo: somenteModelo ?? this.somenteModelo,
      idModelo: idModelo ?? this.idModelo,
    );
  }
}
