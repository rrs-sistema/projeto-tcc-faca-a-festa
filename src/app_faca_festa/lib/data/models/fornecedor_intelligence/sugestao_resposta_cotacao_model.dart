import 'package:cloud_firestore/cloud_firestore.dart';

class SugestaoRespostaCotacaoModel {
  final String idSugestao;
  final String idCotacao;
  final String idFornecedor;
  final String? idEvento;

  final String titulo;

  /// Mensagem pronta para o fornecedor revisar/copiar/enviar.
  final String mensagem;

  /// Exemplo: profissional, cordial, urgente, premium, economico.
  final String tom;

  /// Chave do template usado.
  /// Exemplo: cotacao_nova, evento_urgente, pacote_economico.
  final String templateKey;

  final List<String> camposUsados;
  final List<String> camposAusentes;

  /// Indica se a sugestão precisa de revisão antes do envio.
  final bool precisaRevisao;

  /// Exemplo: deterministic_rules, generative_ai, hybrid.
  final String origem;

  final String versaoRegra;

  /// Exemplo: nova, usada, editada, enviada, ignorada.
  final String status;

  final Map<String, dynamic>? metadados;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const SugestaoRespostaCotacaoModel({
    required this.idSugestao,
    required this.idCotacao,
    required this.idFornecedor,
    required this.titulo,
    required this.mensagem,
    required this.tom,
    required this.templateKey,
    required this.precisaRevisao,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.idEvento,
    this.camposUsados = const [],
    this.camposAusentes = const [],
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });

  factory SugestaoRespostaCotacaoModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return SugestaoRespostaCotacaoModel(
      idSugestao: _readString(
        map,
        ['id_sugestao', 'idSugestao', 'id'],
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
      idEvento: _readNullableString(
        map,
        ['id_evento', 'idEvento', 'eventoId'],
      ),
      titulo: _readString(map, ['titulo'], fallback: 'Resposta sugerida'),
      mensagem: _readString(map, ['mensagem']),
      tom: _readString(map, ['tom'], fallback: 'profissional'),
      templateKey: _readString(
        map,
        ['template_key', 'templateKey'],
        fallback: 'padrao',
      ),
      camposUsados: _readStringList(
        map,
        ['campos_usados', 'camposUsados'],
      ),
      camposAusentes: _readStringList(
        map,
        ['campos_ausentes', 'camposAusentes'],
      ),
      precisaRevisao: _readBool(
        map,
        ['precisa_revisao', 'precisaRevisao'],
        fallback: true,
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
      status: _readString(map, ['status'], fallback: 'nova'),
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
      'id_sugestao': idSugestao,
      'id_cotacao': idCotacao,
      'id_fornecedor': idFornecedor,
      'id_evento': idEvento,
      'titulo': titulo,
      'mensagem': mensagem,
      'tom': tom,
      'template_key': templateKey,
      'campos_usados': camposUsados,
      'campos_ausentes': camposAusentes,
      'precisa_revisao': precisaRevisao,
      'origem': origem,
      'versao_regra': versaoRegra,
      'status': status,
      'metadados': metadados,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  SugestaoRespostaCotacaoModel copyWith({
    String? idSugestao,
    String? idCotacao,
    String? idFornecedor,
    String? idEvento,
    String? titulo,
    String? mensagem,
    String? tom,
    String? templateKey,
    List<String>? camposUsados,
    List<String>? camposAusentes,
    bool? precisaRevisao,
    String? origem,
    String? versaoRegra,
    String? status,
    Map<String, dynamic>? metadados,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return SugestaoRespostaCotacaoModel(
      idSugestao: idSugestao ?? this.idSugestao,
      idCotacao: idCotacao ?? this.idCotacao,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idEvento: idEvento ?? this.idEvento,
      titulo: titulo ?? this.titulo,
      mensagem: mensagem ?? this.mensagem,
      tom: tom ?? this.tom,
      templateKey: templateKey ?? this.templateKey,
      camposUsados: camposUsados ?? this.camposUsados,
      camposAusentes: camposAusentes ?? this.camposAusentes,
      precisaRevisao: precisaRevisao ?? this.precisaRevisao,
      origem: origem ?? this.origem,
      versaoRegra: versaoRegra ?? this.versaoRegra,
      status: status ?? this.status,
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

  static bool _readBool(
    Map<String, dynamic> map,
    List<String> keys, {
    bool fallback = false,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (['true', '1', 's', 'sim', 'yes'].contains(normalized)) {
          return true;
        }
        if (['false', '0', 'n', 'nao', 'não', 'no'].contains(normalized)) {
          return false;
        }
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
