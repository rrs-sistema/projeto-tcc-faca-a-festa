class OrcamentoGasto {
  OrcamentoGasto({
    required this.idGasto,
    required this.idOrcamento,
    this.idServicoContratado,
    this.nomeServicoContratado,
    required this.nome,
    required this.custo,
    required this.pago,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  final String idGasto;
  final String idOrcamento;
  final String? idServicoContratado;
  final String? nomeServicoContratado;
  final String nome;
  final double custo;
  final double pago;
  final DateTime dataCadastro;

  double get restante => (custo - pago).clamp(0, custo).toDouble();

  double get percentualPago =>
      custo > 0 ? (pago / custo).clamp(0.0, 1.0).toDouble() : 0.0;
}
