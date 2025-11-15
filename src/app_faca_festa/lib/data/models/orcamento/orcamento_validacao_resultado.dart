class OrcamentoValidacaoResultado {
  final bool ok;
  final String? mensagem;
  final double? excedente;
  final double? limite;

  OrcamentoValidacaoResultado({
    required this.ok,
    this.mensagem,
    this.excedente,
    this.limite,
  });

  factory OrcamentoValidacaoResultado.ok() => OrcamentoValidacaoResultado(ok: true);

  factory OrcamentoValidacaoResultado.excedeuCategoria({
    required double excedente,
    required double limite,
  }) =>
      OrcamentoValidacaoResultado(
        ok: false,
        mensagem: "Limite da categoria excedido.",
        excedente: excedente,
        limite: limite,
      );

  factory OrcamentoValidacaoResultado.excedeuEvento({
    required double excedente,
    required double limite,
  }) =>
      OrcamentoValidacaoResultado(
        ok: false,
        mensagem: "Orçamento total do evento excedido.",
        excedente: excedente,
        limite: limite,
      );

  factory OrcamentoValidacaoResultado.erro(String mensagem) =>
      OrcamentoValidacaoResultado(ok: false, mensagem: mensagem);
}
