import 'package:cloud_firestore/cloud_firestore.dart';

class InsightFornecedorModel {
  final String idInsight;
  final String idFornecedor;
  final String? idEvento;
  final String? idCotacao;

  /// Exemplo: oportunidade, proxima_acao, catalogo, reputacao,
  /// promocao, preco, pacote, resposta_cotacao.
  final String tipo;

  final String titulo;
  final String descricao;

  /// Prioridade sugerida para ordenação.
  /// Exemplo: 1 = baixa, 5 = alta.
  final int prioridade;

  /// Score opcional de 0 a 100.
  final double? score;

  /// Exemplo: baixo, medio, alto, critico.
  final String? nivel;

  final List<String> motivos;
  final List<String> acoesSugeridas;

  /// Exemplo: deterministic_rules, generative_ai, hybrid.
  final String origem;

  /// Exemplo: novo, visto, resolvido, ignorado, expirado.
  final String status;

  final String versaoRegra;

  /// Campo livre para guardar informações complementares
  /// sem alterar o contrato principal do model.
  final Map<String, dynamic>? metadados;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const InsightFornecedorModel({
    required this.idInsight,
    required this.idFornecedor,
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.prioridade,
    required this.origem,
    required this.status,
    required this.versaoRegra,
    required this.createdAt,
    this.idEvento,
    this.idCotacao,
    this.score,
    this.nivel,
    this.motivos = const [],
    this.acoesSugeridas = const [],
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });

  factory InsightFornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return InsightFornecedorModel(
      idInsight: _readString(
        map,
        ['id_insight', 'idInsight', 'id'],
        fallback: documentId ?? '',
      ),
      idFornecedor: _readString(
        map,
        ['id_fornecedor', 'idFornecedor', 'fornecedorId'],
      ),
      idEvento: _readNullableString(
        map,
        ['id_evento', 'idEvento', 'eventoId'],
      ),
      idCotacao: _readNullableString(
        map,
        ['id_cotacao', 'idCotacao', 'cotacaoId'],
      ),
      tipo: _readString(map, ['tipo'], fallback: 'geral'),
      titulo: _readString(map, ['titulo'], fallback: 'Insight'),
      descricao: _readString(map, ['descricao']),
      prioridade: _readInt(map, ['prioridade'], fallback: 1),
      score: _readNullableDouble(map, ['score']),
      nivel: _readNullableString(map, ['nivel']),
      motivos: _readStringList(map, ['motivos']),
      acoesSugeridas: _readStringList(
        map,
        ['acoes_sugeridas', 'acoesSugeridas'],
      ),
      origem: _readString(
        map,
        ['origem'],
        fallback: 'deterministic_rules',
      ),
      status: _readString(map, ['status'], fallback: 'novo'),
      versaoRegra: _readString(
        map,
        ['versao_regra', 'versaoRegra'],
        fallback: '1.0.0',
      ),
      metadados: _readNullableMap(map['metadados'] ?? map['metadata']),
      createdAt: _readDate(
        map,
        ['created_at', 'createdAt'],
        fallback: DateTime.now(),
      ),
      updatedAt: _readNullableDate(map, ['updated_at', 'updatedAt']),
      expiresAt: _readNullableDate(map, ['expires_at', 'expiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_insight': idInsight,
      'id_fornecedor': idFornecedor,
      'id_evento': idEvento,
      'id_cotacao': idCotacao,
      'tipo': tipo,
      'titulo': titulo,
      'descricao': descricao,
      'prioridade': prioridade,
      'score': score,
      'nivel': nivel,
      'motivos': motivos,
      'acoes_sugeridas': acoesSugeridas,
      'origem': origem,
      'status': status,
      'versao_regra': versaoRegra,
      'metadados': metadados,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  InsightFornecedorModel copyWith({
    String? idInsight,
    String? idFornecedor,
    String? idEvento,
    String? idCotacao,
    String? tipo,
    String? titulo,
    String? descricao,
    int? prioridade,
    double? score,
    String? nivel,
    List<String>? motivos,
    List<String>? acoesSugeridas,
    String? origem,
    String? status,
    String? versaoRegra,
    Map<String, dynamic>? metadados,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return InsightFornecedorModel(
      idInsight: idInsight ?? this.idInsight,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idEvento: idEvento ?? this.idEvento,
      idCotacao: idCotacao ?? this.idCotacao,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      prioridade: prioridade ?? this.prioridade,
      score: score ?? this.score,
      nivel: nivel ?? this.nivel,
      motivos: motivos ?? this.motivos,
      acoesSugeridas: acoesSugeridas ?? this.acoesSugeridas,
      origem: origem ?? this.origem,
      status: status ?? this.status,
      versaoRegra: versaoRegra ?? this.versaoRegra,
      metadados: metadados ?? this.metadados,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static String _readString(
    Map<String, dynamic> map,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _readString(map, keys);
    return value.isEmpty ? null : value;
  }

  static int _readInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  static double? _readNullableDouble(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static List<String> _readStringList(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value is List) {
        return value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty && item != 'null')
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    return <String>[];
  }

  static DateTime _readDate(
    Map<String, dynamic> map,
    List<String> keys, {
    required DateTime fallback,
  }) {
    return _readNullableDate(map, keys) ?? fallback;
  }

  static DateTime? _readNullableDate(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _readNullableMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }
}
