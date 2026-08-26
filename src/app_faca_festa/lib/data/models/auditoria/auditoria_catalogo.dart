class AuditoriaAcaoInfo {
  const AuditoriaAcaoInfo({
    required this.codigo,
    required this.titulo,
    required this.area,
    required this.areaLabel,
  });

  final String codigo;
  final String titulo;
  final String area;
  final String areaLabel;
}

const catalogoAcoesAuditoria = <String, AuditoriaAcaoInfo>{
  'USUARIO_CRIADO': AuditoriaAcaoInfo(
    codigo: 'USUARIO_CRIADO',
    titulo: 'Usuário criado',
    area: 'USUARIO',
    areaLabel: 'Acessos',
  ),
  'USUARIO_TIPO_ALTERADO': AuditoriaAcaoInfo(
    codigo: 'USUARIO_TIPO_ALTERADO',
    titulo: 'Papel do usuário',
    area: 'USUARIO',
    areaLabel: 'Acessos',
  ),
  'USUARIO_STATUS_ALTERADO': AuditoriaAcaoInfo(
    codigo: 'USUARIO_STATUS_ALTERADO',
    titulo: 'Status da conta',
    area: 'USUARIO',
    areaLabel: 'Acessos',
  ),
  'FORNECEDOR_APROVADO': AuditoriaAcaoInfo(
    codigo: 'FORNECEDOR_APROVADO',
    titulo: 'Fornecedor aprovado',
    area: 'FORNECEDOR',
    areaLabel: 'Fornecedor',
  ),
  'FORNECEDOR_REPROVADO': AuditoriaAcaoInfo(
    codigo: 'FORNECEDOR_REPROVADO',
    titulo: 'Fornecedor reprovado',
    area: 'FORNECEDOR',
    areaLabel: 'Fornecedor',
  ),
  'FORNECEDOR_ATIVADO': AuditoriaAcaoInfo(
    codigo: 'FORNECEDOR_ATIVADO',
    titulo: 'Fornecedor ativado',
    area: 'FORNECEDOR',
    areaLabel: 'Fornecedor',
  ),
  'FORNECEDOR_DESATIVADO': AuditoriaAcaoInfo(
    codigo: 'FORNECEDOR_DESATIVADO',
    titulo: 'Fornecedor desativado',
    area: 'FORNECEDOR',
    areaLabel: 'Fornecedor',
  ),
  'FORNECEDOR_EDITADO': AuditoriaAcaoInfo(
    codigo: 'FORNECEDOR_EDITADO',
    titulo: 'Perfil do fornecedor',
    area: 'FORNECEDOR',
    areaLabel: 'Fornecedor',
  ),
  'SERVICO_CATALOGO_SALVO': AuditoriaAcaoInfo(
    codigo: 'SERVICO_CATALOGO_SALVO',
    titulo: 'Serviço do catálogo',
    area: 'CATALOGO',
    areaLabel: 'Catálogo',
  ),
  'SERVICO_CATALOGO_EXCLUIDO': AuditoriaAcaoInfo(
    codigo: 'SERVICO_CATALOGO_EXCLUIDO',
    titulo: 'Serviço removido do catálogo',
    area: 'CATALOGO',
    areaLabel: 'Catálogo',
  ),
  'CATEGORIA_SALVA': AuditoriaAcaoInfo(
    codigo: 'CATEGORIA_SALVA',
    titulo: 'Categoria salva',
    area: 'CATALOGO',
    areaLabel: 'Catálogo',
  ),
  'CATEGORIA_EXCLUIDA': AuditoriaAcaoInfo(
    codigo: 'CATEGORIA_EXCLUIDA',
    titulo: 'Categoria removida',
    area: 'CATALOGO',
    areaLabel: 'Catálogo',
  ),
  'SERVICO_FORNECEDOR_SALVO': AuditoriaAcaoInfo(
    codigo: 'SERVICO_FORNECEDOR_SALVO',
    titulo: 'Serviço publicado',
    area: 'SERVICO',
    areaLabel: 'Serviços',
  ),
  'SERVICO_FORNECEDOR_EXCLUIDO': AuditoriaAcaoInfo(
    codigo: 'SERVICO_FORNECEDOR_EXCLUIDO',
    titulo: 'Serviço removido',
    area: 'SERVICO',
    areaLabel: 'Serviços',
  ),
  'EVENTO_APROVADO': AuditoriaAcaoInfo(
    codigo: 'EVENTO_APROVADO',
    titulo: 'Evento aprovado',
    area: 'EVENTO',
    areaLabel: 'Eventos',
  ),
  'EVENTO_EXCLUIDO': AuditoriaAcaoInfo(
    codigo: 'EVENTO_EXCLUIDO',
    titulo: 'Evento excluído',
    area: 'EVENTO',
    areaLabel: 'Eventos',
  ),
  'ORCAMENTO_RESPONDIDO': AuditoriaAcaoInfo(
    codigo: 'ORCAMENTO_RESPONDIDO',
    titulo: 'Orçamento respondido',
    area: 'ORCAMENTO',
    areaLabel: 'Orçamentos',
  ),
  'ORCAMENTO_EXCLUIDO': AuditoriaAcaoInfo(
    codigo: 'ORCAMENTO_EXCLUIDO',
    titulo: 'Orçamento excluído',
    area: 'ORCAMENTO',
    areaLabel: 'Orçamentos',
  ),
  'COTACAO_RESPONDIDA': AuditoriaAcaoInfo(
    codigo: 'COTACAO_RESPONDIDA',
    titulo: 'Cotação respondida',
    area: 'COTACAO',
    areaLabel: 'Cotações',
  ),
};

const areasAuditoriaLabels = <String, String>{
  'ACESSO': 'Acessos',
  'USUARIO': 'Acessos',
  'FORNECEDOR': 'Fornecedor',
  'SERVICO': 'Serviços',
  'CATALOGO': 'Catálogo',
  'EVENTO': 'Eventos',
  'ORCAMENTO': 'Orçamentos',
  'COTACAO': 'Cotações',
  'SISTEMA': 'Sistema',
};

AuditoriaAcaoInfo infoAcaoAuditoria(String acao) {
  return catalogoAcoesAuditoria[acao] ??
      AuditoriaAcaoInfo(
        codigo: acao,
        titulo: acao.replaceAll('_', ' ').toLowerCase(),
        area: 'SISTEMA',
        areaLabel: 'Sistema',
      );
}
