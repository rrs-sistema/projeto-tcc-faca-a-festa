import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/gatilhos_sugestao_base_festa.dart';
import 'package:app_faca_festa/domain/entities/sugestao_base_festa.dart';


enum ModuloSugestaoIA {
  calculadora('calculadora'),
  orcamento('orcamento'),
  convidados('convidados'),
  fornecedores('fornecedores'),
  checklist('checklist'),
  espacoConvidados('espaco_convidados'),
  referencias('referencias'),
  cardapio('cardapio'),
  decoracao('decoracao'),
  presentes('presentes');

  const ModuloSugestaoIA(this.value);
  final String value;

  static ModuloSugestaoIA? fromValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final item in ModuloSugestaoIA.values) {
      if (item.value == normalized) return item;
    }
    return null;
  }
}

enum CategoriaSugestaoIA {
  alerta('alerta'),
  economia('economia'),
  consumo('consumo'),
  financeiro('financeiro'),
  organizacao('organizacao'),
  fornecedor('fornecedor'),
  cardapio('cardapio'),
  decoracao('decoracao'),
  experiencia('experiencia'),
  geral('geral');

  const CategoriaSugestaoIA(this.value);
  final String value;

  static CategoriaSugestaoIA? fromValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final item in CategoriaSugestaoIA.values) {
      if (item.value == normalized) return item;
    }
    return null;
  }
}

enum PrioridadeSugestaoIA {
  baixa('baixa'),
  media('media'),
  alta('alta'),
  critica('critica');

  const PrioridadeSugestaoIA(this.value);
  final String value;

  static PrioridadeSugestaoIA? fromValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase();
    for (final item in PrioridadeSugestaoIA.values) {
      if (item.value == normalized) return item;
    }
    return null;
  }
}

enum StatusRevisaoSugestaoIA {
  rascunho('rascunho'),
  pendente('pendente'),
  aprovada('aprovada'),
  reprovada('reprovada'),
  arquivada('arquivada');

  const StatusRevisaoSugestaoIA(this.value);
  final String value;

  static StatusRevisaoSugestaoIA? fromValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = SugestaoBaseFestaModel.normalizeToken(value);
    for (final item in StatusRevisaoSugestaoIA.values) {
      if (item.value == normalized) return item;
    }
    return null;
  }
}

class SugestaoBaseFestaModel extends SugestaoBaseFesta {
  const SugestaoBaseFestaModel({
    required super.id,
    required super.titulo,
    required super.descricao,
    required super.modulo,
    required super.tema,
    required super.tipoEvento,
    required super.perfisFesta,
    required super.categoria,
    required super.prioridade,
    required super.gatilhos,
    required super.tags,
    required super.ativo,
    super.excluido = false,
    required super.ordem,
    super.versao = 1,
    super.origem = 'manual',
    super.revisadoPor = '',
    super.dataRevisao,
    super.dataPublicacao,
    super.statusRevisao = 'aprovada',
    super.observacaoRevisao = '',
    super.createdAt,
    super.updatedAt,
  });

