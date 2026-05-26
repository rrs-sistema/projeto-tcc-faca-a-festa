class CalculadoraFestaItemModel {
  final String idItemResultado;
  final String idCalculo;
  final String idEvento;
  final String nome;
  final String tipoItem;
  final String publicoAlvo;
  final double quantidade;
  final String unidade;
  final String regraAplicada;
  final bool adicionadoAoCardapio;

  const CalculadoraFestaItemModel({
    required this.idItemResultado,
    required this.idCalculo,
    required this.idEvento,
    required this.nome,
    required this.tipoItem,
    this.publicoAlvo = 'todos',
    required this.quantidade,
    required this.unidade,
    required this.regraAplicada,
    this.adicionadoAoCardapio = false,
  });

  String get quantidadeFormatada {
    if (quantidade % 1 == 0) return '${quantidade.toInt()} $unidade';
    return '${quantidade.toStringAsFixed(1)} $unidade';
  }

  Map<String, dynamic> toMap() {
    return {
      'id_item_resultado': idItemResultado,
      'id_calculo': idCalculo,
      'id_evento': idEvento,
      'nome': nome,
      'tipo_item': tipoItem,
      'publico_alvo': publicoAlvo,
      'quantidade': quantidade,
      'unidade': unidade,
      'regra_aplicada': regraAplicada,
      'adicionado_ao_cardapio': adicionadoAoCardapio,
    };
  }

  factory CalculadoraFestaItemModel.fromMap(Map<String, dynamic> map) {
    return CalculadoraFestaItemModel(
      idItemResultado: map['id_item_resultado']?.toString() ?? '',
      idCalculo: map['id_calculo']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      tipoItem: map['tipo_item']?.toString() ?? 'outro',
      publicoAlvo: map['publico_alvo']?.toString() ?? 'todos',
      quantidade: map['quantidade'] is num ? (map['quantidade'] as num).toDouble() : 0,
      unidade: map['unidade']?.toString() ?? 'un',
      regraAplicada: map['regra_aplicada']?.toString() ?? '',
      adicionadoAoCardapio: map['adicionado_ao_cardapio'] ?? false,
    );
  }

  CalculadoraFestaItemModel copyWith({
    double? quantidade,
    String? unidade,
    bool? adicionadoAoCardapio,
  }) {
    return CalculadoraFestaItemModel(
      idItemResultado: idItemResultado,
      idCalculo: idCalculo,
      idEvento: idEvento,
      nome: nome,
      tipoItem: tipoItem,
      publicoAlvo: publicoAlvo,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      regraAplicada: regraAplicada,
      adicionadoAoCardapio: adicionadoAoCardapio ?? this.adicionadoAoCardapio,
    );
  }
}
