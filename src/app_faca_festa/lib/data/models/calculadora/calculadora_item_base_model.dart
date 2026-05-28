import 'package:cloud_firestore/cloud_firestore.dart';

class CalculadoraItemBaseModel {
  static const String collectionName = 'calculadora_itens_base';

  static const String fieldId = 'id';
  static const String fieldNome = 'nome';
  static const String fieldDescricao = 'descricao';
  static const String fieldCategoriaPadrao = 'categoria_padrao';
  static const String fieldTipoItem = 'tipo_item';
  static const String fieldUnidadePadrao = 'unidade_padrao';
  static const String fieldPublicoAlvo = 'publico_alvo';
  static const String fieldAtivo = 'ativo';
  static const String fieldOrdem = 'ordem';
  static const String fieldIcone = 'icone';
  static const String fieldTags = 'tags';
  static const String fieldCreatedAt = 'created_at';
  static const String fieldUpdatedAt = 'updated_at';

  final String id;
  final String nome;
  final String descricao;
  final String categoriaPadrao;
  final String tipoItem;
  final String unidadePadrao;
  final String publicoAlvo;
  final bool ativo;
  final int ordem;
  final String icone;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalculadoraItemBaseModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.categoriaPadrao,
    required this.tipoItem,
    required this.unidadePadrao,
    required this.publicoAlvo,
    required this.ativo,
    required this.ordem,
    required this.icone,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalculadoraItemBaseModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return CalculadoraItemBaseModel(
      id: _parseString(
        map[fieldId] ?? map['document_id'],
      ),
      nome: _parseString(
        map[fieldNome],
      ),
      descricao: _parseString(
        map[fieldDescricao],
      ),
      categoriaPadrao: _parseString(
        map[fieldCategoriaPadrao] ?? map['categoriaPadrao'],
      ),
      tipoItem: _parseString(
        map[fieldTipoItem] ?? map['tipoItem'],
      ),
      unidadePadrao: _parseString(
        map[fieldUnidadePadrao] ?? map['unidadePadrao'],
      ),
      publicoAlvo: _parseString(
        map[fieldPublicoAlvo] ?? map['publicoAlvo'],
      ),
      ativo: _parseBool(
        map[fieldAtivo],
        defaultValue: true,
      ),
      ordem: _parseInt(
        map[fieldOrdem],
      ),
      icone: _parseString(
        map[fieldIcone],
      ),
      tags: _parseStringList(
        map[fieldTags],
      ),
      createdAt: _parseDateTime(
            map[fieldCreatedAt] ?? map['createdAt'],
          ) ??
          now,
      updatedAt: _parseDateTime(
            map[fieldUpdatedAt] ?? map['updatedAt'],
          ) ??
          now,
    );
  }

  factory CalculadoraItemBaseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final idFromData = _parseString(data[fieldId]);

    return CalculadoraItemBaseModel.fromMap({
      ...data,
      fieldId: idFromData.isNotEmpty ? idFromData : document.id,
    });
  }

  Map<String, dynamic> toMap() {
    return {
      fieldId: id,
      fieldNome: nome,
      fieldDescricao: descricao,
      fieldCategoriaPadrao: categoriaPadrao,
      fieldTipoItem: tipoItem,
      fieldUnidadePadrao: unidadePadrao,
      fieldPublicoAlvo: publicoAlvo,
      fieldAtivo: ativo,
      fieldOrdem: ordem,
      fieldIcone: icone,
      fieldTags: tags,
      fieldCreatedAt: Timestamp.fromDate(createdAt),
      fieldUpdatedAt: Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  CalculadoraItemBaseModel copyWith({
    String? id,
    String? nome,
    String? descricao,
    String? categoriaPadrao,
    String? tipoItem,
    String? unidadePadrao,
    String? publicoAlvo,
    bool? ativo,
    int? ordem,
    String? icone,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalculadoraItemBaseModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoriaPadrao: categoriaPadrao ?? this.categoriaPadrao,
      tipoItem: tipoItem ?? this.tipoItem,
      unidadePadrao: unidadePadrao ?? this.unidadePadrao,
      publicoAlvo: publicoAlvo ?? this.publicoAlvo,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      icone: icone ?? this.icone,
      tags: tags ?? List<String>.from(this.tags),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  CalculadoraItemBaseModel marcarComoAtivo() {
    return copyWith(
      ativo: true,
      updatedAt: DateTime.now(),
    );
  }

  CalculadoraItemBaseModel marcarComoInativo() {
    return copyWith(
      ativo: false,
      updatedAt: DateTime.now(),
    );
  }

  bool get inativo => !ativo;

  bool get possuiId => id.trim().isNotEmpty;

  bool get possuiNome => nome.trim().isNotEmpty;

  bool get possuiDescricao => descricao.trim().isNotEmpty;

  bool get possuiIcone => icone.trim().isNotEmpty;

  bool get possuiTags => tags.isNotEmpty;

  String get nomeNormalizado => nome.trim().toLowerCase();

  String get tipoItemNormalizado => tipoItem.trim().toLowerCase();

  String get categoriaNormalizada => categoriaPadrao.trim().toLowerCase();

  String get unidadeNormalizada => unidadePadrao.trim().toLowerCase();

  bool get isPublicoTodos {
    return publicoAlvo.trim().toLowerCase() == 'todos';
  }

  bool get isPublicoAdulto {
    final value = publicoAlvo.trim().toLowerCase();

    return value == 'adulto' || value == 'adultos';
  }

  bool get isPublicoCrianca {
    final value = publicoAlvo.trim().toLowerCase();

    return value == 'crianca' || value == 'criança' || value == 'criancas' || value == 'crianças';
  }

  bool contemTag(String tag) {
    final tagNormalizada = tag.trim().toLowerCase();

    if (tagNormalizada.isEmpty) {
      return false;
    }

    return tags.any(
      (item) => item.trim().toLowerCase() == tagNormalizada,
    );
  }

  static String _parseString(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is String) {
      return value.trim();
    }

    return value.toString().trim();
  }

  static int _parseInt(
    dynamic value, {
    int defaultValue = 0,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        return defaultValue;
      }

      final intValue = int.tryParse(normalized);

      if (intValue != null) {
        return intValue;
      }

      final doubleValue = double.tryParse(
        normalized.replaceAll(',', '.'),
      );

      return doubleValue?.toInt() ?? defaultValue;
    }

    return defaultValue;
  }

  static bool _parseBool(
    dynamic value, {
    bool defaultValue = false,
  }) {
    if (value == null) {
      return defaultValue;
    }

    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is num) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized.isEmpty) {
        return defaultValue;
      }

      if (_trueValues.contains(normalized)) {
        return true;
      }

      if (_falseValues.contains(normalized)) {
        return false;
      }
    }

    return defaultValue;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) {
      return <String>[];
    }

    final result = <String>[];

    if (value is List) {
      for (final item in value) {
        final parsed = _parseString(item);

        if (parsed.isNotEmpty && !result.contains(parsed)) {
          result.add(parsed);
        }
      }

      return result;
    }

    if (value is Set) {
      for (final item in value) {
        final parsed = _parseString(item);

        if (parsed.isNotEmpty && !result.contains(parsed)) {
          result.add(parsed);
        }
      }

      return result;
    }

    if (value is String) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        return <String>[];
      }

      final parts = normalized.split(',');

      for (final part in parts) {
        final parsed = part.trim();

        if (parsed.isNotEmpty && !result.contains(parsed)) {
          result.add(parsed);
        }
      }

      return result;
    }

    return <String>[];
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        return null;
      }

      return DateTime.tryParse(normalized);
    }

    if (value is int) {
      return _dateTimeFromNumber(value);
    }

    if (value is double) {
      return _dateTimeFromNumber(value.toInt());
    }

    if (value is num) {
      return _dateTimeFromNumber(value.toInt());
    }

    return null;
  }

  static DateTime? _dateTimeFromNumber(int value) {
    if (value <= 0) {
      return null;
    }

    final isSecondsTimestamp = value < 1000000000000;

    if (isSecondsTimestamp) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }

    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  static const Set<String> _trueValues = {
    'true',
    '1',
    's',
    'sim',
    'ativo',
    'ativa',
    'active',
    'yes',
    'y',
  };

  static const Set<String> _falseValues = {
    'false',
    '0',
    'n',
    'nao',
    'não',
    'inativo',
    'inativa',
    'inactive',
    'no',
  };

  @override
  String toString() {
    return 'CalculadoraItemBaseModel('
        'id: $id, '
        'nome: $nome, '
        'descricao: $descricao, '
        'categoriaPadrao: $categoriaPadrao, '
        'tipoItem: $tipoItem, '
        'unidadePadrao: $unidadePadrao, '
        'publicoAlvo: $publicoAlvo, '
        'ativo: $ativo, '
        'ordem: $ordem, '
        'icone: $icone, '
        'tags: $tags, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is CalculadoraItemBaseModel &&
        other.id == id &&
        other.nome == nome &&
        other.descricao == descricao &&
        other.categoriaPadrao == categoriaPadrao &&
        other.tipoItem == tipoItem &&
        other.unidadePadrao == unidadePadrao &&
        other.publicoAlvo == publicoAlvo &&
        other.ativo == ativo &&
        other.ordem == ordem &&
        other.icone == icone &&
        _listEquals(other.tags, tags) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nome,
      descricao,
      categoriaPadrao,
      tipoItem,
      unidadePadrao,
      publicoAlvo,
      ativo,
      ordem,
      icone,
      Object.hashAll(tags),
      createdAt,
      updatedAt,
    );
  }

  static bool _listEquals(
    List<String> first,
    List<String> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
