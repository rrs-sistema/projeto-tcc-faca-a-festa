import 'package:app_faca_festa/domain/entities/inspiracao_sugestao.dart';

class Inspiracao {
  final String id;
  final String tipoEventoId;
  final String tipoEvento;
  final String tipoEventoNormalizado;
  final List<String> tipoEventoIds;
  final List<String> tipoEventoSlugs;
  final List<String> tipoEventoNomes;
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
  final List<TarefaInspiracaoSugerida> tarefasSugeridas;
  final List<ItemOrcamentoInspiracaoSugerido> itensOrcamentoSugeridos;
  final String estilo;
  final String faixaCusto;
  final String nivelDificuldade;
  final bool destaque;
  final bool ativo;
  final bool publicado;
  final bool deletado;
  final int ordem;
  final bool favorito;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  const Inspiracao({
    required this.id,
    this.tipoEventoId = '',
    this.tipoEvento = '',
    this.tipoEventoNormalizado = '',
    this.tipoEventoIds = const [],
    this.tipoEventoSlugs = const [],
    this.tipoEventoNomes = const [],
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
    this.publicado = true,
    this.deletado = false,
    this.ordem = 0,
    this.favorito = false,
    this.criadoEm,
    this.atualizadoEm,
  });

  Inspiracao copyWith({
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
    return Inspiracao(
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
}
