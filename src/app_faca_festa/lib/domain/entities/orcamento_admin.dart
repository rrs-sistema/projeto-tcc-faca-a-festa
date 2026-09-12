class OrcamentoAdmin {
  OrcamentoAdmin({
    required this.id,
    required this.eventoNome,
    required this.tipoEvento,
    required this.cidade,
    required this.dataEvento,
    required this.categoria,
    required this.custoEstimado,
    required this.pago,
    required this.status,
    this.custoTotalEvento = 0.0,
  });

  final String id;
  final String eventoNome;
  final String tipoEvento;
  final String cidade;
  final DateTime? dataEvento;
  final String categoria;
  final double custoEstimado;
  final double pago;
  final String status;
  final double custoTotalEvento;

  double get pendente => custoEstimado > pago ? custoEstimado - pago : 0;

  double get percentualPago =>
      custoEstimado > 0 ? (pago / custoEstimado).clamp(0, 1).toDouble() : 0.0;
}
