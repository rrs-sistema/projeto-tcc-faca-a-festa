import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';


class CalculadoraFestaItemModel extends CalculadoraFestaItem {
  const CalculadoraFestaItemModel({
    required super.idItemResultado,
    required super.idCalculo,
    required super.idEvento,
    required super.categoria,
    required super.nome,
    required super.tipoItem,
    required super.publicoAlvo,
    required super.quantidade,
    required super.unidade,
    required super.regraAplicada,
    super.adicionadoAoCardapio = false,
    super.adicionadoAoOrcamento = false,
    super.idOrcamentoGerado,
    super.dataAdicionadoAoOrcamento,
    super.valorUnitarioMedio = 0,
    super.custoEstimado = 0,
    super.quantidadePorConvidadoEquivalente = 0,
  });

  factory CalculadoraFestaItemModel.fromEntity(CalculadoraFestaItem entity) {
    if (entity is CalculadoraFestaItemModel) return entity;

    return CalculadoraFestaItemModel(
      idItemResultado: entity.idItemResultado,
      idCalculo: entity.idCalculo,
      idEvento: entity.idEvento,
      categoria: entity.categoria,
      nome: entity.nome,
      tipoItem: entity.tipoItem,
      publicoAlvo: entity.publicoAlvo,
      quantidade: entity.quantidade,
      unidade: entity.unidade,
      regraAplicada: entity.regraAplicada,
      adicionadoAoCardapio: entity.adicionadoAoCardapio,
      adicionadoAoOrcamento: entity.adicionadoAoOrcamento,
      idOrcamentoGerado: entity.idOrcamentoGerado,
      dataAdicionadoAoOrcamento: entity.dataAdicionadoAoOrcamento,
      valorUnitarioMedio: entity.valorUnitarioMedio,
      custoEstimado: entity.custoEstimado,
      quantidadePorConvidadoEquivalente:
          entity.quantidadePorConvidadoEquivalente,
    );
  }

  @override
  String get quantidadeFormatada {
    final valor = quantidade.ceil();
    return '$valor $unidade';
  }

  @override
  String get custoEstimadoFormatado {
    return _formatMoney(custoEstimado);
  }

  @override
  String get valorUnitarioFormatado {
    return _formatMoney(valorUnitarioMedio);
  }

  @override
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
