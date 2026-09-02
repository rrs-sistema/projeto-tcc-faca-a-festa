class CalculadoraFestaItemModel {
  final String idItemResultado;
  final String idCalculo;
  final String idEvento;
  final String categoria;
  final String nome;
  final String tipoItem;
  final String publicoAlvo;
  final double quantidade;
  final String unidade;
  final String regraAplicada;

  /// Mantido por compatibilidade com o fluxo atual de cardápio.
  final bool adicionadoAoCardapio;

  /// Controle para evitar duplicidade quando a simulação virar orçamento.
  final bool adicionadoAoOrcamento;
  final String? idOrcamentoGerado;
  final DateTime? dataAdicionadoAoOrcamento;

  /// Campos da estimativa financeira.
  final double valorUnitarioMedio;
  final double custoEstimado;
  final double quantidadePorConvidadoEquivalente;

  const CalculadoraFestaItemModel({
    required this.idItemResultado,
    required this.idCalculo,
    required this.idEvento,
    required this.categoria,
    required this.nome,
    required this.tipoItem,
    required this.publicoAlvo,
    required this.quantidade,
    required this.unidade,
    required this.regraAplicada,
    this.adicionadoAoCardapio = false,
    this.adicionadoAoOrcamento = false,
    this.idOrcamentoGerado,
    this.dataAdicionadoAoOrcamento,
    this.valorUnitarioMedio = 0,
    this.custoEstimado = 0,
    this.quantidadePorConvidadoEquivalente = 0,
  });

  bool get podeAdicionarAoOrcamento => !adicionadoAoOrcamento;

  String get quantidadeFormatada {
    final valor = quantidade.ceil();
    return '$valor $unidade';
  }

  String get custoEstimadoFormatado {
    return _formatMoney(custoEstimado);
  }

  String get valorUnitarioFormatado {
    return _formatMoney(valorUnitarioMedio);
  }

  CalculadoraFestaItemModel copyWith({
    String? idItemResultado,
    String? idCalculo,
    String? idEvento,
    String? categoria,
    String? nome,
    String? tipoItem,
    String? publicoAlvo,
    double? quantidade,
    String? unidade,
    String? regraAplicada,
    bool? adicionadoAoCardapio,
    bool? adicionadoAoOrcamento,
    String? idOrcamentoGerado,
    bool limparIdOrcamentoGerado = false,
    DateTime? dataAdicionadoAoOrcamento,
    bool limparDataAdicionadoAoOrcamento = false,
    double? valorUnitarioMedio,
    double? custoEstimado,
    double? quantidadePorConvidadoEquivalente,
  }) {
    return CalculadoraFestaItemModel(
      idItemResultado: idItemResultado ?? this.idItemResultado,
      idCalculo: idCalculo ?? this.idCalculo,
      idEvento: idEvento ?? this.idEvento,
      categoria: categoria ?? this.categoria,
      nome: nome ?? this.nome,
      tipoItem: tipoItem ?? this.tipoItem,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      quantidade: quantidade ?? this.quantidade,
      unidade: unidade ?? this.unidade,
      regraAplicada: regraAplicada ?? this.regraAplicada,
      adicionadoAoCardapio: adicionadoAoCardapio ?? this.adicionadoAoCardapio,
      adicionadoAoOrcamento:
          adicionadoAoOrcamento ?? this.adicionadoAoOrcamento,
      idOrcamentoGerado: limparIdOrcamentoGerado
          ? null
          : idOrcamentoGerado ?? this.idOrcamentoGerado,
      dataAdicionadoAoOrcamento: limparDataAdicionadoAoOrcamento
          ? null
          : dataAdicionadoAoOrcamento ?? this.dataAdicionadoAoOrcamento,
      valorUnitarioMedio: valorUnitarioMedio ?? this.valorUnitarioMedio,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      quantidadePorConvidadoEquivalente: quantidadePorConvidadoEquivalente ??
          this.quantidadePorConvidadoEquivalente,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_item_resultado': idItemResultado,
      'id_calculo': idCalculo,
      'id_evento': idEvento,
      'categoria': categoria,
      'nome': nome,
      'tipo_item': tipoItem,
      'publico_alvo': publicoAlvo,
      'quantidade': quantidade,
      'unidade': unidade,
      'regra_aplicada': regraAplicada,
      'adicionado_ao_cardapio': adicionadoAoCardapio,
      'adicionado_ao_orcamento': adicionadoAoOrcamento,
      'id_orcamento_gerado': idOrcamentoGerado,
      'data_adicionado_ao_orcamento':
          dataAdicionadoAoOrcamento?.toIso8601String(),
      'valor_unitario_medio': valorUnitarioMedio,
      'custo_estimado': custoEstimado,
      'quantidade_por_convidado_equivalente': quantidadePorConvidadoEquivalente,
    };
  }

  factory CalculadoraFestaItemModel.fromMap(Map<String, dynamic> map) {
    return CalculadoraFestaItemModel(
      idItemResultado: map['id_item_resultado']?.toString() ?? '',
      idCalculo: map['id_calculo']?.toString() ?? '',
      idEvento: map['id_evento']?.toString() ?? '',
      categoria: map['categoria']?.toString() ?? 'Recepção',
      nome: map['nome']?.toString() ?? '',
      tipoItem: map['tipo_item']?.toString() ?? 'comida',
      publicoAlvo: map['publico_alvo']?.toString() ?? 'todos',
      quantidade: _asDouble(map['quantidade']),
      unidade: map['unidade']?.toString() ?? 'un',
      regraAplicada: map['regra_aplicada']?.toString() ?? '',
      adicionadoAoCardapio: _asBool(map['adicionado_ao_cardapio']),
      adicionadoAoOrcamento: _asBool(map['adicionado_ao_orcamento']),
      idOrcamentoGerado: _nullableString(map['id_orcamento_gerado']),
      dataAdicionadoAoOrcamento: _asDate(map['data_adicionado_ao_orcamento']),
      valorUnitarioMedio: _asDouble(map['valor_unitario_medio']),
      custoEstimado: _asDouble(map['custo_estimado']),
      quantidadePorConvidadoEquivalente: _asDouble(
        map['quantidade_por_convidado_equivalente'],
      ),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase();

    if (normalized == 'true' || normalized == '1' || normalized == 'sim') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'nao' ||
        normalized == 'não') {
      return false;
    }

    return fallback;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    // Compatibilidade com Timestamp do Firestore sem acoplar o model ao pacote cloud_firestore.
    try {
      final dynamic dynamicValue = value;
      final converted = dynamicValue.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Ignora e tenta parsear como texto.
    }

    return DateTime.tryParse(value.toString());
  }

  static String _formatMoney(double value) {
    final normalized = value.toStringAsFixed(2).replaceAll('.', ',');
    final parts = normalized.split(',');
    final integer = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'R\$ $integer,${parts.last}';
  }
}
