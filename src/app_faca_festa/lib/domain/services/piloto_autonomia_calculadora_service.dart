import 'avaliacao_autonomia_calculadora_service.dart';

/// Roteiro e progresso do estudo. Não cria resultados de participantes.
class PilotoAutonomiaCalculadoraService {
  const PilotoAutonomiaCalculadoraService();
  static const instrucoes = {
    'propor':
        'Obter uma proposta inicial e conferir suas premissas e pendências.',
    'ajustar':
        'Alterar o público definido no caso e conferir o recálculo sem perder ajustes.',
    'comprar':
        'Preparar a lista, conferir reservas compartilhadas e itens cobertos por serviço. Não executar compra externa.',
    'revisar':
        'Registrar o resultado do caso pós-evento fornecido, salvar, reabrir e conferir o estado.',
  };

  Map<String, dynamic> criar(String antes, String depois, int participantes) {
    if (antes.trim().isEmpty ||
        depois.trim().isEmpty ||
        antes == depois ||
        participantes < 5 ||
        participantes > 50) {
      throw ArgumentError(
          'Defina versões diferentes e de 5 a 50 participantes.');
    }
    return {
      'versao': 1,
      'revisao': 0,
      'versao_antes': antes,
      'versao_depois': depois,
      'participantes': [
        for (var n = 1; n <= participantes; n++)
          'p${n.toString().padLeft(2, '0')}'
      ],
      'casos': <String, dynamic>{},
      'sessoes': <Map<String, dynamic>>[],
    };
  }

  Map<String, dynamic> definirCaso(Map<String, dynamic> estudo, String cenario,
      String tarefa, String contexto, String criterio) {
    _validar(estudo);
    if (!AvaliacaoAutonomiaCalculadoraService.cenarios.contains(cenario) ||
        !instrucoes.containsKey(tarefa) ||
        contexto.trim().isEmpty ||
        criterio.trim().length < 20 ||
        contexto.length > 160 ||
        criterio.length > 3000) {
      throw ArgumentError(
          'Identifique o caso e descreva seu critério de aceite, com ao menos 20 caracteres.');
    }
    final chave = '$cenario|$tarefa';
    final sessoes = _sessoes(estudo);
    if (sessoes.any((s) => s['cenario'] == cenario && s['tarefa'] == tarefa)) {
      throw StateError(
          'O caso já tem observações e não pode mudar durante o estudo.');
    }
    return _proxima(estudo, {
      'casos': {
        ..._casos(estudo),
        chave: {
          'contexto': contexto.trim(),
          'criterio': criterio.trim(),
        }
      }
    });
  }

  Map<String, dynamic> registrar(
      Map<String, dynamic> estudo, Map<String, dynamic> sessao) {
    _validar(estudo);
    final pessoa = sessao['participante'], modo = sessao['modo'];
    final indice = (estudo['participantes'] as List).indexOf(pessoa);
    final caso = _casos(estudo)['${sessao['cenario']}|${sessao['tarefa']}'];
    if (indice < 0 ||
        !['antes', 'depois'].contains(modo) ||
        caso is! Map ||
        sessao['contexto_comparavel'] != caso['contexto'] ||
        sessao['versao_app'] != estudo['versao_$modo'] ||
        sessao['origem'] != 'sessao_observada') {
      throw StateError(
          'A sessão não corresponde ao participante, versão ou caso fixado no estudo.');
    }
    for (final k in ['intervencoes', 'segundos_ativos', 'correcoes', 'erros']) {
      if (sessao[k] is! int || (sessao[k] as int) < 0) {
        throw ArgumentError('Contagem inválida: $k.');
      }
    }
    final sessoes = _sessoes(estudo);
    final index = sessoes.indexWhere((s) => _chave(s) == _chave(sessao));
    if (index >= 0 && sessoes[index]['estado_observacao'] == 'finalizada') {
      throw StateError(
          'Uma observação finalizada é imutável. Preserve a falha e inicie outro estudo para repetir o caso.');
    }
    if (index >= 0 &&
        ['intervencoes', 'segundos_ativos', 'correcoes', 'erros']
            .any((k) => (sessao[k] as int) < (sessoes[index][k] as int))) {
      throw StateError(
          'A retomada não pode apagar tempo ou ações já observados.');
    }
    final primeiro = indice.isEven ? 'antes' : 'depois';
    if (modo != primeiro &&
        !sessoes.any((s) =>
            s['participante'] == pessoa &&
            s['cenario'] == sessao['cenario'] &&
            s['tarefa'] == sessao['tarefa'] &&
            s['modo'] == primeiro &&
            s['estado_observacao'] == 'finalizada')) {
      throw StateError(
          'Para este participante, observe primeiro a versão $primeiro.');
    }
    if (!['em_andamento', 'finalizada'].contains(sessao['estado_observacao'])) {
      throw ArgumentError('Estado de observação inválido.');
    }
    if (sessao['estado_observacao'] == 'finalizada') {
      // Reusar os validadores públicos, sem criar uma linha de base artificial.
      _validarFinalizada(sessao);
    }
    if (index >= 0) {
      sessoes[index] = Map.of(sessao);
    } else {
      sessoes.add(Map.of(sessao));
    }
    return _proxima(estudo, {'sessoes': sessoes});
  }

