class TarefaInspiracaoSugerida {
  const TarefaInspiracaoSugerida({
    required this.titulo,
    this.descricao = '',
    this.categoria = '',
    this.diasAntesEvento = 30,
    this.prioridade = 'media',
    this.obrigatoria = false,
    this.ordem = 1,
    this.status = 'pendente',
    this.origem = '',
  });

  final String titulo;
  final String descricao;
  final String categoria;
  final int diasAntesEvento;
  final String prioridade;
  final bool obrigatoria;
  final int ordem;
  final String status;
  final String origem;

  TarefaInspiracaoSugerida copyWith({
    String? titulo,
    String? descricao,
    String? categoria,
    int? diasAntesEvento,
    String? prioridade,
    bool? obrigatoria,
    int? ordem,
    String? status,
    String? origem,
  }) {
    return TarefaInspiracaoSugerida(
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      diasAntesEvento: diasAntesEvento ?? this.diasAntesEvento,
      prioridade: prioridade ?? this.prioridade,
      obrigatoria: obrigatoria ?? this.obrigatoria,
      ordem: ordem ?? this.ordem,
      status: status ?? this.status,
      origem: origem ?? this.origem,
    );
  }
}

class ItemOrcamentoInspiracaoSugerido {
  const ItemOrcamentoInspiracaoSugerido({
    required this.item,
    this.categoria = '',
    this.descricao = '',
    this.custoEstimado = 0,
    this.custoReal = 0,
    this.custoMinimo = 0,
    this.custoMaximo = 0,
    this.unidade = 'unidade',
    this.quantidadeBase = 1,
    this.custoPorConvidado = 0,
    this.obrigatorio = false,
    this.ordem = 1,
    this.statusPagamento = 'pendente',
    this.origem = '',
  });

  final String item;
  final String categoria;
  final String descricao;
  final double custoEstimado;
  final double custoReal;
  final double custoMinimo;
  final double custoMaximo;
  final String unidade;
  final double quantidadeBase;
  final double custoPorConvidado;
  final bool obrigatorio;
  final int ordem;
  final String statusPagamento;
  final String origem;

  ItemOrcamentoInspiracaoSugerido copyWith({
    String? item,
    String? categoria,
    String? descricao,
    double? custoEstimado,
    double? custoReal,
    double? custoMinimo,
    double? custoMaximo,
    String? unidade,
    double? quantidadeBase,
    double? custoPorConvidado,
    bool? obrigatorio,
    int? ordem,
    String? statusPagamento,
    String? origem,
  }) {
    return ItemOrcamentoInspiracaoSugerido(
      item: item ?? this.item,
      categoria: categoria ?? this.categoria,
      descricao: descricao ?? this.descricao,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      custoReal: custoReal ?? this.custoReal,
      custoMinimo: custoMinimo ?? this.custoMinimo,
      custoMaximo: custoMaximo ?? this.custoMaximo,
      unidade: unidade ?? this.unidade,
      quantidadeBase: quantidadeBase ?? this.quantidadeBase,
      custoPorConvidado: custoPorConvidado ?? this.custoPorConvidado,
      obrigatorio: obrigatorio ?? this.obrigatorio,
      ordem: ordem ?? this.ordem,
      statusPagamento: statusPagamento ?? this.statusPagamento,
      origem: origem ?? this.origem,
    );
  }
}
