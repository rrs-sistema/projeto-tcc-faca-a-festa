/// Textos da home do organizador — vocabulário de festa, não de sistema.
abstract final class HomeOrganizadorCopy {
  static const barraHome = 'Festa';
  static const barraConvidados = 'Convidados';
  static const barraOrcamento = 'Orçamento';
  static const barraMais = 'Mais';

  static const resumoTitulo = 'Como vai a festa';
  static const resumoConvidados = 'Convidados';
  static const resumoOrcamento = 'Orçamento';
  static const resumoTarefas = 'Tarefas';

  static const gastoTitulo = 'Gasto e planejado';
  static const gastoUsado = 'Gasto';
  static const gastoPlanejado = 'Planejado';

  static const atalhoCotacoes = 'Pedidos de preço';
  static const atalhoCalculadora = 'Calculadora';
  static const atalhoPresentes = 'Presentes';
  static const atalhoFornecedores = 'Fornecedores';

  static const proximasTarefas = 'Próximas tarefas';
  static const verTodasTarefas = 'Ver todas';
  static const nenhumaTarefa = 'Nenhuma tarefa';
  static const nenhumaTarefaAcao = 'Criar a primeira';
  static const tarefasEmDia = 'Todas as tarefas concluídas';

  static String tarefasFaixaTitulo({required int total, required int pendentes}) {
    if (total <= 0) return nenhumaTarefa;
    if (pendentes <= 0) return tarefasEmDia;
    return proximasTarefas;
  }

  static String tarefasFaixaAcao({required int total}) {
    if (total <= 0) return nenhumaTarefaAcao;
    return verTodasTarefas;
  }

  static const fornecedoresRegiao = 'Fornecedores perto da festa';

  static const vazioTitulo = 'Comece pela sua festa';
  static const vazioTexto =
      'Crie um evento para acompanhar convidados, orçamento e tarefas neste painel.';
  static const vazioCriar = 'Criar minha festa';
  static const vazioEscolher = 'Escolher um evento';

  static String convidadosValor(int confirmados, int total) {
    if (total <= 0) return '0 na lista';
    return '$confirmados de $total';
  }

  static String orcamentoPercentual(double progresso) {
    final pct = (progresso * 100).clamp(0, 999);
    return '${pct.toStringAsFixed(0)}%';
  }

  static String tarefasPercentual(double progresso) {
    final pct = (progresso * 100).clamp(0, 100);
    return '${pct.toStringAsFixed(0)}%';
  }

  static String cotacoesValor(int total) {
    if (total <= 0) return 'Nenhum pedido';
    if (total == 1) return '1 pedido';
    return '$total pedidos';
  }

  static const calculadoraValor = 'Estimar';
  static const presentesValor = 'Lista da festa';
  static const fornecedoresValor = 'Perto da festa';
}
