class SugestaoCatalogoFornecedor {
  final String idSugestao;
  final String idFornecedor;
  final double scoreCatalogo;
  final String nivelCatalogo;
  final String titulo;
  final String descricao;
  final List<String> pendencias;
  final List<String> melhoriasPrioritarias;
  final List<String> camposAusentes;
  final List<Map<String, dynamic>> servicosComAlerta;
  final List<String> categoriasSemServico;
  final int totalServicosAtivos;
  final int totalServicosSemImagem;
  final int totalServicosSemPreco;
  final int totalServicosSemDescricao;
  final String origem;
  final String versaoRegra;
  final String status;
  final Map<String, dynamic>? metadados;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  const SugestaoCatalogoFornecedor({
    required this.idSugestao,
    required this.idFornecedor,
    required this.scoreCatalogo,
    required this.nivelCatalogo,
    required this.titulo,
    required this.descricao,
    required this.totalServicosAtivos,
    required this.totalServicosSemImagem,
    required this.totalServicosSemPreco,
    required this.totalServicosSemDescricao,
    required this.origem,
    required this.versaoRegra,
    required this.status,
    required this.createdAt,
    this.pendencias = const [],
    this.melhoriasPrioritarias = const [],
    this.camposAusentes = const [],
    this.servicosComAlerta = const [],
    this.categoriasSemServico = const [],
    this.metadados,
    this.updatedAt,
    this.expiresAt,
  });
}
