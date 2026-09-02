import 'package:cloud_firestore/cloud_firestore.dart';

class SugestaoCatalogoFornecedorModel {
  final String idSugestao;
  final String idFornecedor;

  /// Score de saúde do catálogo de 0 a 100.
  final double scoreCatalogo;

  /// Exemplo: fraco, basico, bom, completo.
  final String nivelCatalogo;

  final String titulo;
  final String descricao;

  final List<String> pendencias;
  final List<String> melhoriasPrioritarias;
  final List<String> camposAusentes;

  /// Lista flexível para serviços com problema.
  /// Exemplo:
  /// {
  ///   "id_servico": "abc",
  ///   "nome_servico": "Bolo personalizado",
  ///   "alertas": ["sem_imagem", "sem_descricao"]
  /// }
  final List<Map<String, dynamic>> servicosComAlerta;

  final List<String> categoriasSemServico;

  final int totalServicosAtivos;
  final int totalServicosSemImagem;
  final int totalServicosSemPreco;
  final int totalServicosSemDescricao;

  /// Exemplo: deterministic_rules, generative_ai, hybrid.
  final String origem;

  final String versaoRegra;

  /// Exemplo: nova, vista, aplicada, ignorada.
  final String status;

  final Map<String, dynamic>? metadados;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const SugestaoCatalogoFornecedorModel({
    required this.idSugestao,
    required this.idFornecedor,
    required this.scoreCatalogo,
    required this.nivelCatalogo,
    required this.titulo,
    required this.descricao,
    required this.totalServicosAtivos,
    required this.totalServicosSemImagem,
    required this.totalServicosSemPreco,
    required this.totalServicosSemDescricao,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.pendencias = const [],
    this.melhoriasPrioritarias = const [],
    this.camposAusentes = const [],
    this.servicosComAlerta = const [],
    this.categoriasSemServico = const [],
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });

  factory SugestaoCatalogoFornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return SugestaoCatalogoFornecedorModel(
      idSugestao: _readString(
        map,
        ['id_sugestao', 'idSugestao', 'id'],
        fallback: documentId ?? '',
      ),
      idFornecedor: _readString(
        map,
        ['id_fornecedor', 'idFornecedor', 'fornecedorId'],
      ),
      scoreCatalogo: _readDouble(
        map,
        ['score_catalogo', 'scoreCatalogo'],
      ),
      nivelCatalogo: _readString(
        map,
        ['nivel_catalogo', 'nivelCatalogo'],
        fallback: 'fraco',
      ),
      titulo: _readString(
        map,
        ['titulo'],
        fallback: 'Melhoria do catálogo',
      ),
      descricao: _readString(map, ['descricao']),
      pendencias: _readStringList(map, ['pendencias']),
      melhoriasPrioritarias: _readStringList(
        map,
        ['melhorias_prioritarias', 'melhoriasPrioritarias'],
      ),
      camposAusentes: _readStringList(
        map,
        ['campos_ausentes', 'camposAusentes'],
      ),
      servicosComAlerta: _readMapList(
        map['servicos_com_alerta'] ?? map['servicosComAlerta'],
      ),
      categoriasSemServico: _readStringList(
        map,
        ['categorias_sem_servico', 'categoriasSemServico'],
      ),
      totalServicosAtivos: _readInt(
        map,
        ['total_servicos_ativos', 'totalServicosAtivos'],
      ),
      totalServicosSemImagem: _readInt(
        map,
        ['total_servicos_sem_imagem', 'totalServicosSemImagem'],
      ),
      totalServicosSemPreco: _readInt(
        map,
        ['total_servicos_sem_preco', 'totalServicosSemPreco'],
      ),
      totalServicosSemDescricao: _readInt(
        map,
        ['total_servicos_sem_descricao', 'totalServicosSemDescricao'],
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
      'id_fornecedor': idFornecedor,
      'score_catalogo': scoreCatalogo,
      'nivel_catalogo': nivelCatalogo,
      'titulo': titulo,
      'descricao': descricao,
      'pendencias': pendencias,
      'melhorias_prioritarias': melhoriasPrioritarias,
      'campos_ausentes': camposAusentes,
      'servicos_com_alerta': servicosComAlerta,
      'categorias_sem_servico': categoriasSemServico,
      'total_servicos_ativos': totalServicosAtivos,
      'total_servicos_sem_imagem': totalServicosSemImagem,
      'total_servicos_sem_preco': totalServicosSemPreco,
      'total_servicos_sem_descricao': totalServicosSemDescricao,
      'origem': origem,
      'versao_regra': versaoRegra,
      'status': status,
      'metadados': metadados,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'expires_at': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
    };
  }

  SugestaoCatalogoFornecedorModel copyWith({
    String? idSugestao,
    String? idFornecedor,
    double? scoreCatalogo,
    String? nivelCatalogo,
    String? titulo,
    String? descricao,
    List<String>? pendencias,
    List<String>? melhoriasPrioritarias,
    List<String>? camposAusentes,
    List<Map<String, dynamic>>? servicosComAlerta,
    List<String>? categoriasSemServico,
    int? totalServicosAtivos,
    int? totalServicosSemImagem,
    int? totalServicosSemPreco,
    int? totalServicosSemDescricao,
    String? origem,
    String? versaoRegra,
    String? status,
    Map<String, dynamic>? metadados,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return SugestaoCatalogoFornecedorModel(
      idSugestao: idSugestao ?? this.idSugestao,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      scoreCatalogo: scoreCatalogo ?? this.scoreCatalogo,
      nivelCatalogo: nivelCatalogo ?? this.nivelCatalogo,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      pendencias: pendencias ?? this.pendencias,
      melhoriasPrioritarias:
          melhoriasPrioritarias ?? this.melhoriasPrioritarias,
      camposAusentes: camposAusentes ?? this.camposAusentes,
      servicosComAlerta: servicosComAlerta ?? this.servicosComAlerta,
      categoriasSemServico: categoriasSemServico ?? this.categoriasSemServico,
      totalServicosAtivos: totalServicosAtivos ?? this.totalServicosAtivos,
      totalServicosSemImagem:
          totalServicosSemImagem ?? this.totalServicosSemImagem,
      totalServicosSemPreco:
          totalServicosSemPreco ?? this.totalServicosSemPreco,
      totalServicosSemDescricao:
          totalServicosSemDescricao ?? this.totalServicosSemDescricao,
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
