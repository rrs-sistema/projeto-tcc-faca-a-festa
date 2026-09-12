import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/fornecedor_recomendacao.dart';

export 'package:app_faca_festa/domain/entities/fornecedor_recomendacao.dart';

class FornecedorRecomendacaoModel extends FornecedorRecomendacao {
  const FornecedorRecomendacaoModel({
    required super.id,
    required super.idEvento,
    required super.idUsuario,
    required super.idFornecedor,
    required super.nomeFornecedor,
    required super.score,
    required super.nivel,
    required super.mediaAvaliacoes,
    required super.totalAvaliacoes,
    required super.motivos,
    super.bannerUrl,
    super.categoriaPrincipal,
    super.nivelLabelBackend,
    super.motivoPrincipal,
    super.compatibilidadePercentual,
    super.distanciaKm,
    super.tipoEventoNomes = const [],
    super.tipoEventoSlugs = const [],
    super.tipoEventoIds = const [],
    super.tipoEventoInformado = false,
    super.tipoEventoCompativel = false,
    super.tipoEventoIncompativel = false,
    super.createdAt,
    super.updatedAt,
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

  @override
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

  factory FornecedorRecomendacaoModel.fromEntity(
    FornecedorRecomendacao recomendacao,
  ) {
    return FornecedorRecomendacaoModel(
      id: recomendacao.id,
      idEvento: recomendacao.idEvento,
      idUsuario: recomendacao.idUsuario,
      idFornecedor: recomendacao.idFornecedor,
      nomeFornecedor: recomendacao.nomeFornecedor,
      bannerUrl: recomendacao.bannerUrl,
      categoriaPrincipal: recomendacao.categoriaPrincipal,
      score: recomendacao.score,
      nivel: recomendacao.nivel,
      nivelLabelBackend: recomendacao.nivelLabelBackend,
      motivoPrincipal: recomendacao.motivoPrincipal,
      compatibilidadePercentual: recomendacao.compatibilidadePercentual,
      mediaAvaliacoes: recomendacao.mediaAvaliacoes,
      totalAvaliacoes: recomendacao.totalAvaliacoes,
      distanciaKm: recomendacao.distanciaKm,
      motivos: recomendacao.motivos,
      tipoEventoNomes: recomendacao.tipoEventoNomes,
      tipoEventoSlugs: recomendacao.tipoEventoSlugs,
      tipoEventoIds: recomendacao.tipoEventoIds,
      tipoEventoInformado: recomendacao.tipoEventoInformado,
      tipoEventoCompativel: recomendacao.tipoEventoCompativel,
      tipoEventoIncompativel: recomendacao.tipoEventoIncompativel,
      createdAt: recomendacao.createdAt,
      updatedAt: recomendacao.updatedAt,
    );
  }
}
