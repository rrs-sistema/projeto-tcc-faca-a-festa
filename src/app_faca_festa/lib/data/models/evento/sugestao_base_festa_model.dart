import 'package:cloud_firestore/cloud_firestore.dart';

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

class SugestaoBaseFestaModel {
  final String id;
  final String titulo;
  final String descricao;
  final String modulo;
  final String tema;
  final List<String> tipoEvento;
  final List<String> perfisFesta;
  final String categoria;
  final String prioridade;
  final Map<String, dynamic> gatilhos;
  final List<String> tags;
  final bool ativo;
  final bool excluido;
  final int ordem;

  /// Versão editorial da sugestão base.
  ///
  /// Sempre que o conteúdo/gatilhos da sugestão mudar de forma relevante,
  /// incremente esta versão para preservar rastreabilidade das análises antigas.
  final int versao;

  /// Origem do cadastro: seed_inicial, admin, importacao, migracao, etc.
  final String origem;

  /// Usuário, papel ou identificador de quem revisou/aprovou a sugestão.
  final String revisadoPor;

  final DateTime? dataRevisao;
  final DateTime? dataPublicacao;

  /// Status editorial da sugestão.
  ///
  /// Apenas sugestões aprovadas devem ser usadas como contexto da IA.
  final String statusRevisao;
  final String observacaoRevisao;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SugestaoBaseFestaModel({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.modulo,
    required this.tema,
    required this.tipoEvento,
    required this.perfisFesta,
    required this.categoria,
    required this.prioridade,
    required this.gatilhos,
    required this.tags,
    required this.ativo,
    this.excluido = false,
    required this.ordem,
    this.versao = 1,
    this.origem = 'manual',
    this.revisadoPor = '',
    this.dataRevisao,
    this.dataPublicacao,
    this.statusRevisao = 'aprovada',
    this.observacaoRevisao = '',
    this.createdAt,
    this.updatedAt,
  });

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
      gatilhos: <String, dynamic>{},
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
      gatilhos: _asMap(map['gatilhos']),
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
      'gatilhos': gatilhos,
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
      'gatilhos': gatilhos,
      'tags': tags,
      'ordem': ordem,
      'origem': origem,
      'status_revisao': statusRevisao,
      'data_publicacao': dataPublicacao?.toIso8601String(),
    };
  }

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
    Map<String, dynamic>? gatilhos,
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

  bool get isNew => id.trim().isEmpty;
  bool get isInactive => !ativo;
  bool get isCritica => prioridade == PrioridadeSugestaoIA.critica.value;
  bool get isAlta => prioridade == PrioridadeSugestaoIA.alta.value;
  bool get isAprovada =>
      statusRevisao == StatusRevisaoSugestaoIA.aprovada.value;
  bool get isPendente =>
      statusRevisao == StatusRevisaoSugestaoIA.pendente.value;
  bool get isReprovada =>
      statusRevisao == StatusRevisaoSugestaoIA.reprovada.value;
  bool get isArquivada =>
      statusRevisao == StatusRevisaoSugestaoIA.arquivada.value;
  bool get possuiRevisao =>
      revisadoPor.trim().isNotEmpty || dataRevisao != null;
  bool get possuiPublicacao => dataPublicacao != null;
  bool get possuiObservacaoRevisao => observacaoRevisao.trim().isNotEmpty;

  bool get podeSerUsadaComoContextoIA {
    return ativo && !excluido && isAprovada;
  }

  String get tipoEventoLabel =>
      tipoEvento.isEmpty ? 'todos' : tipoEvento.join(', ');
  String get perfisFestaLabel =>
      perfisFesta.isEmpty ? 'todos' : perfisFesta.join(', ');
  String get tagsLabel => tags.join(', ');
  String get versaoLabel => 'v$versao';
  String get rastreioLabel => '$id@$versaoLabel';

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

  bool get isCalculadora => modulo == ModuloSugestaoIA.calculadora.value;

  bool get prioridadeAlta {
    return prioridade == PrioridadeSugestaoIA.alta.value ||
        prioridade == PrioridadeSugestaoIA.critica.value;
  }

  bool aceitaTipoEvento(String? tipo) {
    final normalized = _normalizeToken(tipo ?? '');
    return normalized.isEmpty ||
        tipoEvento.isEmpty ||
        tipoEvento.contains(normalized) ||
        tipoEvento.contains('todos');
  }

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
