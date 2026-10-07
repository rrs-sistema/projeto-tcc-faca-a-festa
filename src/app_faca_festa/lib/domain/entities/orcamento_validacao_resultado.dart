class OrcamentoValidacaoResultado {
  OrcamentoValidacaoResultado({
    required this.ok,
    this.mensagem,
    this.excedente,
    this.limite,
  });

  final bool ok;
  final String? mensagem;
  final double? excedente;
  final double? limite;

  factory OrcamentoValidacaoResultado.ok() =>
      OrcamentoValidacaoResultado(ok: true);

  factory OrcamentoValidacaoResultado.excedeuCategoria({
    required double excedente,
    required double limite,
  }) =>
      OrcamentoValidacaoResultado(
        ok: false,
        mensagem: 'O custo total é maior que o previsto da categoria.',
        excedente: excedente,
        limite: limite,
      );

  factory OrcamentoValidacaoResultado.excedeuPagamentoCategoria({
    required double excedente,
    required double limite,
  }) =>
      OrcamentoValidacaoResultado(
        ok: false,
        mensagem: 'O valor pago excede o previsto da categoria.',
        excedente: excedente,
        limite: limite,
      );

  factory OrcamentoValidacaoResultado.excedeuEvento({
    required double excedente,
    required double limite,
  }) =>
      OrcamentoValidacaoResultado(
        ok: false,
        mensagem: 'O valor pago excede o orçamento do evento.',
        excedente: excedente,
        limite: limite,
      );

  factory OrcamentoValidacaoResultado.erro(String mensagem) =>
      OrcamentoValidacaoResultado(ok: false, mensagem: mensagem);
}
