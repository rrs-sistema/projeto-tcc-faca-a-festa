enum TipoSugestaoCalculadoraIA {
  economia,
  alerta,
  melhoria,
  excesso,
  falta,
  planejamento,
}

enum PrioridadeSugestaoCalculadoraIA {
  baixa,
  media,
  alta,
}

extension TipoSugestaoCalculadoraIAExtension on TipoSugestaoCalculadoraIA {
  String get label {
    switch (this) {
      case TipoSugestaoCalculadoraIA.economia:
        return 'Economia';
      case TipoSugestaoCalculadoraIA.alerta:
        return 'Alerta';
      case TipoSugestaoCalculadoraIA.melhoria:
        return 'Melhoria';
      case TipoSugestaoCalculadoraIA.excesso:
        return 'Excesso';
      case TipoSugestaoCalculadoraIA.falta:
        return 'Falta';
      case TipoSugestaoCalculadoraIA.planejamento:
        return 'Planejamento';
    }
  }

  static TipoSugestaoCalculadoraIA fromString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    if (normalized == 'warning' || normalized == 'risco') {
      return TipoSugestaoCalculadoraIA.alerta;
    }

    if (normalized == 'cost' || normalized == 'custo') {
      return TipoSugestaoCalculadoraIA.economia;
    }

    if (normalized == 'improvement' || normalized == 'melhorar') {
      return TipoSugestaoCalculadoraIA.melhoria;
    }

    return TipoSugestaoCalculadoraIA.values.firstWhere(
      (item) => item.name.toLowerCase() == normalized,
      orElse: () => TipoSugestaoCalculadoraIA.planejamento,
    );
  }
}

extension PrioridadeSugestaoCalculadoraIAExtension
    on PrioridadeSugestaoCalculadoraIA {
  String get label {
    switch (this) {
      case PrioridadeSugestaoCalculadoraIA.baixa:
        return 'Baixa';
      case PrioridadeSugestaoCalculadoraIA.media:
        return 'Média';
      case PrioridadeSugestaoCalculadoraIA.alta:
        return 'Alta';
    }
  }

  static PrioridadeSugestaoCalculadoraIA fromString(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    if (normalized == 'high') return PrioridadeSugestaoCalculadoraIA.alta;
    if (normalized == 'medium') return PrioridadeSugestaoCalculadoraIA.media;
    if (normalized == 'low') return PrioridadeSugestaoCalculadoraIA.baixa;

    return PrioridadeSugestaoCalculadoraIA.values.firstWhere(
      (item) => item.name.toLowerCase() == normalized,
      orElse: () => PrioridadeSugestaoCalculadoraIA.media,
    );
  }
}

class SugestaoCalculadoraIAModel {
  final String id;
  final String titulo;
  final String descricao;
  final TipoSugestaoCalculadoraIA tipo;
  final PrioridadeSugestaoCalculadoraIA prioridade;
  final String? itemRelacionado;
  final double impactoEstimado;

  const SugestaoCalculadoraIAModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.prioridade,
    this.itemRelacionado,
    this.impactoEstimado = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'tipo': tipo.name,
      'tipo_label': tipo.label,
      'prioridade': prioridade.name,
      'prioridade_label': prioridade.label,
      'item_relacionado': itemRelacionado,
      'impacto_estimado': impactoEstimado,
    };
  }

  factory SugestaoCalculadoraIAModel.fromMap(Map<String, dynamic> map) {
    final titulo = map['titulo']?.toString() ?? '';

    return SugestaoCalculadoraIAModel(
      id: map['id']?.toString().trim().isNotEmpty == true
          ? map['id'].toString()
          : _gerarIdPorTitulo(titulo),
      titulo: titulo,
      descricao: map['descricao']?.toString() ?? '',
      tipo: TipoSugestaoCalculadoraIAExtension.fromString(
        map['tipo']?.toString(),
      ),
      prioridade: PrioridadeSugestaoCalculadoraIAExtension.fromString(
        map['prioridade']?.toString(),
      ),
      itemRelacionado: _asNullableString(
        map['item_relacionado'] ?? map['itemRelacionado'],
      ),
      impactoEstimado: _asDouble(
        map['impacto_estimado'] ?? map['impactoEstimado'],
      ),
    );
  }

  SugestaoCalculadoraIAModel copyWith({
    String? id,
    String? titulo,
    String? descricao,
    TipoSugestaoCalculadoraIA? tipo,
    PrioridadeSugestaoCalculadoraIA? prioridade,
    String? itemRelacionado,
    bool limparItemRelacionado = false,
    double? impactoEstimado,
  }) {
    return SugestaoCalculadoraIAModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      prioridade: prioridade ?? this.prioridade,
      itemRelacionado: limparItemRelacionado
          ? null
          : (itemRelacionado ?? this.itemRelacionado),
      impactoEstimado: impactoEstimado ?? this.impactoEstimado,
    );
  }

  static String? _asNullableString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static String _gerarIdPorTitulo(String titulo) {
    final normalized = titulo
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúâêîôûãõç]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return normalized.isEmpty ? 'sugestao_ia' : normalized;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}

class AnaliseCalculadoraIAModel {
  final String titulo;
  final String resumo;

  /// Índices de 0 a 100 para exibição visual.
  final double indiceEconomia;
  final double indiceRiscoFaltarItens;
  final double indiceConforto;

  final double custoTotalEstimado;
  final double? orcamentoDisponivel;
  final double diferencaOrcamento;
  final DateTime dataAnalise;
  final List<SugestaoCalculadoraIAModel> sugestoes;

  /// Campos retornados pela Cloud Function/IA generativa.
  ///
  /// Mantidos opcionais para não quebrar o layout compacto atual.
  final String fonte;
  final String versaoSchema;
  final String versaoPrompt;
  final String nomePrompt;
  final String modeloIAUtilizado;
  final List<String> idsSugestoesBaseUtilizadas;
  final Map<String, int> versoesSugestoesBaseUtilizadas;
  final int totalSugestoesBaseUtilizadas;
  final DateTime? dataProcessamento;
  final String diagnosticoFinanceiro;
  final String diagnosticoConsumo;
  final String recomendacaoFinal;
  final List<String> pontosDeAtencao;
  final List<String> proximasAcoes;

  const AnaliseCalculadoraIAModel({
    required this.titulo,
    required this.resumo,
    required this.indiceEconomia,
    required this.indiceRiscoFaltarItens,
    required this.indiceConforto,
    required this.custoTotalEstimado,
    required this.orcamentoDisponivel,
    required this.diferencaOrcamento,
    required this.dataAnalise,
    required this.sugestoes,
    this.fonte = 'local',
    this.versaoSchema = '1.0.0',
    this.versaoPrompt = 'local',
    this.nomePrompt = 'analise_calculadora_local',
    this.modeloIAUtilizado = 'local',
    this.idsSugestoesBaseUtilizadas = const [],
    this.versoesSugestoesBaseUtilizadas = const <String, int>{},
    this.totalSugestoesBaseUtilizadas = 0,
    this.dataProcessamento,
    this.diagnosticoFinanceiro = '',
    this.diagnosticoConsumo = '',
    this.recomendacaoFinal = '',
    this.pontosDeAtencao = const [],
    this.proximasAcoes = const [],
  });

  bool get possuiSugestoes => sugestoes.isNotEmpty;

  bool get possuiOrcamento =>
      orcamentoDisponivel != null && orcamentoDisponivel! > 0;

  bool get acimaDoOrcamento => possuiOrcamento && diferencaOrcamento > 0;

  bool get dentroDoOrcamento => possuiOrcamento && diferencaOrcamento <= 0;

  bool get geradaPorIAGenerativa =>
      fonte.trim().toLowerCase() == 'ia_generativa';

