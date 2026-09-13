import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/inspiracao.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_sugestao.dart';
import 'package:app_faca_festa/domain/entities/referencia_evento.dart';


class InspiracaoModel extends Inspiracao {
  InspiracaoModel({
    required super.id,
    super.tipoEventoId = '',
    super.tipoEvento = '',
    super.tipoEventoNormalizado = '',
    super.tipoEventoIds = const [],
    super.tipoEventoSlugs = const [],
    super.tipoEventoNomes = const [],
    required super.titulo,
    required super.descricao,
    required super.imagemUrl,
    super.tags = const [],
    super.galeriaUrls = const [],
    super.paletaCores = const [],
    super.categoriaId,
    super.categoria,
    super.fornecedoresRelacionados = const [],
    super.categoriasFornecedorSugeridas = const [],
    super.tarefasSugeridas = const [],
    super.itensOrcamentoSugeridos = const [],
    super.estilo = '',
    super.faixaCusto = '',
    super.nivelDificuldade = '',
    super.destaque = false,
    super.ativo = true,
    super.publicado = true,
    super.deletado = false,
    super.ordem = 0,
    super.favorito = false,
    super.criadoEm,
    super.atualizadoEm,
  });

  factory InspiracaoModel.fromEntity(Inspiracao entity) {
    if (entity is InspiracaoModel) return entity;

    return InspiracaoModel(
      id: entity.id,
      tipoEventoId: entity.tipoEventoId,
      tipoEvento: entity.tipoEvento,
      tipoEventoNormalizado: entity.tipoEventoNormalizado,
      tipoEventoIds: List<String>.from(entity.tipoEventoIds),
      tipoEventoSlugs: List<String>.from(entity.tipoEventoSlugs),
      tipoEventoNomes: List<String>.from(entity.tipoEventoNomes),
      titulo: entity.titulo,
      descricao: entity.descricao,
      imagemUrl: entity.imagemUrl,
      tags: List<String>.from(entity.tags),
      galeriaUrls: List<String>.from(entity.galeriaUrls),
      paletaCores: List<String>.from(entity.paletaCores),
      categoriaId: entity.categoriaId,
      categoria: entity.categoria,
      fornecedoresRelacionados:
          List<String>.from(entity.fornecedoresRelacionados),
      categoriasFornecedorSugeridas:
          List<String>.from(entity.categoriasFornecedorSugeridas),
      tarefasSugeridas:
          List<TarefaInspiracaoSugerida>.from(entity.tarefasSugeridas),
      itensOrcamentoSugeridos: List<ItemOrcamentoInspiracaoSugerido>.from(
        entity.itensOrcamentoSugeridos,
      ),
      estilo: entity.estilo,
      faixaCusto: entity.faixaCusto,
      nivelDificuldade: entity.nivelDificuldade,
      destaque: entity.destaque,
      ativo: entity.ativo,
      publicado: entity.publicado,
      deletado: entity.deletado,
      ordem: entity.ordem,
      favorito: entity.favorito,
      criadoEm: entity.criadoEm,
      atualizadoEm: entity.atualizadoEm,
    );
  }

