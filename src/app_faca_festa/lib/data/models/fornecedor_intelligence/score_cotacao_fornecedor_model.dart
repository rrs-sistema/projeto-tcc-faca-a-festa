import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreCotacaoFornecedorModel {
  final String idScore;
  final String idCotacao;
  final String idFornecedor;
  final String idEvento;

  /// Score final de 0 a 100.
  final double score;

  /// Exemplo: baixo, medio, alto.
  final String nivel;

  final double compatibilidadeTipoEvento;
  final double compatibilidadeCategoria;
  final double compatibilidadeOrcamento;
  final double compatibilidadeLocalizacao;
  final double scoreUrgencia;
  final double scoreInteracao;
  final double scoreReputacao;

  final List<String> motivosPositivos;
  final List<String> alertas;
  final List<String> penalidades;

  /// Exemplo: deterministic_rules, generative_ai, hybrid.
  final String origem;

  final String versaoRegra;

  final Map<String, dynamic>? metadados;

  final DateTime calculadoEm;
  final DateTime? expiresAt;

  const ScoreCotacaoFornecedorModel({
    required this.idScore,
    required this.idCotacao,
    required this.idFornecedor,
    required this.idEvento,
    required this.score,
    required this.nivel,
    required this.compatibilidadeTipoEvento,
    required this.compatibilidadeCategoria,
    required this.compatibilidadeOrcamento,
    required this.compatibilidadeLocalizacao,
    required this.scoreUrgencia,
    required this.scoreInteracao,
    required this.scoreReputacao,
    required this.origem,
    required this.versaoRegra,
    required this.calculadoEm,
    this.motivosPositivos = const [],
    this.alertas = const [],
    this.penalidades = const [],
    this.metadados,
    this.expiresAt,
  });

  factory ScoreCotacaoFornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return ScoreCotacaoFornecedorModel(
      idScore: _readString(
        map,
        ['id_score', 'idScore', 'id'],
        fallback: documentId ?? '',
      ),
      idCotacao: _readString(
        map,
        ['id_cotacao', 'idCotacao', 'cotacaoId'],
      ),
      idFornecedor: _readString(
        map,
        ['id_fornecedor', 'idFornecedor', 'fornecedorId'],
      ),
      idEvento: _readString(
        map,
        ['id_evento', 'idEvento', 'eventoId'],
      ),
      score: _readDouble(map, ['score']),
      nivel: _readString(map, ['nivel'], fallback: 'baixo'),
      compatibilidadeTipoEvento: _readDouble(
        map,
        ['compatibilidade_tipo_evento', 'compatibilidadeTipoEvento'],
      ),
      compatibilidadeCategoria: _readDouble(
        map,
        ['compatibilidade_categoria', 'compatibilidadeCategoria'],
      ),
      compatibilidadeOrcamento: _readDouble(
        map,
        ['compatibilidade_orcamento', 'compatibilidadeOrcamento'],
      ),
      compatibilidadeLocalizacao: _readDouble(
        map,
        ['compatibilidade_localizacao', 'compatibilidadeLocalizacao'],
      ),
      scoreUrgencia: _readDouble(
        map,
        ['score_urgencia', 'scoreUrgencia'],
      ),
      scoreInteracao: _readDouble(
        map,
        ['score_interacao', 'scoreInteracao'],
      ),
      scoreReputacao: _readDouble(
        map,
        ['score_reputacao', 'scoreReputacao'],
      ),
      motivosPositivos: _readStringList(
        map,
        ['motivos_positivos', 'motivosPositivos'],
      ),
      alertas: _readStringList(map, ['alertas']),
      penalidades: _readStringList(map, ['penalidades']),
      origem: _readString(
        map,
        ['origem'],
        fallback: 'deterministic_rules',
      ),
      versaoRegra: _readString(
        map,
        ['versao_regra', 'versaoRegra'],
        fallback: '1.0.0',
      ),
      metadados: _readNullableMap(map['metadados'] ?? map['metadata']),
      calculadoEm: _readDate(
        map,
        ['calculado_em', 'calculadoEm'],
        fallback: DateTime.now(),
      ),
      expiresAt: _readNullableDate(map, ['expires_at', 'expiresAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_score': idScore,
      'id_cotacao': idCotacao,
      'id_fornecedor': idFornecedor,
      'id_evento': idEvento,
      'score': score,
      'nivel': nivel,
      'compatibilidade_tipo_evento': compatibilidadeTipoEvento,
      'compatibilidade_categoria': compatibilidadeCategoria,
      'compatibilidade_orcamento': compatibilidadeOrcamento,
      'compatibilidade_localizacao': compatibilidadeLocalizacao,
      'score_urgencia': scoreUrgencia,
      'score_interacao': scoreInteracao,
      'score_reputacao': scoreReputacao,
      'motivos_positivos': motivosPositivos,
      'alertas': alertas,
      'penalidades': penalidades,
      'origem': origem,
      'versao_regra': versaoRegra,
      'metadados': metadados,
      'calculado_em': Timestamp.fromDate(calculadoEm),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  ScoreCotacaoFornecedorModel copyWith({
    String? idScore,
    String? idCotacao,
    String? idFornecedor,
    String? idEvento,
    double? score,
    String? nivel,
    double? compatibilidadeTipoEvento,
    double? compatibilidadeCategoria,
    double? compatibilidadeOrcamento,
    double? compatibilidadeLocalizacao,
    double? scoreUrgencia,
    double? scoreInteracao,
    double? scoreReputacao,
    List<String>? motivosPositivos,
    List<String>? alertas,
    List<String>? penalidades,
    String? origem,
    String? versaoRegra,
    Map<String, dynamic>? metadados,
    DateTime? calculadoEm,
    DateTime? expiresAt,
  }) {
    return ScoreCotacaoFornecedorModel(
      idScore: idScore ?? this.idScore,
      idCotacao: idCotacao ?? this.idCotacao,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idEvento: idEvento ?? this.idEvento,
      score: score ?? this.score,
      nivel: nivel ?? this.nivel,
      compatibilidadeTipoEvento:
          compatibilidadeTipoEvento ?? this.compatibilidadeTipoEvento,
      compatibilidadeCategoria:
          compatibilidadeCategoria ?? this.compatibilidadeCategoria,
      compatibilidadeOrcamento:
          compatibilidadeOrcamento ?? this.compatibilidadeOrcamento,
      compatibilidadeLocalizacao:
          compatibilidadeLocalizacao ?? this.compatibilidadeLocalizacao,
      scoreUrgencia: scoreUrgencia ?? this.scoreUrgencia,
      scoreInteracao: scoreInteracao ?? this.scoreInteracao,
      scoreReputacao: scoreReputacao ?? this.scoreReputacao,
      motivosPositivos: motivosPositivos ?? this.motivosPositivos,
      alertas: alertas ?? this.alertas,
      penalidades: penalidades ?? this.penalidades,
      origem: origem ?? this.origem,
      versaoRegra: versaoRegra ?? this.versaoRegra,
      metadados: metadados ?? this.metadados,
      calculadoEm: calculadoEm ?? this.calculadoEm,
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

  static double _readDouble(
    Map<String, dynamic> map,
    List<String> keys, {
    double fallback = 0.0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
        if (parsed != null) return parsed;
      }
    }
    return fallback;
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
