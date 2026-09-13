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
}
