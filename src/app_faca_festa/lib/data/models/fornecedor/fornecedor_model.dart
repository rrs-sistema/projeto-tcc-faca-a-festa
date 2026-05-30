import 'package:cloud_firestore/cloud_firestore.dart';

class FornecedorModel {
  final String idFornecedor;
  final String idUsuario;
  final String razaoSocial;
  final String? cnpj;
  final String telefone;
  final String email;
  final String? descricao;
  final bool aptoParaOperar;
  final bool ativo;
  final DateTime dataCadastro;

  final String? bannerUrl;

  /// Lista de categorias e subcategorias do fornecedor.
  final List<Map<String, dynamic>> categorias;

  /// Campos usados pela IA de recomendação para identificar em quais tipos
  /// de evento o fornecedor é compatível.
  ///
  /// Exemplo:
  /// tipoEventoIds: ["302191a2-dbf3-4ac6-ba53-08273b384cab"]
  /// tipoEventoSlugs: ["casamento"]
  /// tipoEventoNomes: ["Casamento"]
  final List<String> tipoEventoIds;
  final List<String> tipoEventoSlugs;
  final List<String> tipoEventoNomes;

  /// Campos opcionais para melhorar a recomendação por orçamento.
  final double? precoMinimo;
  final double? precoMaximo;
  final double? precoMedio;

  /// Métricas de qualidade e confiança.
  final double mediaAvaliacoes;
  final int totalAvaliacoes;
  final bool isTopCategoria;
  final int totalContratacoes;
  final double? tempoMedioRespostaHoras;

  final String? fcmToken;

  const FornecedorModel({
    required this.idFornecedor,
    required this.idUsuario,
    required this.razaoSocial,
    required this.telefone,
    required this.email,
    this.cnpj,
    this.descricao,
    this.aptoParaOperar = false,
    this.ativo = true,
    required this.dataCadastro,
    this.bannerUrl,
    this.categorias = const [],
    this.tipoEventoIds = const [],
    this.tipoEventoSlugs = const [],
    this.tipoEventoNomes = const [],
    this.precoMinimo,
    this.precoMaximo,
    this.precoMedio,
    this.mediaAvaliacoes = 0.0,
    this.totalAvaliacoes = 0,
    this.isTopCategoria = false,
    this.totalContratacoes = 0,
    this.tempoMedioRespostaHoras,
    this.fcmToken,
  });

  factory FornecedorModel.novo({
    required String idFornecedor,
    required String idUsuario,
    required String razaoSocial,
    required String telefone,
    required String email,
    String? cnpj,
    String? descricao,
    bool aptoParaOperar = false,
    bool ativo = true,
    String? bannerUrl,
    List<Map<String, dynamic>> categorias = const [],
    List<String> tipoEventoIds = const [],
    List<String> tipoEventoSlugs = const [],
    List<String> tipoEventoNomes = const [],
    double? precoMinimo,
    double? precoMaximo,
    double? precoMedio,
    String? fcmToken,
  }) {
    return FornecedorModel(
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
      razaoSocial: razaoSocial,
      telefone: telefone,
      email: email,
      cnpj: cnpj,
      descricao: descricao,
      aptoParaOperar: aptoParaOperar,
      ativo: ativo,
      dataCadastro: DateTime.now(),
      bannerUrl: bannerUrl,
      categorias: categorias,
      tipoEventoIds: tipoEventoIds,
      tipoEventoSlugs: tipoEventoSlugs,
      tipoEventoNomes: tipoEventoNomes,
      precoMinimo: precoMinimo,
      precoMaximo: precoMaximo,
      precoMedio: precoMedio,
      fcmToken: fcmToken,
    );
  }

