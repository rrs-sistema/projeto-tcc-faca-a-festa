import 'package:cloud_firestore/cloud_firestore.dart';

class ProximaAcaoFornecedorModel {
  final String idAcao;
  final String idFornecedor;
  final String? idEvento;
  final String? idCotacao;

  /// Exemplo: responder_cotacao, enviar_lembrete,
  /// melhorar_catalogo, pedir_avaliacao, criar_promocao.
  final String tipoAcao;

  final String titulo;
  final String descricao;

  /// Texto do botão ou ação principal.
  final String acaoPrincipal;

  final List<String> acoesSecundarias;
  final List<String> motivos;

  /// Prioridade sugerida para ordenação.
  /// Exemplo: 1 = baixa, 5 = alta.
  final int prioridade;

  final bool urgente;

  /// Score opcional de 0 a 100.
  final double? score;

  /// Exemplo: pendente, visualizada, respondida.
  final String? statusCotacao;

  /// Exemplo: deterministic_rules, generative_ai, hybrid.
  final String origem;

  final String versaoRegra;

  /// Exemplo: novo, visto, executado, ignorado, expirado.
  final String status;

  final Map<String, dynamic>? metadados;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const ProximaAcaoFornecedorModel({
    required this.idAcao,
    required this.idFornecedor,
    required this.tipoAcao,
    required this.titulo,
    required this.descricao,
    required this.acaoPrincipal,
    required this.prioridade,
    required this.urgente,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.idEvento,
    this.idCotacao,
    this.acoesSecundarias = const [],
    this.motivos = const [],
    this.score,
    this.statusCotacao,
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });

  factory ProximaAcaoFornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return ProximaAcaoFornecedorModel(
      idAcao: _readString(
        map,
        ['id_acao', 'idAcao', 'id'],
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
      tipoAcao: _readString(
        map,
        ['tipo_acao', 'tipoAcao'],
        fallback: 'geral',
      ),
      titulo: _readString(map, ['titulo'], fallback: 'Próxima ação'),
      descricao: _readString(map, ['descricao']),
      acaoPrincipal: _readString(
        map,
        ['acao_principal', 'acaoPrincipal'],
      ),
      acoesSecundarias: _readStringList(
        map,
        ['acoes_secundarias', 'acoesSecundarias'],
      ),
      motivos: _readStringList(map, ['motivos']),
      prioridade: _readInt(map, ['prioridade'], fallback: 1),
      urgente: _readBool(map, ['urgente'], fallback: false),
      score: _readNullableDouble(map, ['score']),
      statusCotacao: _readNullableString(
        map,
        ['status_cotacao', 'statusCotacao'],
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
      status: _readString(map, ['status'], fallback: 'novo'),
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
      'id_acao': idAcao,
      'id_fornecedor': idFornecedor,
      'id_evento': idEvento,
      'id_cotacao': idCotacao,
      'tipo_acao': tipoAcao,
      'titulo': titulo,
      'descricao': descricao,
      'acao_principal': acaoPrincipal,
      'acoes_secundarias': acoesSecundarias,
      'motivos': motivos,
      'prioridade': prioridade,
      'urgente': urgente,
      'score': score,
      'status_cotacao': statusCotacao,
      'origem': origem,
      'versao_regra': versaoRegra,
      'status': status,
      'metadados': metadados,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  ProximaAcaoFornecedorModel copyWith({
    String? idAcao,
    String? idFornecedor,
    String? idEvento,
    String? idCotacao,
    String? tipoAcao,
    String? titulo,
    String? descricao,
    String? acaoPrincipal,
    List<String>? acoesSecundarias,
    List<String>? motivos,
    int? prioridade,
    bool? urgente,
    double? score,
    String? statusCotacao,
    String? origem,
    String? versaoRegra,
    String? status,
    Map<String, dynamic>? metadados,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return ProximaAcaoFornecedorModel(
      idAcao: idAcao ?? this.idAcao,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idEvento: idEvento ?? this.idEvento,
      idCotacao: idCotacao ?? this.idCotacao,
      tipoAcao: tipoAcao ?? this.tipoAcao,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      acaoPrincipal: acaoPrincipal ?? this.acaoPrincipal,
      acoesSecundarias: acoesSecundarias ?? this.acoesSecundarias,
      motivos: motivos ?? this.motivos,
      prioridade: prioridade ?? this.prioridade,
      urgente: urgente ?? this.urgente,
      score: score ?? this.score,
      statusCotacao: statusCotacao ?? this.statusCotacao,
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
