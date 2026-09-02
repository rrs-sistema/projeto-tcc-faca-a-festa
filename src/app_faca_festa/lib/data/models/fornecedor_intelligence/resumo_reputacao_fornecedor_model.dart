import 'package:cloud_firestore/cloud_firestore.dart';

class ResumoReputacaoFornecedorModel {
  final String idResumo;
  final String idFornecedor;

  final double mediaGeral;
  final int totalAvaliacoes;

  final double percentualPositivas;
  final double percentualNeutras;
  final double percentualNegativas;

  final double? mediaUltimos90Dias;

  /// Exemplo: subindo, estavel, caindo, insuficiente.
  final String tendencia;

  final String resumo;

  final List<String> pontosFortes;
  final List<String> pontosAtencao;

  final String? servicoMelhorAvaliado;
  final String? servicoComAlerta;

  final int totalComentariosAnalisados;

  /// Exemplo: deterministic_rules, generative_ai, hybrid.
  final String origem;

  final String versaoRegra;

  final Map<String, dynamic>? metadados;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const ResumoReputacaoFornecedorModel({
    required this.idResumo,
    required this.idFornecedor,
    required this.mediaGeral,
    required this.totalAvaliacoes,
    required this.percentualPositivas,
    required this.percentualNeutras,
    required this.percentualNegativas,
    required this.tendencia,
    required this.resumo,
    required this.totalComentariosAnalisados,
    required this.origem,
    required this.versaoRegra,
    required this.createdAt,
    this.mediaUltimos90Dias,
    this.pontosFortes = const [],
    this.pontosAtencao = const [],
    this.servicoMelhorAvaliado,
    this.servicoComAlerta,
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });

  factory ResumoReputacaoFornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return ResumoReputacaoFornecedorModel(
      idResumo: _readString(
        map,
        ['id_resumo', 'idResumo', 'id'],
        fallback: documentId ?? '',
      ),
      idFornecedor: _readString(
        map,
        ['id_fornecedor', 'idFornecedor', 'fornecedorId'],
      ),
      mediaGeral: _readDouble(
        map,
        ['media_geral', 'mediaGeral', 'media_avaliacoes', 'mediaAvaliacoes'],
      ),
      totalAvaliacoes: _readInt(
        map,
        ['total_avaliacoes', 'totalAvaliacoes'],
      ),
      percentualPositivas: _readDouble(
        map,
        ['percentual_positivas', 'percentualPositivas'],
      ),
      percentualNeutras: _readDouble(
        map,
        ['percentual_neutras', 'percentualNeutras'],
      ),
      percentualNegativas: _readDouble(
        map,
        ['percentual_negativas', 'percentualNegativas'],
      ),
      mediaUltimos90Dias: _readNullableDouble(
        map,
        ['media_ultimos_90_dias', 'mediaUltimos90Dias'],
      ),
      tendencia: _readString(
        map,
        ['tendencia'],
        fallback: 'insuficiente',
      ),
      resumo: _readString(map, ['resumo']),
      pontosFortes: _readStringList(
        map,
        ['pontos_fortes', 'pontosFortes'],
      ),
      pontosAtencao: _readStringList(
        map,
        ['pontos_atencao', 'pontosAtencao'],
      ),
      servicoMelhorAvaliado: _readNullableString(
        map,
        ['servico_melhor_avaliado', 'servicoMelhorAvaliado'],
      ),
      servicoComAlerta: _readNullableString(
        map,
        ['servico_com_alerta', 'servicoComAlerta'],
      ),
      totalComentariosAnalisados: _readInt(
        map,
        [
          'total_comentarios_analisados',
          'totalComentariosAnalisados',
        ],
      ),
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
      'id_resumo': idResumo,
      'id_fornecedor': idFornecedor,
      'media_geral': mediaGeral,
      'total_avaliacoes': totalAvaliacoes,
      'percentual_positivas': percentualPositivas,
      'percentual_neutras': percentualNeutras,
      'percentual_negativas': percentualNegativas,
      'media_ultimos_90_dias': mediaUltimos90Dias,
      'tendencia': tendencia,
      'resumo': resumo,
      'pontos_fortes': pontosFortes,
      'pontos_atencao': pontosAtencao,
      'servico_melhor_avaliado': servicoMelhorAvaliado,
      'servico_com_alerta': servicoComAlerta,
      'total_comentarios_analisados': totalComentariosAnalisados,
      'origem': origem,
      'versao_regra': versaoRegra,
      'metadados': metadados,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  ResumoReputacaoFornecedorModel copyWith({
    String? idResumo,
    String? idFornecedor,
    double? mediaGeral,
    int? totalAvaliacoes,
    double? percentualPositivas,
    double? percentualNeutras,
    double? percentualNegativas,
    double? mediaUltimos90Dias,
    String? tendencia,
    String? resumo,
    List<String>? pontosFortes,
    List<String>? pontosAtencao,
    String? servicoMelhorAvaliado,
    String? servicoComAlerta,
    int? totalComentariosAnalisados,
    String? origem,
    String? versaoRegra,
    Map<String, dynamic>? metadados,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return ResumoReputacaoFornecedorModel(
      idResumo: idResumo ?? this.idResumo,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      mediaGeral: mediaGeral ?? this.mediaGeral,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      percentualPositivas: percentualPositivas ?? this.percentualPositivas,
      percentualNeutras: percentualNeutras ?? this.percentualNeutras,
      percentualNegativas: percentualNegativas ?? this.percentualNegativas,
      mediaUltimos90Dias: mediaUltimos90Dias ?? this.mediaUltimos90Dias,
      tendencia: tendencia ?? this.tendencia,
      resumo: resumo ?? this.resumo,
      pontosFortes: pontosFortes ?? this.pontosFortes,
      pontosAtencao: pontosAtencao ?? this.pontosAtencao,
      servicoMelhorAvaliado:
          servicoMelhorAvaliado ?? this.servicoMelhorAvaliado,
      servicoComAlerta: servicoComAlerta ?? this.servicoComAlerta,
      totalComentariosAnalisados:
          totalComentariosAnalisados ?? this.totalComentariosAnalisados,
      origem: origem ?? this.origem,
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

  static double _readDouble(
    Map<String, dynamic> map,
    List<String> keys, {
    double fallback = 0.0,
  }) {
    return _readNullableDouble(map, keys) ?? fallback;
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
