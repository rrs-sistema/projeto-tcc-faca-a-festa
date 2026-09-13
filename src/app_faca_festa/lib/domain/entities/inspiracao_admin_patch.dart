class InspiracaoAdminPatch {
  const InspiracaoAdminPatch({
    this.ativo,
    this.publicado,
    this.deletado,
    this.destaque,
    this.ordem,
    this.imagemUrl,
  });

  final bool? ativo;
  final bool? publicado;
  final bool? deletado;
  final bool? destaque;
  final int? ordem;
  final String? imagemUrl;
}
