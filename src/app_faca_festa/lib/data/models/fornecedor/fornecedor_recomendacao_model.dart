import 'package:cloud_firestore/cloud_firestore.dart';

class FornecedorRecomendacaoModel {
  final String id;
  final String idEvento;
  final String idUsuario;
  final String idFornecedor;
  final String nomeFornecedor;
  final String? bannerUrl;
  final String? categoriaPrincipal;
  final double score;
  final String nivel;
  final String? nivelLabelBackend;
  final String? motivoPrincipal;
  final double? compatibilidadePercentual;
  final double mediaAvaliacoes;
  final int totalAvaliacoes;
  final double? distanciaKm;
  final List<String> motivos;
  final List<String> tipoEventoNomes;
  final List<String> tipoEventoSlugs;
  final List<String> tipoEventoIds;
  final bool tipoEventoInformado;
  final bool tipoEventoCompativel;
  final bool tipoEventoIncompativel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FornecedorRecomendacaoModel({
    required this.id,
    required this.idEvento,
    required this.idUsuario,
    required this.idFornecedor,
    required this.nomeFornecedor,
    required this.score,
    required this.nivel,
    required this.mediaAvaliacoes,
    required this.totalAvaliacoes,
    required this.motivos,
    this.bannerUrl,
    this.categoriaPrincipal,
    this.nivelLabelBackend,
    this.motivoPrincipal,
    this.compatibilidadePercentual,
    this.distanciaKm,
    this.tipoEventoNomes = const [],
    this.tipoEventoSlugs = const [],
    this.tipoEventoIds = const [],
    this.tipoEventoInformado = false,
    this.tipoEventoCompativel = false,
    this.tipoEventoIncompativel = false,
    this.createdAt,
    this.updatedAt,
  });

  factory FornecedorRecomendacaoModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      final normalized = value?.toString().toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'sim';
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();
      }
      return <String>[];
    }

    String? parseNullableString(dynamic value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || text == 'null') return null;
      return text;
    }

    final score = parseDouble(map['score']);
    final compatibilidade = parseNullableDouble(
      map['compatibilidadePercentual'] ?? map['compatibilidade_percentual'],
    );

    return FornecedorRecomendacaoModel(
      id: documentId ?? map['id']?.toString() ?? '',
      idEvento: map['eventoId']?.toString() ??
          map['id_evento']?.toString() ??
          map['idEvento']?.toString() ??
          '',
      idUsuario: map['usuarioId']?.toString() ??
          map['id_usuario']?.toString() ??
          map['idUsuario']?.toString() ??
          '',
      idFornecedor: map['fornecedorId']?.toString() ??
          map['id_fornecedor']?.toString() ??
          map['idFornecedor']?.toString() ??
          '',
      nomeFornecedor: map['nomeFornecedor']?.toString() ??
          map['nome_fornecedor']?.toString() ??
          map['nome']?.toString() ??
          'Fornecedor',
      bannerUrl: parseNullableString(map['bannerUrl'] ?? map['banner_url']),
      categoriaPrincipal: parseNullableString(
        map['categoriaPrincipal'] ?? map['categoria_principal'],
      ),
      score: score,
      nivel: map['nivel']?.toString() ?? 'recomendado',
      nivelLabelBackend: parseNullableString(
        map['nivelLabel'] ?? map['nivel_label'],
      ),
      motivoPrincipal: parseNullableString(
        map['motivoPrincipal'] ?? map['motivo_principal'],
      ),
      compatibilidadePercentual: compatibilidade,
      mediaAvaliacoes: parseDouble(
        map['mediaAvaliacoes'] ?? map['media_avaliacoes'],
      ),
      totalAvaliacoes: parseInt(
        map['totalAvaliacoes'] ?? map['total_avaliacoes'],
      ),
      distanciaKm: map['distanciaKm'] != null || map['distancia_km'] != null
          ? parseDouble(map['distanciaKm'] ?? map['distancia_km'])
          : null,
      motivos: parseStringList(map['motivos']),
      tipoEventoNomes: parseStringList(
        map['tipoEventoNomes'] ?? map['tipo_evento_nomes'],
      ),
      tipoEventoSlugs: parseStringList(
        map['tipoEventoSlugs'] ?? map['tipo_evento_slugs'],
      ),
      tipoEventoIds: parseStringList(
        map['tipoEventoIds'] ?? map['tipo_evento_ids'],
      ),
      tipoEventoInformado: parseBool(
        map['tipoEventoInformado'] ?? map['tipo_evento_informado'],
      ),
      tipoEventoCompativel: parseBool(
        map['tipoEventoCompativel'] ?? map['tipo_evento_compativel'],
      ),
      tipoEventoIncompativel: parseBool(
        map['tipoEventoIncompativel'] ?? map['tipo_evento_incompativel'],
      ),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      updatedAt: parseDate(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventoId': idEvento,
      'usuarioId': idUsuario,
      'fornecedorId': idFornecedor,
      'nomeFornecedor': nomeFornecedor,
      'bannerUrl': bannerUrl,
      'categoriaPrincipal': categoriaPrincipal,
      'score': score,
      'nivel': nivel,
      'nivelLabel': nivelLabel,
      'motivoPrincipal': motivoPrincipalSeguro,
      'compatibilidadePercentual': compatibilidadeNumero,
      'mediaAvaliacoes': mediaAvaliacoes,
      'totalAvaliacoes': totalAvaliacoes,
      'distanciaKm': distanciaKm,
      'motivos': motivos,
      'tipoEventoNomes': tipoEventoNomes,
      'tipoEventoSlugs': tipoEventoSlugs,
      'tipoEventoIds': tipoEventoIds,
      'tipoEventoInformado': tipoEventoInformado,
      'tipoEventoCompativel': tipoEventoCompativel,
      'tipoEventoIncompativel': tipoEventoIncompativel,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  FornecedorRecomendacaoModel copyWith({
    String? id,
    String? idEvento,
    String? idUsuario,
    String? idFornecedor,
    String? nomeFornecedor,
    String? bannerUrl,
    String? categoriaPrincipal,
    double? score,
    String? nivel,
    String? nivelLabelBackend,
    String? motivoPrincipal,
    double? compatibilidadePercentual,
    double? mediaAvaliacoes,
    int? totalAvaliacoes,
    double? distanciaKm,
    List<String>? motivos,
    List<String>? tipoEventoNomes,
    List<String>? tipoEventoSlugs,
    List<String>? tipoEventoIds,
    bool? tipoEventoInformado,
    bool? tipoEventoCompativel,
    bool? tipoEventoIncompativel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FornecedorRecomendacaoModel(
      id: id ?? this.id,
      idEvento: idEvento ?? this.idEvento,
      idUsuario: idUsuario ?? this.idUsuario,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      categoriaPrincipal: categoriaPrincipal ?? this.categoriaPrincipal,
      score: score ?? this.score,
      nivel: nivel ?? this.nivel,
      nivelLabelBackend: nivelLabelBackend ?? this.nivelLabelBackend,
      motivoPrincipal: motivoPrincipal ?? this.motivoPrincipal,
      compatibilidadePercentual:
          compatibilidadePercentual ?? this.compatibilidadePercentual,
      mediaAvaliacoes: mediaAvaliacoes ?? this.mediaAvaliacoes,
      totalAvaliacoes: totalAvaliacoes ?? this.totalAvaliacoes,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      motivos: motivos ?? this.motivos,
      tipoEventoNomes: tipoEventoNomes ?? this.tipoEventoNomes,
      tipoEventoSlugs: tipoEventoSlugs ?? this.tipoEventoSlugs,
      tipoEventoIds: tipoEventoIds ?? this.tipoEventoIds,
      tipoEventoInformado: tipoEventoInformado ?? this.tipoEventoInformado,
      tipoEventoCompativel: tipoEventoCompativel ?? this.tipoEventoCompativel,
      tipoEventoIncompativel:
          tipoEventoIncompativel ?? this.tipoEventoIncompativel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get compatibilidadeNumero {
    final value = compatibilidadePercentual ?? score;
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  String get scorePercentual => '${compatibilidadeNumero.round()}%';

  String get nivelLabel {
    if (nivelLabelBackend != null && nivelLabelBackend!.trim().isNotEmpty) {
      return nivelLabelBackend!;
    }

    switch (nivel) {
      case 'altamente_recomendado':
        return 'Altamente recomendado';
      case 'muito_compativel':
        return 'Muito compatível';
      case 'compativel':
        return 'Compatível';
      case 'sugestao_complementar':
      case 'pouca_aderencia':
        return 'Sugestão complementar';
      default:
        if (compatibilidadeNumero >= 85) return 'Altamente recomendado';
        if (compatibilidadeNumero >= 65) return 'Muito compatível';
        if (compatibilidadeNumero >= 45) return 'Compatível';
        return 'Sugestão complementar';
    }
  }

  String get motivoPrincipalSeguro {
    final motivo = motivoPrincipal?.trim();
    if (motivo != null && motivo.isNotEmpty) return motivo;
    if (motivos.isNotEmpty) return motivos.first;
    if (tipoEventoCompativel) return 'Atende o tipo de evento selecionado';
    if (categoriaPrincipal != null && categoriaPrincipal!.trim().isNotEmpty) {
      return 'Categoria compatível com seu evento';
    }
    return 'Fornecedor recomendado para análise';
  }

  List<String> get motivosVisiveis {
    final principal = motivoPrincipalSeguro.trim();
    final lista = <String>[principal];

    for (final motivo in motivos) {
      final item = motivo.trim();
      if (item.isEmpty) continue;
      if (lista.any((e) => e.toLowerCase() == item.toLowerCase())) continue;
      lista.add(item);
    }

    return lista.take(4).toList(growable: false);
  }

  String get avaliacaoTexto {
    if (totalAvaliacoes <= 0 || mediaAvaliacoes <= 0) {
      return 'Sem avaliações';
    }

    return '${mediaAvaliacoes.toStringAsFixed(1)} ($totalAvaliacoes)';
  }

  String get distanciaTexto {
    if (distanciaKm == null) return '';
    if (distanciaKm! < 1) {
      return '${(distanciaKm! * 1000).round()} m';
    }
    return '${distanciaKm!.toStringAsFixed(1)} km';
  }

  String get tiposEventoTexto {
    if (tipoEventoNomes.isEmpty) return '';
    return tipoEventoNomes.take(3).join(' • ');
  }

  bool get altaCompatibilidade => compatibilidadeNumero >= 85;

  bool get boaCompatibilidade => compatibilidadeNumero >= 65;

  bool get baixaCompatibilidade => compatibilidadeNumero < 45;
}
