class SugestaoBaseFesta {
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
  final int versao;
  final String origem;
  final String revisadoPor;
  final DateTime? dataRevisao;
  final DateTime? dataPublicacao;
  final String statusRevisao;
  final String observacaoRevisao;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SugestaoBaseFesta({
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

  factory SugestaoBaseFesta.empty() {
    return const SugestaoBaseFesta(
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

  SugestaoBaseFesta copyWith({
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
    return SugestaoBaseFesta(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      modulo: modulo ?? this.modulo,
      tema: tema ?? this.tema,
      tipoEvento: tipoEvento ?? List<String>.from(this.tipoEvento),
      perfisFesta: perfisFesta ?? List<String>.from(this.perfisFesta),
      categoria: categoria ?? this.categoria,
      prioridade: prioridade ?? this.prioridade,
      gatilhos: gatilhos ?? Map<String, dynamic>.from(this.gatilhos),
      tags: tags ?? List<String>.from(this.tags),
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

  bool get isCritica => prioridade == 'critica';

  bool get isAlta => prioridade == 'alta';

  bool get isAprovada => statusRevisao == 'aprovada';

  bool get isPendente => statusRevisao == 'pendente';

  bool get isReprovada => statusRevisao == 'reprovada';

  bool get isArquivada => statusRevisao == 'arquivada';

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

  static String normalizeToken(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  bool get isCalculadora => modulo == 'calculadora';

  bool get prioridadeAlta {
    return prioridade == 'alta' || prioridade == 'critica';
  }

  bool aceitaTipoEvento(String? tipo) {
    final normalized = normalizeToken(tipo ?? '');
    return normalized.isEmpty ||
        tipoEvento.isEmpty ||
        tipoEvento.contains(normalized) ||
        tipoEvento.contains('todos');
  }

  bool aceitaPerfilFesta(String? perfil) {
    final normalized = normalizeToken(perfil ?? '');
    return normalized.isEmpty ||
        perfisFesta.isEmpty ||
        perfisFesta.contains(normalized) ||
        perfisFesta.contains('todos');
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
}
