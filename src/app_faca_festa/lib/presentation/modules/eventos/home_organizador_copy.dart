/// Prazo mostrado na faixa de tarefas da home.
class PrazoTarefaHome {
  const PrazoTarefaHome({
    required this.rotulo,
    required this.atrasada,
    required this.hoje,
  });

  final String rotulo;
  final bool atrasada;
  final bool hoje;
}

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
  static const novaTarefa = 'Nova tarefa';
  static const desfazer = 'Desfazer';
  static const tarefaConcluidaAviso = 'Tarefa concluída';
  static const tarefaErroStatus = 'Não foi possível atualizar a tarefa';
  static const semPrazo = 'Sem prazo';
  static const marcarFeita = 'Marcar como feita';
  static const abrirTarefa = 'Abrir tarefa';
  static const verFornecedores = 'Ver todos';
  static const nenhumFornecedorPerto = 'Nenhum fornecedor perto da festa';
  static const nenhumFornecedorAcao = 'Buscar fornecedores';
  static const fornecedorAbrir = 'Ver detalhes';

  static String tarefasFaixaTitulo({required int total, required int pendentes}) {
    if (total <= 0) return nenhumaTarefa;
    if (pendentes <= 0) return tarefasEmDia;
    return proximasTarefas;
  }

  static String tarefasFaixaAcao({required int total}) {
    if (total <= 0) return nenhumaTarefaAcao;
    return verTodasTarefas;
  }

  static PrazoTarefaHome prazoTarefa(DateTime? data, DateTime agora) {
    if (data == null) {
      return const PrazoTarefaHome(rotulo: semPrazo, atrasada: false, hoje: false);
    }
    final diferenca = _soDia(data).difference(_soDia(agora)).inDays;
    if (diferenca < 0) {
      return PrazoTarefaHome(
        rotulo: 'Atrasada · ${_ddMm(data)}',
        atrasada: true,
        hoje: false,
      );
    }
    if (diferenca == 0) {
      return const PrazoTarefaHome(rotulo: 'Hoje', atrasada: false, hoje: true);
    }
    if (diferenca == 1) {
      return const PrazoTarefaHome(rotulo: 'Amanhã', atrasada: false, hoje: false);
    }
    if (diferenca <= 7) {
      return PrazoTarefaHome(
        rotulo: 'Em $diferenca dias',
        atrasada: false,
        hoje: false,
      );
    }
    return PrazoTarefaHome(rotulo: _ddMm(data), atrasada: false, hoje: false);
  }

  static int contarAtrasadas(Iterable<DateTime?> datas, DateTime agora) {
    var total = 0;
    for (final data in datas) {
      if (prazoTarefa(data, agora).atrasada) total++;
    }
    return total;
  }

  static String tarefasResumoFaixa({
    required int total,
    required int pendentes,
    required int atrasadas,
  }) {
    if (total <= 0) {
      return 'Anote o que falta até o dia da festa.';
    }
    if (pendentes <= 0) {
      return 'Nada pendente. A festa está em dia.';
    }
    if (atrasadas <= 0) {
      return pendentes == 1 ? '1 para fazer' : '$pendentes para fazer';
    }
    if (atrasadas == pendentes) {
      return atrasadas == 1 ? '1 atrasada' : '$atrasadas atrasadas';
    }
    final atraso = atrasadas == 1 ? '1 atrasada' : '$atrasadas atrasadas';
    final falta = pendentes == 1 ? '1 para fazer' : '$pendentes para fazer';
    return '$atraso · $falta';
  }

  static String eMaisTarefas(int restantes) {
    if (restantes <= 1) return 'E mais 1 tarefa';
    return 'E mais $restantes tarefas';
  }

  static String distanciaFornecedor(double? km) {
    if (km == null || km < 0) return '';
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) {
      final texto = km.toStringAsFixed(1);
      return '${texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto} km';
    }
    return '${km.round()} km';
  }

  static DateTime _soDia(DateTime data) => DateTime(data.year, data.month, data.day);

  static String _ddMm(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes';
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