  Map<String, dynamic> progresso(Map<String, dynamic> estudo) {
    _validar(estudo);
    final sessoes = _sessoes(estudo);
    final concluidas =
        sessoes.where((s) => s['estado_observacao'] == 'finalizada').toList();
    final faltantes = <Map<String, String>>[];
    for (final p in estudo['participantes'] as List) {
      for (final c in AvaliacaoAutonomiaCalculadoraService.cenarios) {
        for (final t in instrucoes.keys) {
          for (final m in ['antes', 'depois']) {
            if (!concluidas.any((s) =>
                s['participante'] == p &&
                s['cenario'] == c &&
                s['tarefa'] == t &&
                s['modo'] == m)) {
              faltantes.add({
                'participante': p.toString(),
                'cenario': c,
                'tarefa': t,
                'modo': m
              });
            }
          }
        }
      }
    }
    Map<String, dynamic>? resultado;
    String? impedimento;
    if (faltantes.isEmpty) {
      try {
        resultado =
            const AvaliacaoAutonomiaCalculadoraService().avaliar(concluidas);
      } catch (e) {
        impedimento = e.toString();
      }
    }
    return {
      'sessoes_previstas': (estudo['participantes'] as List).length * 32,
      'sessoes_finalizadas': concluidas.length,
      'sessoes_interrompidas': sessoes.length - concluidas.length,
      'casos_definidos': _casos(estudo).length,
      'casos_previstos': 16,
      'faltantes': faltantes,
      'resultado': resultado,
      'impedimento': impedimento ??
          (faltantes.isEmpty
              ? null
              : 'Há sessões pendentes. Nenhuma foi descartada para calcular a meta.'),
    };
  }

  void _validarFinalizada(Map<String, dynamic> s) {
    for (final k in [
      'concluida',
      'validacao_quantidades',
      'sem_duplicidades',
      'sem_alterar_fatos'
    ]) {
      if (s[k] is! bool) {
        throw ArgumentError('Confira o resultado observado: $k.');
      }
    }
    final custo = s['custo_ia'], latencia = s['latencia_ia_ms'];
    if (custo is! num ||
        !custo.isFinite ||
        custo < 0 ||
        latencia is! int ||
        latencia < 0) {
      throw ArgumentError(
          'Informe custo e latência medidos. Desconhecido não é zero.');
    }
  }

  String _chave(Map<String, dynamic> s) =>
      ['participante', 'cenario', 'tarefa', 'modo'].map((k) => s[k]).join('|');
  List<Map<String, dynamic>> _sessoes(Map<String, dynamic> e) =>
      (e['sessoes'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
  Map<String, dynamic> _casos(Map<String, dynamic> e) =>
      Map<String, dynamic>.from(e['casos'] as Map);
  Map<String, dynamic> _proxima(
          Map<String, dynamic> e, Map<String, dynamic> patch) =>
      {...e, ...patch, 'revisao': (e['revisao'] as int) + 1};
  void _validar(Map<String, dynamic> e) {
    if (e['versao'] != 1 ||
        e['revisao'] is! int ||
        e['participantes'] is! List ||
        (e['participantes'] as List).length < 5 ||
        e['casos'] is! Map ||
        e['sessoes'] is! List) {
      throw ArgumentError(
          'Estudo inválido. Crie o roteiro antes de registrar sessões.');
    }
  }
}
