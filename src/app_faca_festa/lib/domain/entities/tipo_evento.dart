class TipoEvento {
  final String idTipoEvento;
  final String nome;
  final bool ativo;

  const TipoEvento({
    required this.idTipoEvento,
    required this.nome,
    this.ativo = true,
  });
}
