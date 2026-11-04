class AvaliacaoServico {
  final String? respostaFornecedor;
  final DateTime? respostaData;
  final bool verificada;
  final String? idContrato;
  final String id;
  final String idFornecedorServico;
  final String idCliente;
  final String nomeCliente;
  final int nota;
  final String comentario;
  final DateTime data;
  final String? idEvento;
  final String? nomeEvento;

  const AvaliacaoServico({
    this.respostaFornecedor,
    this.respostaData,
    this.verificada = false,
    this.idContrato,
    required this.id,
    required this.idFornecedorServico,
    required this.idCliente,
    required this.nomeCliente,
    required this.nota,
    required this.comentario,
    required this.data,
    this.idEvento,
    this.nomeEvento,
  });
}
