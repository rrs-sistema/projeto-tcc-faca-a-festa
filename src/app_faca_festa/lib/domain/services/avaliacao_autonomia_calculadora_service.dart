class AvaliacaoAutonomiaCalculadoraService {
  const AvaliacaoAutonomiaCalculadoraService();
  static const cenarios = {
    'tipo_orcamento',
    'tipo_orcamento_publico',
    'tipo_orcamento_cardapio',
    'completo'
  };
  static const tarefas = {'propor', 'ajustar', 'comprar', 'revisar'};

  Map<String, dynamic> avaliar(List<Map<String, dynamic>> sessoes) {
    if (sessoes.isEmpty) {
      throw ArgumentError('Nenhuma sessão observada foi informada.');
    }
    final pares = <String, Map<String, Map<String, dynamic>>>{};
    final participantes = <String>{}, cobertura = <String>{};
    final coberturaPorParticipante = <String, Set<String>>{};
    for (final s in sessoes) {
      final pessoa = s['participante'],
          caso = s['cenario'],
          tarefa = s['tarefa'];
      if (s['origem'] != 'sessao_observada' ||
          pessoa is! String ||
          pessoa.trim().isEmpty ||
          !cenarios.contains(caso) ||
          !tarefas.contains(tarefa) ||
          !['antes', 'depois'].contains(s['modo']) ||
          s['versao_app'] is! String ||
          (s['versao_app'] as String).isEmpty ||
          s['contexto_comparavel'] is! String ||
          (s['contexto_comparavel'] as String).isEmpty ||
          s['concluida'] is! bool ||
          s['validacao_quantidades'] is! bool ||
          s['sem_duplicidades'] is! bool ||
          s['sem_alterar_fatos'] is! bool) {
        throw ArgumentError(
            'Há uma sessão sem identificação, contexto ou verificação de qualidade.');
      }
      for (final k in [
        'intervencoes',
        'segundos_ativos',
        'correcoes',
        'erros',
        'latencia_ia_ms'
      ]) {
        final v = s[k];
        if (v is! int || v < 0) {
          throw ArgumentError('Informe $k como inteiro não negativo.');
        }
      }
      final custo = s['custo_ia'];
      if (custo is! num || !custo.isFinite || custo < 0) {
        throw ArgumentError(
            'Informe o custo medido de IA, inclusive zero quando não usada.');
      }
      final chave = '$pessoa|$caso|$tarefa';
      final par = pares.putIfAbsent(chave, () => {});
      if (par.containsKey(s['modo'])) {
        throw ArgumentError(
            'Há sessões duplicadas para a mesma tarefa e modo.');
      }
      par[s['modo'] as String] = s;
      participantes.add(pessoa);
      cobertura.add('$caso|$tarefa');
      coberturaPorParticipante
          .putIfAbsent(pessoa, () => {})
          .add('$caso|$tarefa');
    }
    var antes = 0,
        depois = 0,
        tempoAntes = 0,
        tempoDepois = 0,
        correcoesAntes = 0,
        correcoesDepois = 0,
        latencia = 0;
    var custo = 0.0, qualidade = true;
    for (final par in pares.values) {
      if (par.length != 2) {
        throw ArgumentError(
            'Toda tarefa precisa da sessão anterior e posterior; não descarte falhas.');
      }
      final a = par['antes']!, d = par['depois']!;
      if (a['contexto_comparavel'] != d['contexto_comparavel']) {
        throw ArgumentError(
            'As sessões do par usam dados ou objetivos diferentes.');
      }
      antes += a['intervencoes'] as int;
      depois += d['intervencoes'] as int;
      tempoAntes += a['segundos_ativos'] as int;
      tempoDepois += d['segundos_ativos'] as int;
      correcoesAntes += a['correcoes'] as int;
      correcoesDepois += d['correcoes'] as int;
      latencia += d['latencia_ia_ms'] as int;
      custo += (d['custo_ia'] as num).toDouble();
      qualidade = qualidade &&
          a['concluida'] == true &&
          d['concluida'] == true &&
          d['validacao_quantidades'] == true &&
          d['sem_duplicidades'] == true &&
          d['sem_alterar_fatos'] == true &&
          a['medicao_completa'] != false &&
          d['medicao_completa'] != false &&
          d['erros'] <= a['erros'];
    }
    if (antes == 0) {
      throw ArgumentError(
          'A linha de base tem zero intervenções; não há redução percentual calculável.');
    }
    final reducao = 100 * (1 - depois / antes);
    final completa = cobertura.length == cenarios.length * tarefas.length &&
        participantes.length >= 5 &&
        coberturaPorParticipante.values
            .every((c) => c.length == cenarios.length * tarefas.length);
    return {
      'pares': pares.length,
      'participantes': participantes.length,
      'intervencoes_antes': antes,
      'intervencoes_depois': depois,
      'reducao_percentual': reducao,
      'segundos_antes': tempoAntes,
      'segundos_depois': tempoDepois,
      'correcoes_antes': correcoesAntes,
      'correcoes_depois': correcoesDepois,
      'custo_ia_depois': custo,
      'latencia_ia_ms_depois': latencia,
      'cobertura_piloto_completa': completa,
      'qualidade_preservada': qualidade,
      'motivos_meta_nao_comprovada': [
        if (!completa)
          'Falta cobertura pareada das 16 combinações por participante, com ao menos cinco participantes.',
        if (!qualidade)
          'Há tarefa inconclusa ou verificação de qualidade reprovada.',
        if (correcoesDepois > correcoesAntes)
          'As correções aumentaram no conjunto observado.',
        if (reducao < 70) 'A redução observada é inferior a 70%.',
      ],
      'meta_70_no_piloto': completa &&
          qualidade &&
          correcoesDepois <= correcoesAntes &&
          reducao >= 70,
      'meta_80_no_piloto': completa &&
          qualidade &&
          correcoesDepois <= correcoesAntes &&
          reducao >= 80,
      'limite':
          'Resultado das sessões observadas informadas; não prova calibração de consumo nem generalização estatística.',
    };
  }
}