  bool get geradaPorFallbackLocal =>
      fonte.trim().toLowerCase() == 'fallback_local';

  bool get possuiRastreabilidadeIA {
    return versaoPrompt.trim().isNotEmpty ||
        versaoSchema.trim().isNotEmpty ||
        idsSugestoesBaseUtilizadas.isNotEmpty ||
        modeloIAUtilizado.trim().isNotEmpty;
  }

  String get fonteLabel {
    if (geradaPorIAGenerativa) return 'IA generativa';
    if (geradaPorFallbackLocal) return 'Análise local';
    return 'Análise automática';
  }

  String get resumoPrincipal {
    if (resumo.trim().isNotEmpty) return resumo;
    if (diagnosticoFinanceiro.trim().isNotEmpty) return diagnosticoFinanceiro;
    if (diagnosticoConsumo.trim().isNotEmpty) return diagnosticoConsumo;
    if (recomendacaoFinal.trim().isNotEmpty) return recomendacaoFinal;
    return statusOrcamento;
  }

  String get statusOrcamento {
    if (!possuiOrcamento) return 'Sem orçamento informado';
    return acimaDoOrcamento ? 'Acima do orçamento' : 'Dentro do orçamento';
  }

  String get rastreabilidadeResumo {
    final partes = <String>[];

    if (versaoPrompt.trim().isNotEmpty) {
      partes.add('Prompt $versaoPrompt');
    }

    if (versaoSchema.trim().isNotEmpty) {
      partes.add('Schema $versaoSchema');
    }

    if (modeloIAUtilizado.trim().isNotEmpty) {
      partes.add('Modelo $modeloIAUtilizado');
    }

    if (totalSugestoesBaseUtilizadas > 0) {
      partes.add('$totalSugestoesBaseUtilizadas sugestões base');
    }

    return partes.join(' • ');
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'resumo': resumo,
      'resumo_principal': resumoPrincipal,
      'indice_economia': indiceEconomia,
      'indice_risco_faltar_itens': indiceRiscoFaltarItens,
      'indice_conforto': indiceConforto,
      'custo_total_estimado': custoTotalEstimado,
      'orcamento_disponivel': orcamentoDisponivel,
      'diferenca_orcamento': diferencaOrcamento,
      'status_orcamento': statusOrcamento,
      'data_analise': dataAnalise.toIso8601String(),
      'sugestoes': sugestoes.map((item) => item.toMap()).toList(),
      'fonte': fonte,
      'fonte_label': fonteLabel,
      'versao_prompt': versaoPrompt,
      'nome_prompt': nomePrompt,
      'versao_schema': versaoSchema,
      'ids_sugestoes_base_utilizadas': idsSugestoesBaseUtilizadas,
      'versoes_sugestoes_base_utilizadas': versoesSugestoesBaseUtilizadas,
      'total_sugestoes_base_utilizadas': totalSugestoesBaseUtilizadas,
      'modelo_ia_utilizado': modeloIAUtilizado,
      'data_processamento': dataProcessamento?.toIso8601String(),
      'diagnostico_financeiro': diagnosticoFinanceiro,
      'diagnostico_consumo': diagnosticoConsumo,
      'recomendacao_final': recomendacaoFinal,
      'pontos_de_atencao': pontosDeAtencao,
      'proximas_acoes': proximasAcoes,
    };
  }

  factory AnaliseCalculadoraIAModel.fromMap(Map<String, dynamic> map) {
    final rawSugestoes = map['sugestoes'];
    final sugestoes = rawSugestoes is List
        ? rawSugestoes
            .whereType<Map>()
            .map(
              (item) => SugestaoCalculadoraIAModel.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <SugestaoCalculadoraIAModel>[];

    final resumo = _firstNotEmpty([
      map['resumo'],
      map['resumo_executivo'],
      map['resumoExecutivo'],
      map['summary'],
    ]);

    final idsSugestoesBaseUtilizadas = _asStringList(
      map['ids_sugestoes_base_utilizadas'] ??
          map['idsSugestoesBaseUtilizadas'] ??
          map['suggestionBaseIds'],
    );

    final versoesSugestoesBaseUtilizadas = _asStringIntMap(
      map['versoes_sugestoes_base_utilizadas'] ??
          map['versoesSugestoesBaseUtilizadas'] ??
          map['suggestionBaseVersions'],
    );

    return AnaliseCalculadoraIAModel(
      titulo: map['titulo']?.toString() ?? 'Análise inteligente',
      resumo: resumo,
      indiceEconomia: _asDouble(
        map['indice_economia'] ?? map['indiceEconomia'],
      ),
      indiceRiscoFaltarItens: _asDouble(
        map['indice_risco_faltar_itens'] ?? map['indiceRiscoFaltarItens'],
      ),
      indiceConforto: _asDouble(
        map['indice_conforto'] ?? map['indiceConforto'],
      ),
      custoTotalEstimado: _asDouble(
        map['custo_total_estimado'] ?? map['custoTotalEstimado'],
      ),
      orcamentoDisponivel: _asNullableDouble(
        map['orcamento_disponivel'] ?? map['orcamentoDisponivel'],
      ),
      diferencaOrcamento: _asDouble(
        map['diferenca_orcamento'] ?? map['diferencaOrcamento'],
      ),
      dataAnalise: _asDateTime(map['data_analise'] ?? map['dataAnalise']) ??
          DateTime.now(),
      sugestoes: sugestoes,
      fonte: map['fonte']?.toString() ?? 'local',
      versaoPrompt: _firstNotEmpty([
        map['versao_prompt'],
        map['versaoPrompt'],
        map['prompt_version'],
      ], fallback: 'local'),
      nomePrompt: _firstNotEmpty([
        map['nome_prompt'],
        map['nomePrompt'],
        map['prompt_name'],
      ], fallback: 'analise_calculadora_local'),
      versaoSchema: _firstNotEmpty([
        map['versao_schema'],
        map['versaoSchema'],
        map['schema_version'],
      ], fallback: '1.0.0'),
      modeloIAUtilizado: _firstNotEmpty([
        map['modelo_ia_utilizado'],
        map['modeloIAUtilizado'],
        map['modelo'],
        map['model'],
      ], fallback: 'local'),
      idsSugestoesBaseUtilizadas: idsSugestoesBaseUtilizadas,
      versoesSugestoesBaseUtilizadas: versoesSugestoesBaseUtilizadas,
      totalSugestoesBaseUtilizadas: _asInt(
        map['total_sugestoes_base_utilizadas'] ??
            map['totalSugestoesBaseUtilizadas'],
        fallback: idsSugestoesBaseUtilizadas.length,
      ),
      dataProcessamento: _asDateTime(
        map['data_processamento'] ?? map['dataProcessamento'],
      ),
      diagnosticoFinanceiro: _firstNotEmpty([
        map['diagnostico_financeiro'],
        map['diagnosticoFinanceiro'],
      ]),
      diagnosticoConsumo: _firstNotEmpty([
        map['diagnostico_consumo'],
        map['diagnosticoConsumo'],
      ]),
      recomendacaoFinal: _firstNotEmpty([
        map['recomendacao_final'],
        map['recomendacaoFinal'],
      ]),
      pontosDeAtencao: _asStringList(
        map['pontos_de_atencao'] ?? map['pontosDeAtencao'],
      ),
      proximasAcoes: _asStringList(
        map['proximas_acoes'] ?? map['proximasAcoes'],
      ),
    );
  }

  AnaliseCalculadoraIAModel copyWith({
    String? titulo,
    String? resumo,
    double? indiceEconomia,
    double? indiceRiscoFaltarItens,
    double? indiceConforto,
    double? custoTotalEstimado,
    double? orcamentoDisponivel,
    bool limparOrcamentoDisponivel = false,
    double? diferencaOrcamento,
    DateTime? dataAnalise,
    List<SugestaoCalculadoraIAModel>? sugestoes,
    String? fonte,
    String? versaoSchema,
    String? versaoPrompt,
    String? nomePrompt,
    String? modeloIAUtilizado,
    List<String>? idsSugestoesBaseUtilizadas,
    Map<String, int>? versoesSugestoesBaseUtilizadas,
    int? totalSugestoesBaseUtilizadas,
    DateTime? dataProcessamento,
    bool limparDataProcessamento = false,
    String? diagnosticoFinanceiro,
    String? diagnosticoConsumo,
    String? recomendacaoFinal,
    List<String>? pontosDeAtencao,
    List<String>? proximasAcoes,
  }) {
    return AnaliseCalculadoraIAModel(
      titulo: titulo ?? this.titulo,
      resumo: resumo ?? this.resumo,
      indiceEconomia: indiceEconomia ?? this.indiceEconomia,
      indiceRiscoFaltarItens:
          indiceRiscoFaltarItens ?? this.indiceRiscoFaltarItens,
      indiceConforto: indiceConforto ?? this.indiceConforto,
      custoTotalEstimado: custoTotalEstimado ?? this.custoTotalEstimado,
      orcamentoDisponivel: limparOrcamentoDisponivel
          ? null
          : (orcamentoDisponivel ?? this.orcamentoDisponivel),
      diferencaOrcamento: diferencaOrcamento ?? this.diferencaOrcamento,
      dataAnalise: dataAnalise ?? this.dataAnalise,
      sugestoes: sugestoes ?? this.sugestoes,
      fonte: fonte ?? this.fonte,
      versaoSchema: versaoSchema ?? this.versaoSchema,
      versaoPrompt: versaoPrompt ?? this.versaoPrompt,
      nomePrompt: nomePrompt ?? this.nomePrompt,
      modeloIAUtilizado: modeloIAUtilizado ?? this.modeloIAUtilizado,
      idsSugestoesBaseUtilizadas:
          idsSugestoesBaseUtilizadas ?? this.idsSugestoesBaseUtilizadas,
      versoesSugestoesBaseUtilizadas:
          versoesSugestoesBaseUtilizadas ?? this.versoesSugestoesBaseUtilizadas,
      totalSugestoesBaseUtilizadas:
          totalSugestoesBaseUtilizadas ?? this.totalSugestoesBaseUtilizadas,
      dataProcessamento: limparDataProcessamento
          ? null
          : (dataProcessamento ?? this.dataProcessamento),
      diagnosticoFinanceiro:
          diagnosticoFinanceiro ?? this.diagnosticoFinanceiro,
      diagnosticoConsumo: diagnosticoConsumo ?? this.diagnosticoConsumo,
      recomendacaoFinal: recomendacaoFinal ?? this.recomendacaoFinal,
      pontosDeAtencao: pontosDeAtencao ?? this.pontosDeAtencao,
      proximasAcoes: proximasAcoes ?? this.proximasAcoes,
    );
  }

  static String _firstNotEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty && item != 'null')
          .toSet()
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && item != 'null')
          .toSet()
          .toList();
    }

    return const [];
  }

  static Map<String, int> _asStringIntMap(dynamic value) {
    if (value == null) return const <String, int>{};

    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(
          key.toString(),
          _asInt(mapValue, fallback: 1),
        ),
      );
    }

    if (value is List) {
      final result = <String, int>{};

      for (final item in value) {
        if (item is Map) {
          final id = item['id']?.toString().trim();
          if (id == null || id.isEmpty) continue;

          result[id] = _asInt(
            item['versao'] ?? item['version'],
            fallback: 1,
          );
        }
      }

      return result;
    }

    return const <String, int>{};
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final dynamic dynamicValue = value;
      final converted = dynamicValue.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Ignora e tenta parsear como texto.
    }

    return DateTime.tryParse(value.toString());
  }
}
