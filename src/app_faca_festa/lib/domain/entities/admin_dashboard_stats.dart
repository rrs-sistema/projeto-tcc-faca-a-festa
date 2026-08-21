class AdminDashboardStats {
  final int categorias;
  final int categoriasAtivas;
  final int subcategorias;
  final int servicos;
  final int fornecedores;
  final int fornecedoresAptos;
  final int fornecedoresPendentes;
  final int usuarios;
  final int usuariosAtivos;
  final int eventos;
  final int eventosAtivos;
  final int temas;
  final int orcamentos;
  final int orcamentosAbertos;
  final int territorios;

  const AdminDashboardStats({
    this.categorias = 0,
    this.categoriasAtivas = 0,
    this.subcategorias = 0,
    this.servicos = 0,
    this.fornecedores = 0,
    this.fornecedoresAptos = 0,
    this.fornecedoresPendentes = 0,
    this.usuarios = 0,
    this.usuariosAtivos = 0,
    this.eventos = 0,
    this.eventosAtivos = 0,
    this.temas = 0,
    this.orcamentos = 0,
    this.orcamentosAbertos = 0,
    this.territorios = 0,
  });

  static const empty = AdminDashboardStats();
}
