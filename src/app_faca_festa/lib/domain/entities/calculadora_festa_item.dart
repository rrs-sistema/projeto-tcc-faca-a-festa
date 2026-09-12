class CalculadoraFestaItem {
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
  final bool adicionadoAoCardapio;
  final bool adicionadoAoOrcamento;
  final String? idOrcamentoGerado;
  final DateTime? dataAdicionadoAoOrcamento;
  final double valorUnitarioMedio;
  final double custoEstimado;
  final double quantidadePorConvidadoEquivalente;

  const CalculadoraFestaItem({
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

  CalculadoraFestaItem copyWith({
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
    return CalculadoraFestaItem(
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
