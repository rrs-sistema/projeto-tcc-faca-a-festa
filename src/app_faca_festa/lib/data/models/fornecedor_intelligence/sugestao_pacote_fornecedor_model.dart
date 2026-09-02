import 'package:cloud_firestore/cloud_firestore.dart';

class SugestaoPacoteFornecedorModel {
  final String idSugestao;
  final String idFornecedor;
  final String? idEvento;
  final String? idCotacao;

  /// Exemplo: economico, padrao, premium.
  final String tipoPacote;

  final String nomePacote;
  final String descricao;

  /// Lista flexível para itens do pacote.
  /// Exemplo:
  /// {
  ///   "nome": "Docinhos tradicionais",
  ///   "quantidade": 100,
  ///   "tipo_medida": "unidade",
  ///   "valor": 250.0
  /// }
  final List<Map<String, dynamic>> itensSugeridos;

  final double? valorMinimo;
  final double? valorEstimado;
  final double? valorMaximo;

  final int? quantidadeBase;
  final double? totalConvidadosEquivalentes;

  final List<String> motivos;
  final List<String> alertas;

  /// Exemplo: deterministic_rules, generative_ai, hybrid.
  final String origem;

  final String versaoRegra;

  /// Exemplo: nova, aplicada, editada, ignorada.
  final String status;

  final Map<String, dynamic>? metadados;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const SugestaoPacoteFornecedorModel({
    required this.idSugestao,
    required this.idFornecedor,
    required this.tipoPacote,
    required this.nomePacote,
    required this.descricao,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.idEvento,
    this.idCotacao,
    this.itensSugeridos = const [],
    this.valorMinimo,
    this.valorEstimado,
    this.valorMaximo,
    this.quantidadeBase,
    this.totalConvidadosEquivalentes,
    this.motivos = const [],
    this.alertas = const [],
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });

  factory SugestaoPacoteFornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return SugestaoPacoteFornecedorModel(
      idSugestao: _readString(
        map,
        ['id_sugestao', 'idSugestao', 'id'],
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
      tipoPacote: _readString(
        map,
        ['tipo_pacote', 'tipoPacote'],
        fallback: 'padrao',
      ),
      nomePacote: _readString(
        map,
        ['nome_pacote', 'nomePacote'],
        fallback: 'Pacote sugerido',
      ),
      descricao: _readString(map, ['descricao']),
      itensSugeridos: _readMapList(
        map['itens_sugeridos'] ?? map['itensSugeridos'],
      ),
      valorMinimo: _readNullableDouble(
        map,
        ['valor_minimo', 'valorMinimo'],
      ),
      valorEstimado: _readNullableDouble(
        map,
        ['valor_estimado', 'valorEstimado'],
      ),
      valorMaximo: _readNullableDouble(
        map,
        ['valor_maximo', 'valorMaximo'],
      ),
      quantidadeBase: _readNullableInt(
        map,
        ['quantidade_base', 'quantidadeBase'],
      ),
      totalConvidadosEquivalentes: _readNullableDouble(
        map,
        [
          'total_convidados_equivalentes',
          'totalConvidadosEquivalentes',
        ],
      ),
      motivos: _readStringList(map, ['motivos']),
      alertas: _readStringList(map, ['alertas']),
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
      'id_fornecedor': idFornecedor,
      'id_evento': idEvento,
      'id_cotacao': idCotacao,
      'tipo_pacote': tipoPacote,
      'nome_pacote': nomePacote,
      'descricao': descricao,
      'itens_sugeridos': itensSugeridos,
      'valor_minimo': valorMinimo,
      'valor_estimado': valorEstimado,
      'valor_maximo': valorMaximo,
      'quantidade_base': quantidadeBase,
      'total_convidados_equivalentes': totalConvidadosEquivalentes,
      'motivos': motivos,
      'alertas': alertas,
      'origem': origem,
      'versao_regra': versaoRegra,
      'status': status,
      'metadados': metadados,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  SugestaoPacoteFornecedorModel copyWith({
    String? idSugestao,
    String? idFornecedor,
    String? idEvento,
    String? idCotacao,
    String? tipoPacote,
    String? nomePacote,
    String? descricao,
    List<Map<String, dynamic>>? itensSugeridos,
    double? valorMinimo,
    double? valorEstimado,
    double? valorMaximo,
    int? quantidadeBase,
    double? totalConvidadosEquivalentes,
    List<String>? motivos,
    List<String>? alertas,
    String? origem,
    String? versaoRegra,
    String? status,
    Map<String, dynamic>? metadados,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return SugestaoPacoteFornecedorModel(
      idSugestao: idSugestao ?? this.idSugestao,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idEvento: idEvento ?? this.idEvento,
      idCotacao: idCotacao ?? this.idCotacao,
      tipoPacote: tipoPacote ?? this.tipoPacote,
      nomePacote: nomePacote ?? this.nomePacote,
      descricao: descricao ?? this.descricao,
      itensSugeridos: itensSugeridos ?? this.itensSugeridos,
      valorMinimo: valorMinimo ?? this.valorMinimo,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      valorMaximo: valorMaximo ?? this.valorMaximo,
      quantidadeBase: quantidadeBase ?? this.quantidadeBase,
      totalConvidadosEquivalentes:
          totalConvidadosEquivalentes ?? this.totalConvidadosEquivalentes,
      motivos: motivos ?? this.motivos,
      alertas: alertas ?? this.alertas,
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

  static int? _readNullableInt(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
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

  static List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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