  Map<String, dynamic> toMap() {
    final categoriasLimpa = categorias.map((c) {
      final map = Map<String, dynamic>.from(c);

      if (map['dataCadastro'] is DateTime) {
        map['dataCadastro'] = Timestamp.fromDate(map['dataCadastro']);
      }

      if (map['data_cadastro'] is DateTime) {
        map['data_cadastro'] = Timestamp.fromDate(map['data_cadastro']);
      }

      if (map['dataCadastro'] is FieldValue) {
        map.remove('dataCadastro');
      }

      if (map['data_cadastro'] is FieldValue) {
        map.remove('data_cadastro');
      }

      return map;
    }).toList();

    return {
      // Campos legados usados atualmente no app.
      'id_fornecedor': idFornecedor,
      'id_usuario': idUsuario,
      'cnpj': cnpj,
      'razao_social': razaoSocial,
      'telefone': telefone,
      'email': email,
      'descricao': descricao,
      'apto_para_operar': aptoParaOperar,
      'ativo': ativo,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
      'banner_url': bannerUrl,
      'categorias': categoriasLimpa,

      // Campos novos para IA de recomendação em camelCase.
      'tipoEventoIds': tipoEventoIds,
      'tipoEventoSlugs': tipoEventoSlugs,
      'tipoEventoNomes': tipoEventoNomes,
      'precoMinimo': precoMinimo,
      'precoMaximo': precoMaximo,
      'precoMedio': precoMedio,
      'totalContratacoes': totalContratacoes,
      'tempoMedioRespostaHoras': tempoMedioRespostaHoras,

      // Compatibilidade para consultas antigas ou Functions que ainda usem snake_case.
      'tipo_evento_ids': tipoEventoIds,
      'tipo_evento_slugs': tipoEventoSlugs,
      'tipo_evento_nomes': tipoEventoNomes,
      'preco_minimo': precoMinimo,
      'preco_maximo': precoMaximo,
      'preco_medio': precoMedio,
      'total_contratacoes': totalContratacoes,
      'tempo_medio_resposta_horas': tempoMedioRespostaHoras,

      // Avaliações.
      'media_avaliacoes': mediaAvaliacoes,
      'total_avaliacoes': totalAvaliacoes,
      'is_top_categoria': isTopCategoria,
      'fcm_token': fcmToken,
    };
  }

