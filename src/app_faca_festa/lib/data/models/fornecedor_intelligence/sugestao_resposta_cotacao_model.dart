import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/sugestao_resposta_cotacao.dart';


class SugestaoRespostaCotacaoModel extends SugestaoRespostaCotacao {
  const SugestaoRespostaCotacaoModel({
    required super.idSugestao,
    required super.idCotacao,
    required super.idFornecedor,
    required super.titulo,
    required super.mensagem,
    required super.tom,
    required super.templateKey,
    required super.precisaRevisao,
    required super.origem,
    required super.versaoRegra,
    required super.status,
    required super.createdAt,
    super.idEvento,
    super.camposUsados,
    super.camposAusentes,
    super.updatedAt,
    super.expiresAt,
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

}
