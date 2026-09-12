class FornecedorInteracao {
  final String id;
  final String idUsuario;
  final String idEvento;
  final String idFornecedor;
  final String acao;
  final int peso;
  final String? tipoEventoId;
  final String? tipoEventoNome;
  final String? cidade;
  final DateTime? createdAt;

  const FornecedorInteracao({
    required this.id,
    required this.idUsuario,
    required this.idEvento,
    required this.idFornecedor,
    required this.acao,
    required this.peso,
    this.tipoEventoId,
    this.tipoEventoNome,
    this.cidade,
    this.createdAt,
  });
}