  factory FornecedorModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return FornecedorModel(
      idFornecedor: _readString(
        map,
        ['id_fornecedor', 'fornecedorId', 'idFornecedor', 'id'],
        fallback: documentId ?? '',
      ),
      idUsuario: _readString(map, ['id_usuario', 'usuarioId', 'idUsuario']),
      razaoSocial: _readString(
        map,
        ['razao_social', 'razaoSocial', 'nomeFornecedor', 'nome'],
      ),
      telefone: _readString(map, ['telefone', 'celular', 'whatsapp']),
      email: _readString(map, ['email']),
      cnpj: _readNullableString(map, ['cnpj']),
      descricao: _readNullableString(map, ['descricao', 'description']),
      aptoParaOperar: _readBool(
        map,
        ['apto_para_operar', 'aptoParaOperar'],
        fallback: false,
      ),
      ativo: _readBool(map, ['ativo', 'active'], fallback: true),
      dataCadastro: _readDate(
        map,
        ['data_cadastro', 'dataCadastro', 'createdAt'],
      ),
      bannerUrl: _readNullableString(map, ['banner_url', 'bannerUrl']),
      categorias: _readMapList(map['categorias']),
      tipoEventoIds: _readStringList(
        map,
        ['tipoEventoIds', 'tipo_evento_ids'],
      ),
      tipoEventoSlugs: _readStringList(
        map,
        ['tipoEventoSlugs', 'tipo_evento_slugs'],
      ),
      tipoEventoNomes: _readStringList(
        map,
        ['tipoEventoNomes', 'tipo_evento_nomes'],
      ),
      precoMinimo: _readNullableDouble(map, ['precoMinimo', 'preco_minimo']),
      precoMaximo: _readNullableDouble(map, ['precoMaximo', 'preco_maximo']),
      precoMedio: _readNullableDouble(map, ['precoMedio', 'preco_medio']),
      mediaAvaliacoes: _readDouble(
        map,
        ['media_avaliacoes', 'mediaAvaliacoes'],
      ),
      totalAvaliacoes: _readInt(
        map,
        ['total_avaliacoes', 'totalAvaliacoes'],
      ),
      isTopCategoria: _readBool(
        map,
        ['is_top_categoria', 'isTopCategoria'],
      ),
      totalContratacoes: _readInt(
        map,
        ['totalContratacoes', 'total_contratacoes'],
      ),
      tempoMedioRespostaHoras: _readNullableDouble(
        map,
        ['tempoMedioRespostaHoras', 'tempo_medio_resposta_horas'],
      ),
      fcmToken: _readNullableString(map, ['fcm_token', 'fcmToken']),
    );
  }

  FornecedorModel copyWith({
    String? idFornecedor,
    String? idUsuario,
    String? razaoSocial,
    String? cnpj,
    String? telefone,
    String? email,
    String? descricao,
    bool? aptoParaOperar,
    bool? ativo,
    DateTime? dataCadastro,
    String? bannerUrl,
    List<Map<String, dynamic>>? categorias,
    List<String>? tipoEventoIds,
    List<String>? tipoEventoSlugs,
    List<String>? tipoEventoNomes,
    double? precoMinimo,
    double? precoMaximo,
    double? precoMedio,
    double? mediaAvaliacoes,
    int? totalAvaliacoes,
    bool? isTopCategoria,
    int? totalContratacoes,
    double? tempoMedioRespostaHoras,
    String? fcmToken,
  }) {
    return FornecedorModel(
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idUsuario: idUsuario ?? this.idUsuario,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      descricao: descricao ?? this.descricao,
      aptoParaOperar: aptoParaOperar ?? this.aptoParaOperar,
      ativo: ativo ?? this.ativo,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      categorias: categorias ?? this.categorias,
      tipoEventoIds: tipoEventoIds ?? this.tipoEventoIds,
      tipoEventoSlugs: tipoEventoSlugs ?? this.tipoEventoSlugs,
      tipoEventoNomes: tipoEventoNomes ?? this.tipoEventoNomes,
      precoMinimo: precoMinimo ?? this.precoMinimo,
      precoMaximo: precoMaximo ?? this.precoMaximo,
      precoMedio: precoMedio ?? this.precoMedio,
      mediaAvaliacoes: mediaAvaliacoes ?? this.mediaAvaliacoes,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      isTopCategoria: isTopCategoria ?? this.isTopCategoria,
      totalContratacoes: totalContratacoes ?? this.totalContratacoes,
      tempoMedioRespostaHoras: tempoMedioRespostaHoras ?? this.tempoMedioRespostaHoras,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  bool atendeTipoEvento({
    String? tipoEventoId,
    String? tipoEventoSlug,
    String? tipoEventoNome,
  }) {
    final id = tipoEventoId?.trim();
    final slug = _normalizarTexto(tipoEventoSlug);
    final nome = _normalizarTexto(tipoEventoNome);

    final ids = tipoEventoIds.map((e) => e.trim()).where((e) => e.isNotEmpty);
    final slugs = tipoEventoSlugs.map(_normalizarTexto).where((e) => e.isNotEmpty);
    final nomes = tipoEventoNomes.map(_normalizarTexto).where((e) => e.isNotEmpty);

    if (id != null && id.isNotEmpty && ids.contains(id)) return true;
    if (slug.isNotEmpty && slugs.contains(slug)) return true;
    if (nome.isNotEmpty && nomes.contains(nome)) return true;

    return false;
  }

  bool get possuiRestricaoTipoEvento {
    return tipoEventoIds.isNotEmpty || tipoEventoSlugs.isNotEmpty || tipoEventoNomes.isNotEmpty;
  }

  static String _normalizarTexto(dynamic value) {
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text.isEmpty) return '';

    return text
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
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
      if (text.isNotEmpty) return text;
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
        if (['true', '1', 's', 'sim', 'y', 'yes'].contains(normalized)) {
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
        final normalized = value.trim().replaceAll(',', '.');
        final parsed = double.tryParse(normalized);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static DateTime _readDate(
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

    return DateTime.now();
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
            .where((item) => item.isNotEmpty)
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

    return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }
}