  factory SugestaoBaseFestaModel.fromEntity(SugestaoBaseFesta entity) {
    if (entity is SugestaoBaseFestaModel) {
      return entity;
    }

    return SugestaoBaseFestaModel(
      id: entity.id,
      titulo: entity.titulo,
      descricao: entity.descricao,
      modulo: entity.modulo,
      tema: entity.tema,
      tipoEvento: List<String>.from(entity.tipoEvento),
      perfisFesta: List<String>.from(entity.perfisFesta),
      categoria: entity.categoria,
      prioridade: entity.prioridade,
      gatilhos: entity.gatilhos,
      tags: List<String>.from(entity.tags),
      ativo: entity.ativo,
      excluido: entity.excluido,
      ordem: entity.ordem,
      versao: entity.versao,
      origem: entity.origem,
      revisadoPor: entity.revisadoPor,
      dataRevisao: entity.dataRevisao,
      dataPublicacao: entity.dataPublicacao,
      statusRevisao: entity.statusRevisao,
      observacaoRevisao: entity.observacaoRevisao,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory SugestaoBaseFestaModel.empty() {
    return const SugestaoBaseFestaModel(
      id: '',
      titulo: '',
      descricao: '',
      modulo: '',
      tema: '',
      tipoEvento: <String>[],
      perfisFesta: <String>[],
      categoria: 'geral',
      prioridade: 'media',
      gatilhos: GatilhosSugestaoBaseFesta.empty,
      tags: <String>[],
      ativo: true,
      excluido: false,
      ordem: 0,
      versao: 1,
      origem: 'manual',
      revisadoPor: '',
      statusRevisao: 'aprovada',
      observacaoRevisao: '',
    );
  }

  factory SugestaoBaseFestaModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return SugestaoBaseFestaModel.fromMap(
      doc.data() ?? const <String, dynamic>{},
      idFallback: doc.id,
    );
  }

  factory SugestaoBaseFestaModel.fromMap(
    Map<String, dynamic> map, {
    String? idFallback,
  }) {
    return SugestaoBaseFestaModel(
      id: _asString(map['id'], fallback: idFallback ?? ''),
      titulo: _asString(map['titulo']),
      descricao: _asString(map['descricao']),
      modulo: _normalizeToken(_asString(map['modulo'])),
      tema: _normalizeToken(_asString(map['tema'])),
      tipoEvento: _asStringList(map['tipo_evento'] ?? map['tipoEvento']),
      perfisFesta: _asStringList(map['perfis_festa'] ?? map['perfisFesta']),
      categoria: _normalizeToken(
        _asString(map['categoria'], fallback: CategoriaSugestaoIA.geral.value),
      ),
      prioridade: _normalizeToken(
        _asString(map['prioridade'],
            fallback: PrioridadeSugestaoIA.media.value),
      ),
      gatilhos: GatilhosSugestaoBaseFesta.fromMap(_asMap(map['gatilhos'])),
      tags: _asStringList(map['tags']),
      ativo: _asBool(map['ativo'], fallback: true),
      excluido: _asBool(
        map['excluido'] ?? map['deleted'] ?? map['deletado'],
        fallback: false,
      ),
      ordem: _asInt(map['ordem']),
      versao: _asInt(map['versao'] ?? map['version'], fallback: 1),
      origem: _asString(map['origem'] ?? map['source'], fallback: 'legado'),
      revisadoPor: _asString(
        map['revisado_por'] ?? map['revisadoPor'] ?? map['reviewed_by'],
      ),
      dataRevisao: _asDateTime(
        map['data_revisao'] ?? map['dataRevisao'] ?? map['reviewed_at'],
      ),
      dataPublicacao: _asDateTime(
        map['data_publicacao'] ?? map['dataPublicacao'] ?? map['published_at'],
      ),
      statusRevisao: _normalizeToken(
        _asString(
          map['status_revisao'] ?? map['statusRevisao'] ?? map['review_status'],
          fallback: StatusRevisaoSugestaoIA.aprovada.value,
        ),
      ),
      observacaoRevisao: _asString(
        map['observacao_revisao'] ??
            map['observacaoRevisao'] ??
            map['review_note'],
      ),
      createdAt: _asDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: _asDateTime(map['updated_at'] ?? map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool includeDates = false}) {
    return <String, dynamic>{
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'modulo': modulo,
      'tema': tema,
      'tipo_evento': tipoEvento,
      'perfis_festa': perfisFesta,
      'categoria': categoria,
      'prioridade': prioridade,
      'gatilhos': gatilhos.toMap(),
      'tags': tags,
      'ativo': ativo,
      'excluido': excluido,
      'ordem': ordem,
      'versao': versao,
      'origem': origem,
      'revisado_por': revisadoPor,
      'data_revisao':
          _dateOrServerTimestamp(dataRevisao, includeDates: includeDates),
      'data_publicacao': _dateOrServerTimestamp(
        dataPublicacao,
        includeDates: includeDates,
      ),
      'status_revisao': statusRevisao,
      'observacao_revisao': observacaoRevisao,
      'created_at': includeDates && createdAt == null
          ? FieldValue.serverTimestamp()
          : createdAt,
      'updated_at': includeDates ? FieldValue.serverTimestamp() : updatedAt,
    };
  }

  @override
  Map<String, dynamic> toContextMap() {
    return <String, dynamic>{
      'id': id,
      'versao': versao,
      'titulo': titulo,
      'descricao': descricao,
      'modulo': modulo,
      'tema': tema,
      'tipo_evento': tipoEvento,
      'perfis_festa': perfisFesta,
      'categoria': categoria,
      'prioridade': prioridade,
      'gatilhos': gatilhos.toMap(),
      'tags': tags,
      'ordem': ordem,
      'origem': origem,
      'status_revisao': statusRevisao,
      'data_publicacao': dataPublicacao?.toIso8601String(),
    };
  }

  @override
  SugestaoBaseFestaModel copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? modulo,
    String? tema,
    List<String>? tipoEvento,
    List<String>? perfisFesta,
    String? categoria,
    String? prioridade,
    GatilhosSugestaoBaseFesta? gatilhos,
    List<String>? tags,
    bool? ativo,
    bool? excluido,
    int? ordem,
    int? versao,
    String? origem,
    String? revisadoPor,
    DateTime? dataRevisao,
    bool limparDataRevisao = false,
    DateTime? dataPublicacao,
    bool limparDataPublicacao = false,
    String? statusRevisao,
    String? observacaoRevisao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SugestaoBaseFestaModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      modulo: modulo ?? this.modulo,
      tema: tema ?? this.tema,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      perfisFesta: perfisFesta ?? this.perfisFesta,
      categoria: categoria ?? this.categoria,
      prioridade: prioridade ?? this.prioridade,
      gatilhos: gatilhos ?? this.gatilhos,
      tags: tags ?? this.tags,
      ativo: ativo ?? this.ativo,
      excluido: excluido ?? this.excluido,
      ordem: ordem ?? this.ordem,
      versao: versao ?? this.versao,
      origem: origem ?? this.origem,
      revisadoPor: revisadoPor ?? this.revisadoPor,
      dataRevisao: limparDataRevisao ? null : (dataRevisao ?? this.dataRevisao),
      dataPublicacao:
          limparDataPublicacao ? null : (dataPublicacao ?? this.dataPublicacao),
      statusRevisao: statusRevisao ?? this.statusRevisao,
      observacaoRevisao: observacaoRevisao ?? this.observacaoRevisao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool get isNew => id.trim().isEmpty;
  @override
  bool get isInactive => !ativo;
  @override
  bool get isCritica => prioridade == PrioridadeSugestaoIA.critica.value;
  @override
  bool get isAlta => prioridade == PrioridadeSugestaoIA.alta.value;
  @override
  bool get isAprovada =>
      statusRevisao == StatusRevisaoSugestaoIA.aprovada.value;
  @override
  bool get isPendente =>
      statusRevisao == StatusRevisaoSugestaoIA.pendente.value;
  @override
  bool get isReprovada =>
      statusRevisao == StatusRevisaoSugestaoIA.reprovada.value;
  @override
  bool get isArquivada =>
      statusRevisao == StatusRevisaoSugestaoIA.arquivada.value;
  @override
  bool get possuiRevisao =>
      revisadoPor.trim().isNotEmpty || dataRevisao != null;
  @override
  bool get possuiPublicacao => dataPublicacao != null;
  @override
  bool get possuiObservacaoRevisao => observacaoRevisao.trim().isNotEmpty;

  @override
  bool get podeSerUsadaComoContextoIA {
    return ativo && !excluido && isAprovada;
  }

  @override
  String get tipoEventoLabel =>
      tipoEvento.isEmpty ? 'todos' : tipoEvento.join(', ');
  @override
  String get perfisFestaLabel =>
      perfisFesta.isEmpty ? 'todos' : perfisFesta.join(', ');
  @override
  String get tagsLabel => tags.join(', ');
  @override
  String get versaoLabel => 'v$versao';
  @override
  String get rastreioLabel => '$id@$versaoLabel';

  @override
  String get statusRevisaoLabel {
    switch (statusRevisao) {
      case 'rascunho':
        return 'Rascunho';
      case 'pendente':
        return 'Pendente';
      case 'aprovada':
        return 'Aprovada';
      case 'reprovada':
        return 'Reprovada';
      case 'arquivada':
        return 'Arquivada';
      default:
        return statusRevisao;
    }
  }

  static String normalizeToken(String value) => _normalizeToken(value);

  @override
  bool get isCalculadora => modulo == ModuloSugestaoIA.calculadora.value;

  @override
  bool get prioridadeAlta {
    return prioridade == PrioridadeSugestaoIA.alta.value ||
        prioridade == PrioridadeSugestaoIA.critica.value;
  }

  @override
  bool aceitaTipoEvento(String? tipo) {
    final normalized = _normalizeToken(tipo ?? '');
    return normalized.isEmpty ||
        tipoEvento.isEmpty ||
        tipoEvento.contains(normalized) ||
        tipoEvento.contains('todos');
  }

  @override
  bool aceitaPerfilFesta(String? perfil) {
    final normalized = _normalizeToken(perfil ?? '');
    return normalized.isEmpty ||
        perfisFesta.isEmpty ||
        perfisFesta.contains(normalized) ||
        perfisFesta.contains('todos');
  }

  static dynamic _dateOrServerTimestamp(
    DateTime? date, {
    required bool includeDates,
  }) {
    if (date != null) return date;
    return includeDates ? FieldValue.serverTimestamp() : null;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString().trim();
  }

  static String _normalizeToken(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (<String>['true', '1', 'sim', 's', 'yes'].contains(normalized)) {
        return true;
      }
      if (<String>['false', '0', 'nao', 'não', 'n', 'no']
          .contains(normalized)) {
        return false;
      }
    }
    return fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is Iterable) {
      return value
          .map((item) => _normalizeToken(item?.toString() ?? ''))
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map(_normalizeToken)
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }
    return <String>[];
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value == null) return <String, dynamic>{};
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return <String, dynamic>{};
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