  factory InspiracaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    return InspiracaoModel.fromMap(data, documentId: doc.id);
  }

  factory InspiracaoModel.fromMap(
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    return InspiracaoModel(
      id: _asString(data['id']).isNotEmpty
          ? _asString(data['id'])
          : (documentId ?? ''),
      tipoEventoId: _asString(data['tipoEventoId'] ??
          data['idTipoEvento'] ??
          data['id_tipo_evento']),
      tipoEvento: _asString(data['tipoEvento'] ?? data['tipo_evento']),
      tipoEventoNormalizado: _asString(
          data['tipoEventoNormalizado'] ?? data['tipo_evento_normalizado']),
      tipoEventoIds: _asStringList(data['tipoEventoIds']),
      tipoEventoSlugs: _asStringListWithExtras(
        data['tipoEventoSlugs'],
        extras: [data['tipoEventoSlug']],
      ),
      tipoEventoNomes: _asStringListWithExtras(
        data['tipoEventoNomes'],
        extras: [data['tipoEventoNome']],
      ),
      titulo: _asString(data['titulo']),
      descricao: _asString(data['descricao']),
      imagemUrl: _asString(data['imagemUrl'] ?? data['imagem_url']),
      tags: _asStringList(data['tags']),
      galeriaUrls: _asStringList(data['galeriaUrls'] ?? data['galeria_urls']),
      paletaCores: _asStringList(data['paletaCores'] ?? data['paleta_cores']),
      categoriaId: _asString(
          data['categoriaId'] ?? data['idCategoria'] ?? data['categoria_id']),
      categoria: _asString(data['categoria']),
      fornecedoresRelacionados: _asStringList(data['fornecedoresRelacionados']),
      categoriasFornecedorSugeridas:
          _asStringList(data['categoriasFornecedorSugeridas']),
      tarefasSugeridas: _asTarefas(data['tarefasSugeridas']),
      itensOrcamentoSugeridos:
          _asItensOrcamento(data['itensOrcamentoSugeridos']),
      estilo: _asString(data['estilo']),
      faixaCusto: _asString(data['faixaCusto']),
      nivelDificuldade: _asString(data['nivelDificuldade']),
      destaque: data['destaque'] == true,
      ativo: data['ativo'] != false && data['deletado'] != true,
      publicado: data['publicado'] != false,
      deletado: data['deletado'] == true || data['deleted'] == true,
      ordem: _asInt(data['ordem']),
      favorito: data['favorito'] == true,
      criadoEm: _asDateTime(
          data['criadoEm'] ?? data['dataCriacao'] ?? data['data_criacao']),
      atualizadoEm:
          _asDateTime(data['atualizadoEm'] ?? data['dataAtualizacao']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'tipoEventoId': tipoEventoId,
      'tipoEvento': tipoEvento,
      'tipoEventoNormalizado': tipoEventoNormalizado,
      'tipoEventoIds': tipoEventoIds,
      'tipoEventoSlugs': tipoEventoSlugs,
      'tipoEventoNomes': tipoEventoNomes,
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
      'tarefasSugeridas': tarefasSugeridas.map(_tarefaToMap).toList(),
      'itensOrcamentoSugeridos':
          itensOrcamentoSugeridos.map(_itemOrcamentoToMap).toList(),
      'estilo': estilo,
      'faixaCusto': faixaCusto,
      'nivelDificuldade': nivelDificuldade,
      'destaque': destaque,
      'ativo': ativo,
      'publicado': publicado,
      'deletado': deletado,
      'ordem': ordem,
      'favorito': favorito,
      'criadoEm': criadoEm == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(criadoEm!),
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
      'tarefasSugeridas': tarefasSugeridas.map(_tarefaToMap).toList(),
      'itensOrcamentoSugeridos':
          itensOrcamentoSugeridos.map(_itemOrcamentoToMap).toList(),
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

  @override
  InspiracaoModel copyWith({
    String? id,
    String? tipoEventoId,
    String? tipoEvento,
    String? tipoEventoNormalizado,
    List<String>? tipoEventoIds,
    List<String>? tipoEventoSlugs,
    List<String>? tipoEventoNomes,
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
    List<TarefaInspiracaoSugerida>? tarefasSugeridas,
    List<ItemOrcamentoInspiracaoSugerido>? itensOrcamentoSugeridos,
    String? estilo,
    String? faixaCusto,
    String? nivelDificuldade,
    bool? destaque,
    bool? ativo,
    bool? publicado,
    bool? deletado,
    int? ordem,
    bool? favorito,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return InspiracaoModel(
      id: id ?? this.id,
      tipoEventoId: tipoEventoId ?? this.tipoEventoId,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      tipoEventoNormalizado:
          tipoEventoNormalizado ?? this.tipoEventoNormalizado,
      tipoEventoIds: tipoEventoIds ?? this.tipoEventoIds,
      tipoEventoSlugs: tipoEventoSlugs ?? this.tipoEventoSlugs,
      tipoEventoNomes: tipoEventoNomes ?? this.tipoEventoNomes,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      tags: tags ?? this.tags,
      galeriaUrls: galeriaUrls ?? this.galeriaUrls,
      paletaCores: paletaCores ?? this.paletaCores,
      categoriaId: categoriaId ?? this.categoriaId,
      categoria: categoria ?? this.categoria,
      fornecedoresRelacionados:
          fornecedoresRelacionados ?? this.fornecedoresRelacionados,
      categoriasFornecedorSugeridas:
          categoriasFornecedorSugeridas ?? this.categoriasFornecedorSugeridas,
      tarefasSugeridas: tarefasSugeridas ?? this.tarefasSugeridas,
      itensOrcamentoSugeridos:
          itensOrcamentoSugeridos ?? this.itensOrcamentoSugeridos,
      estilo: estilo ?? this.estilo,
      faixaCusto: faixaCusto ?? this.faixaCusto,
      nivelDificuldade: nivelDificuldade ?? this.nivelDificuldade,
      destaque: destaque ?? this.destaque,
      ativo: ativo ?? this.ativo,
      publicado: publicado ?? this.publicado,
      deletado: deletado ?? this.deletado,
      ordem: ordem ?? this.ordem,
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
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  static List<String> _asStringListWithExtras(
    dynamic value, {
    List<dynamic> extras = const <dynamic>[],
  }) {
    final result = <String>[];
    final seen = <String>{};

    void add(dynamic raw) {
      final text = _asString(raw).trim();
      if (text.isEmpty) return;
      if (seen.add(text.toLowerCase())) {
        result.add(text);
      }
    }

    for (final item in _asStringList(value)) {
      add(item);
    }
    for (final extra in extras) {
      add(extra);
    }
    return result;
  }

  static List<TarefaInspiracaoSugerida> _asTarefas(dynamic value) {
    if (value is! List) return const <TarefaInspiracaoSugerida>[];

    return value
        .whereType<Map>()
        .map((item) => _tarefaFromMap(Map<String, dynamic>.from(item)))
        .where((tarefa) => tarefa.titulo.isNotEmpty)
        .toList();
  }

  static TarefaInspiracaoSugerida _tarefaFromMap(Map<String, dynamic> map) {
    final titulo = _firstString(map, ['titulo', 'nome']);
    return TarefaInspiracaoSugerida(
      titulo: titulo,
      descricao: _asString(map['descricao']),
      categoria: _asString(map['categoria']),
      diasAntesEvento: _asInt(
        map['diasAntesEvento'] ?? map['diasAntes'],
        fallback: 30,
      ),
      prioridade: _asString(map['prioridade']).isEmpty
          ? 'media'
          : _asString(map['prioridade']),
      obrigatoria: _asBool(map['obrigatoria']),
      ordem: _asInt(map['ordem'], fallback: 1),
      status: _asString(map['status']).isEmpty
          ? 'pendente'
          : _asString(map['status']),
      origem: _asString(map['origem']),
    );
  }

  static Map<String, dynamic> _tarefaToMap(TarefaInspiracaoSugerida tarefa) {
    return {
      'titulo': tarefa.titulo,
      'nome': tarefa.titulo,
      'descricao': tarefa.descricao,
      'categoria': tarefa.categoria,
      'diasAntesEvento': tarefa.diasAntesEvento,
      'prioridade': tarefa.prioridade,
      'obrigatoria': tarefa.obrigatoria,
      'ordem': tarefa.ordem,
      'status': tarefa.status,
      'origem': tarefa.origem,
    };
  }

  static List<ItemOrcamentoInspiracaoSugerido> _asItensOrcamento(
    dynamic value,
  ) {
    if (value is! List) return const <ItemOrcamentoInspiracaoSugerido>[];

    return value
        .whereType<Map>()
        .map((item) => _itemOrcamentoFromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.item.isNotEmpty)
        .toList();
  }

  static ItemOrcamentoInspiracaoSugerido _itemOrcamentoFromMap(
    Map<String, dynamic> map,
  ) {
    final nome = _firstString(map, ['item', 'nome']);
    final custoEstimado = _asDouble(
      map['custoEstimado'] ?? map['valorEstimado'],
    );
    return ItemOrcamentoInspiracaoSugerido(
      item: nome,
      categoria: _asString(map['categoria']),
      descricao: _asString(map['descricao']),
      custoEstimado: custoEstimado,
      custoReal: _asDouble(map['custoReal']),
      custoMinimo: _asDouble(map['custoMinimo']),
      custoMaximo: _asDouble(map['custoMaximo']),
      unidade: _asString(map['unidade']).isEmpty
          ? 'unidade'
          : _asString(map['unidade']),
      quantidadeBase: _asDouble(map['quantidadeBase'], fallback: 1),
      custoPorConvidado: _asDouble(map['custoPorConvidado']),
      obrigatorio: _asBool(map['obrigatorio']),
      ordem: _asInt(map['ordem'], fallback: 1),
      statusPagamento: _asString(map['statusPagamento']).isEmpty
          ? 'pendente'
          : _asString(map['statusPagamento']),
      origem: _asString(map['origem']),
    );
  }

  static Map<String, dynamic> _itemOrcamentoToMap(
    ItemOrcamentoInspiracaoSugerido item,
  ) {
    return {
      'categoria': item.categoria,
      'item': item.item,
      'nome': item.item,
      'descricao': item.descricao,
      'custoEstimado': item.custoEstimado,
      'valorEstimado': item.custoEstimado,
      'custoMinimo': item.custoMinimo,
      'custoMaximo': item.custoMaximo,
      'unidade': item.unidade,
      'quantidadeBase': item.quantidadeBase,
      'custoPorConvidado': item.custoPorConvidado,
      'obrigatorio': item.obrigatorio,
      'ordem': item.ordem,
      'custoReal': item.custoReal,
      'statusPagamento': item.statusPagamento,
      'origem': item.origem,
    };
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final text = _asString(map[key]).trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return ['true', '1', 's', 'sim', 'y', 'yes'].contains(normalized);
    }
    return false;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class ReferenciaEventoModel extends ReferenciaEvento {
  ReferenciaEventoModel({
    required super.id,
    required super.eventoId,
    required super.userId,
    required super.inspiracaoId,
    required super.titulo,
    required super.descricao,
    required super.imagemUrl,
    required super.categoriaId,
    required super.categoria,
    required super.tags,
    required super.galeriaUrls,
    required super.paletaCores,
    required super.favorito,
    required super.status,
    required super.prioridade,
    required super.origem,
    required super.anotacao,
    required super.ativo,
    required super.deletado,
    super.criadoEm,
    super.atualizadoEm,
  });

  factory ReferenciaEventoModel.fromEntity(ReferenciaEvento entity) {
    if (entity is ReferenciaEventoModel) return entity;

    return ReferenciaEventoModel(
      id: entity.id,
      eventoId: entity.eventoId,
      userId: entity.userId,
      inspiracaoId: entity.inspiracaoId,
      titulo: entity.titulo,
      descricao: entity.descricao,
      imagemUrl: entity.imagemUrl,
      categoriaId: entity.categoriaId,
      categoria: entity.categoria,
      tags: List<String>.from(entity.tags),
      galeriaUrls: List<String>.from(entity.galeriaUrls),
      paletaCores: List<String>.from(entity.paletaCores),
      favorito: entity.favorito,
      status: entity.status,
      prioridade: entity.prioridade,
      origem: entity.origem,
      anotacao: entity.anotacao,
      ativo: entity.ativo,
      deletado: entity.deletado,
      criadoEm: entity.criadoEm,
      atualizadoEm: entity.atualizadoEm,
    );
  }

  factory ReferenciaEventoModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return ReferenciaEventoModel(
      id: _asString(data['id']).isNotEmpty ? _asString(data['id']) : doc.id,
      eventoId: _asString(data['eventoId'] ?? data['idEvento']),
      userId: _asString(data['userId'] ?? data['idUsuario']),
      inspiracaoId: _asString(data['inspiracaoId']),
      titulo: _asString(data['titulo']).isEmpty
          ? 'Referência sem título'
          : _asString(data['titulo']),
      descricao: _asString(data['descricao']),
      imagemUrl: _asString(data['imagemUrl']),
      categoriaId: _asString(data['categoriaId']),
      categoria: _asString(data['categoria']).isEmpty
          ? 'Sem categoria'
          : _asString(data['categoria']),
      tags: _asStringList(data['tags']),
      galeriaUrls: _asStringList(data['galeriaUrls']),
      paletaCores: _asStringList(data['paletaCores']),
      favorito: data['favorito'] == true,
      status: _asString(data['status']).isEmpty
          ? 'salva'
          : _asString(data['status']),
      prioridade: _asString(data['prioridade']).isEmpty
          ? 'media'
          : _asString(data['prioridade']),
      origem: _asString(data['origem']).isEmpty
          ? 'manual'
          : _asString(data['origem']),
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
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
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
