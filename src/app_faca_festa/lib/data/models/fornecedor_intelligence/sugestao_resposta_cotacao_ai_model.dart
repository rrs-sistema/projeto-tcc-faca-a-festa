import 'dart:convert';

class SugestaoRespostaCotacaoAiModel {
  final String respostaSugerida;
  final String versaoCurta;
  final List<String> pontosParaRevisar;
  final List<String> perguntasFaltantes;
  final List<String> dadosUtilizados;
  final List<String> alertas;

  /// Valores aceitos:
  /// - alto
  /// - medio
  /// - baixo
  ///
  /// Qualquer valor inválido será convertido para "baixo".
  final String nivelConfianca;

  final String motivoNivelConfianca;

  const SugestaoRespostaCotacaoAiModel({
    required this.respostaSugerida,
    required this.versaoCurta,
    required this.pontosParaRevisar,
    required this.perguntasFaltantes,
    required this.dadosUtilizados,
    required this.alertas,
    required this.nivelConfianca,
    required this.motivoNivelConfianca,
  });

  factory SugestaoRespostaCotacaoAiModel.empty() {
    return const SugestaoRespostaCotacaoAiModel(
      respostaSugerida: '',
      versaoCurta: '',
      pontosParaRevisar: [],
      perguntasFaltantes: [],
      dadosUtilizados: [],
      alertas: [],
      nivelConfianca: 'baixo',
      motivoNivelConfianca: '',
    );
  }

  factory SugestaoRespostaCotacaoAiModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return SugestaoRespostaCotacaoAiModel.empty();
    }

    return SugestaoRespostaCotacaoAiModel(
      respostaSugerida: _readString(
        map,
        ['resposta_sugerida', 'respostaSugerida'],
      ),
      versaoCurta: _readString(
        map,
        ['versao_curta', 'versaoCurta'],
      ),
      pontosParaRevisar: _readStringList(
        map,
        ['pontos_para_revisar', 'pontosParaRevisar'],
      ),
      perguntasFaltantes: _readStringList(
        map,
        ['perguntas_faltantes', 'perguntasFaltantes'],
      ),
      dadosUtilizados: _readStringList(
        map,
        ['dados_utilizados', 'dadosUtilizados'],
      ),
      alertas: _readStringList(
        map,
        ['alertas'],
      ),
      nivelConfianca: _validarNivelConfianca(
        _readString(
          map,
          ['nivel_confianca', 'nivelConfianca'],
        ),
      ),
      motivoNivelConfianca: _readString(
        map,
        ['motivo_nivel_confianca', 'motivoNivelConfianca'],
      ),
    );
  }

  factory SugestaoRespostaCotacaoAiModel.fromJsonString(String json) {
    if (json.trim().isEmpty) {
      return SugestaoRespostaCotacaoAiModel.empty();
    }

    try {
      final sanitized = _sanitizeJsonString(json);
      final decoded = jsonDecode(sanitized);

      if (decoded is Map<String, dynamic>) {
        return SugestaoRespostaCotacaoAiModel.fromMap(decoded);
      }

      if (decoded is Map) {
        return SugestaoRespostaCotacaoAiModel.fromMap(
          Map<String, dynamic>.from(decoded),
        );
      }

      return SugestaoRespostaCotacaoAiModel.empty();
    } catch (_) {
      return SugestaoRespostaCotacaoAiModel.empty();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'resposta_sugerida': respostaSugerida,
      'versao_curta': versaoCurta,
      'pontos_para_revisar': pontosParaRevisar,
      'perguntas_faltantes': perguntasFaltantes,
      'dados_utilizados': dadosUtilizados,
      'alertas': alertas,
      'nivel_confianca': _validarNivelConfianca(nivelConfianca),
      'motivo_nivel_confianca': motivoNivelConfianca,
    };
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  SugestaoRespostaCotacaoAiModel copyWith({
    String? respostaSugerida,
    String? versaoCurta,
    List<String>? pontosParaRevisar,
    List<String>? perguntasFaltantes,
    List<String>? dadosUtilizados,
    List<String>? alertas,
    String? nivelConfianca,
    String? motivoNivelConfianca,
  }) {
    return SugestaoRespostaCotacaoAiModel(
      respostaSugerida: respostaSugerida ?? this.respostaSugerida,
      versaoCurta: versaoCurta ?? this.versaoCurta,
      pontosParaRevisar: pontosParaRevisar ?? this.pontosParaRevisar,
      perguntasFaltantes: perguntasFaltantes ?? this.perguntasFaltantes,
      dadosUtilizados: dadosUtilizados ?? this.dadosUtilizados,
      alertas: alertas ?? this.alertas,
      nivelConfianca: _validarNivelConfianca(
        nivelConfianca ?? this.nivelConfianca,
      ),
      motivoNivelConfianca: motivoNivelConfianca ?? this.motivoNivelConfianca,
    );
  }

  static String _readString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;

      final value = map[key];

      if (value == null) {
        return '';
      }

      if (value is String) {
        return value.trim();
      }

      if (value is num || value is bool) {
        return value.toString().trim();
      }

      try {
        return jsonEncode(value).trim();
      } catch (_) {
        return value.toString().trim();
      }
    }

    return '';
  }

  static List<String> _readStringList(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (!map.containsKey(key)) continue;

      final value = map[key];

      if (value == null) {
        return <String>[];
      }

      if (value is List) {
        return value
            .map(_dynamicToString)
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty && item != 'null')
            .toList();
      }

      if (value is String) {
        final text = value.trim();

        if (text.isEmpty) {
          return <String>[];
        }

        final decodedList = _tryDecodeStringList(text);

        if (decodedList != null) {
          return decodedList;
        }

        return text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
      }

      return <String>[_dynamicToString(value)]
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && item != 'null')
          .toList();
    }

    return <String>[];
  }

  static List<String>? _tryDecodeStringList(String value) {
    final text = value.trim();

    if (!text.startsWith('[') || !text.endsWith(']')) {
      return null;
    }

    try {
      final decoded = jsonDecode(text);

      if (decoded is! List) {
        return null;
      }

      return decoded
          .map(_dynamicToString)
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && item != 'null')
          .toList();
    } catch (_) {
      return null;
    }
  }

  static String _dynamicToString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value;
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  static String _validarNivelConfianca(String value) {
    final normalized = _normalize(value);

    if (normalized == 'alto') {
      return 'alto';
    }

    if (normalized == 'medio') {
      return 'medio';
    }

    if (normalized == 'baixo') {
      return 'baixo';
    }

    return 'baixo';
  }

  static String _normalize(String value) {
    var text = value.trim().toLowerCase();

    const replacements = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    replacements.forEach((from, to) {
      text = text.replaceAll(from, to);
    });

    return text;
  }

  static String _sanitizeJsonString(String raw) {
    var text = raw.trim();

    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```json\s*', caseSensitive: false), '');
      text = text.replaceFirst(RegExp(r'^```\s*'), '');

      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }
    }

    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');

    if (firstBrace >= 0 && lastBrace > firstBrace) {
      text = text.substring(firstBrace, lastBrace + 1).trim();
    }

    return text;
  }

  @override
  String toString() {
    return 'SugestaoRespostaCotacaoAiModel('
        'respostaSugerida: $respostaSugerida, '
        'versaoCurta: $versaoCurta, '
        'pontosParaRevisar: $pontosParaRevisar, '
        'perguntasFaltantes: $perguntasFaltantes, '
        'dadosUtilizados: $dadosUtilizados, '
        'alertas: $alertas, '
        'nivelConfianca: $nivelConfianca, '
        'motivoNivelConfianca: $motivoNivelConfianca'
        ')';
  }
}
