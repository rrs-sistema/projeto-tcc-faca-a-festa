import 'package:cloud_firestore/cloud_firestore.dart';

class InspiracaoModel {
  final String id;
  final String tipoEventoId;
  final String tipoEvento;
  final String tipoEventoNormalizado;
  final String titulo;
  final String descricao;
  final String imagemUrl;
  final List<String> tags;
  final List<String> galeriaUrls;
  final List<String> paletaCores;
  final String? categoriaId;
  final String? categoria;
  final List<String> fornecedoresRelacionados;
  final List<String> categoriasFornecedorSugeridas;
  final List<Map<String, dynamic>> tarefasSugeridas;
  final List<Map<String, dynamic>> itensOrcamentoSugeridos;
  final String estilo;
  final String faixaCusto;
  final String nivelDificuldade;
  final bool destaque;
  final bool ativo;
  final bool favorito;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  InspiracaoModel({
    required this.id,
    this.tipoEventoId = '',
    this.tipoEvento = '',
    this.tipoEventoNormalizado = '',
    required this.titulo,
    required this.descricao,
    required this.imagemUrl,
    this.tags = const [],
    this.galeriaUrls = const [],
    this.paletaCores = const [],
    this.categoriaId,
    this.categoria,
    this.fornecedoresRelacionados = const [],
    this.categoriasFornecedorSugeridas = const [],
    this.tarefasSugeridas = const [],
    this.itensOrcamentoSugeridos = const [],
    this.estilo = '',
    this.faixaCusto = '',
    this.nivelDificuldade = '',
    this.destaque = false,
    this.ativo = true,
    this.favorito = false,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory InspiracaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    return InspiracaoModel(
      id: _asString(data['id']).isNotEmpty ? _asString(data['id']) : doc.id,
      tipoEventoId:
          _asString(data['tipoEventoId'] ?? data['idTipoEvento'] ?? data['id_tipo_evento']),
      tipoEvento: _asString(data['tipoEvento'] ?? data['tipo_evento']),
      tipoEventoNormalizado:
          _asString(data['tipoEventoNormalizado'] ?? data['tipo_evento_normalizado']),
      titulo: _asString(data['titulo']),
      descricao: _asString(data['descricao']),
      imagemUrl: _asString(data['imagemUrl'] ?? data['imagem_url']),
      tags: _asStringList(data['tags']),
      galeriaUrls: _asStringList(data['galeriaUrls'] ?? data['galeria_urls']),
      paletaCores: _asStringList(data['paletaCores'] ?? data['paleta_cores']),
      categoriaId: _asString(data['categoriaId'] ?? data['idCategoria'] ?? data['categoria_id']),
      categoria: _asString(data['categoria']),
      fornecedoresRelacionados: _asStringList(data['fornecedoresRelacionados']),
      categoriasFornecedorSugeridas: _asStringList(data['categoriasFornecedorSugeridas']),
      tarefasSugeridas: _asMapList(data['tarefasSugeridas']),
      itensOrcamentoSugeridos: _asMapList(data['itensOrcamentoSugeridos']),
      estilo: _asString(data['estilo']),
      faixaCusto: _asString(data['faixaCusto']),
      nivelDificuldade: _asString(data['nivelDificuldade']),
      destaque: data['destaque'] == true,
      ativo: data['ativo'] != false && data['deletado'] != true,
      favorito: data['favorito'] == true,
      criadoEm: _asDateTime(data['criadoEm'] ?? data['dataCriacao'] ?? data['data_criacao']),
      atualizadoEm: _asDateTime(data['atualizadoEm'] ?? data['dataAtualizacao']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'tipoEventoId': tipoEventoId,
      'tipoEvento': tipoEvento,
      'tipoEventoNormalizado': tipoEventoNormalizado,
      'titulo': titulo,
      'descricao': descricao,
      'imagemUrl': imagemUrl,
      'tags': tags,
      'galeriaUrls': galeriaUrls,
      'paletaCores': paletaCores,
      'categoriaId': categoriaId ?? '',
      'categoria': categoria ?? '',
      'fornecedoresRelacionados': fornecedoresRelacionados,
      'categoriasFornecedorSugeridas': categoriasFornecedorSugeridas,
      'tarefasSugeridas': tarefasSugeridas,
      'itensOrcamentoSugeridos': itensOrcamentoSugeridos,
      'estilo': estilo,
      'faixaCusto': faixaCusto,
      'nivelDificuldade': nivelDificuldade,
      'destaque': destaque,
      'ativo': ativo,
      'favorito': favorito,
      'criadoEm': criadoEm == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(criadoEm!),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toReferenciaEventoMap({
    required String eventoId,
    required String userId,
    bool favorito = false,
    String status = 'salva',
    String prioridade = 'media',
    String anotacao = '',
    String origem = 'inspiracao_app',
  }) {
    return {
      'eventoId': eventoId,
      'idEvento': eventoId,
      'userId': userId,
      'idUsuario': userId,
      'inspiracaoId': id,
      'titulo': titulo,
      'descricao': descricao,
      'imagemUrl': imagemUrl,
      'categoriaId': categoriaId ?? '',
      'categoria': categoria ?? '',
      'tags': tags,
      'galeriaUrls': galeriaUrls,
      'paletaCores': paletaCores,
      'estilo': estilo,
      'faixaCusto': faixaCusto,
      'nivelDificuldade': nivelDificuldade,
      'fornecedoresRelacionados': fornecedoresRelacionados,
      'categoriasFornecedorSugeridas': categoriasFornecedorSugeridas,
      'tarefasSugeridas': tarefasSugeridas,
      'itensOrcamentoSugeridos': itensOrcamentoSugeridos,
      'favorito': favorito,
      'status': status,
      'prioridade': prioridade,
      'anotacao': anotacao,
      'origem': origem,
      'ativo': true,
      'deletado': false,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    };
  }

  InspiracaoModel copyWith({
    String? id,
    String? tipoEventoId,
    String? tipoEvento,
    String? tipoEventoNormalizado,
    String? titulo,
    String? descricao,
    String? imagemUrl,
    List<String>? tags,
    List<String>? galeriaUrls,
    List<String>? paletaCores,
    String? categoriaId,
    String? categoria,
    List<String>? fornecedoresRelacionados,
    List<String>? categoriasFornecedorSugeridas,
    List<Map<String, dynamic>>? tarefasSugeridas,
    List<Map<String, dynamic>>? itensOrcamentoSugeridos,
    String? estilo,
    String? faixaCusto,
    String? nivelDificuldade,
    bool? destaque,
    bool? ativo,
    bool? favorito,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return InspiracaoModel(
      id: id ?? this.id,
      tipoEventoId: tipoEventoId ?? this.tipoEventoId,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      tipoEventoNormalizado: tipoEventoNormalizado ?? this.tipoEventoNormalizado,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      tags: tags ?? this.tags,
      galeriaUrls: galeriaUrls ?? this.galeriaUrls,
      paletaCores: paletaCores ?? this.paletaCores,
      categoriaId: categoriaId ?? this.categoriaId,
      categoria: categoria ?? this.categoria,
      fornecedoresRelacionados: fornecedoresRelacionados ?? this.fornecedoresRelacionados,
      categoriasFornecedorSugeridas:
          categoriasFornecedorSugeridas ?? this.categoriasFornecedorSugeridas,
      tarefasSugeridas: tarefasSugeridas ?? this.tarefasSugeridas,
      itensOrcamentoSugeridos: itensOrcamentoSugeridos ?? this.itensOrcamentoSugeridos,
      estilo: estilo ?? this.estilo,
      faixaCusto: faixaCusto ?? this.faixaCusto,
      nivelDificuldade: nivelDificuldade ?? this.nivelDificuldade,
      destaque: destaque ?? this.destaque,
      ativo: ativo ?? this.ativo,
      favorito: favorito ?? this.favorito,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return <String>[];
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value == null) return <Map<String, dynamic>>[];
    if (value is List) {
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class ReferenciaEventoModel {
  final String id;
  final String eventoId;
  final String userId;
  final String inspiracaoId;
  final String titulo;
  final String descricao;
  final String imagemUrl;
  final String categoriaId;
  final String categoria;
  final List<String> tags;
  final List<String> galeriaUrls;
  final List<String> paletaCores;
  final bool favorito;
  final String status;
  final String prioridade;
  final String origem;
  final String anotacao;
  final bool ativo;
  final bool deletado;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  ReferenciaEventoModel({
    required this.id,
    required this.eventoId,
    required this.userId,
    required this.inspiracaoId,
    required this.titulo,
    required this.descricao,
    required this.imagemUrl,
    required this.categoriaId,
    required this.categoria,
    required this.tags,
    required this.galeriaUrls,
    required this.paletaCores,
    required this.favorito,
    required this.status,
    required this.prioridade,
    required this.origem,
    required this.anotacao,
    required this.ativo,
    required this.deletado,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory ReferenciaEventoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return ReferenciaEventoModel(
      id: _asString(data['id']).isNotEmpty ? _asString(data['id']) : doc.id,
      eventoId: _asString(data['eventoId'] ?? data['idEvento']),
      userId: _asString(data['userId'] ?? data['idUsuario']),
      inspiracaoId: _asString(data['inspiracaoId']),
      titulo:
          _asString(data['titulo']).isEmpty ? 'Referência sem título' : _asString(data['titulo']),
      descricao: _asString(data['descricao']),
      imagemUrl: _asString(data['imagemUrl']),
      categoriaId: _asString(data['categoriaId']),
      categoria:
          _asString(data['categoria']).isEmpty ? 'Sem categoria' : _asString(data['categoria']),
      tags: _asStringList(data['tags']),
      galeriaUrls: _asStringList(data['galeriaUrls']),
      paletaCores: _asStringList(data['paletaCores']),
      favorito: data['favorito'] == true,
      status: _asString(data['status']).isEmpty ? 'salva' : _asString(data['status']),
      prioridade: _asString(data['prioridade']).isEmpty ? 'media' : _asString(data['prioridade']),
      origem: _asString(data['origem']).isEmpty ? 'manual' : _asString(data['origem']),
      anotacao: _asString(data['anotacao']),
      ativo: data['ativo'] != false,
      deletado: data['deletado'] == true,
      criadoEm: _asDateTime(data['criadoEm']),
      atualizadoEm: _asDateTime(data['atualizadoEm']),
    );
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static List<String> _asStringList(dynamic value) {
    if (value == null) return <String>[];
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return <String>[];
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
