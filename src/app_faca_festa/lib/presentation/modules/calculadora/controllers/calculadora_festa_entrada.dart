part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaEntrada on CalculadoraFestaController {
  Future<Map<String, dynamic>> interpretarEntradaAssistente(String texto,
      {Map<String, dynamic>? anexo, bool documento = false}) async {
    final repo = _repository;
    if (repo is! EntradaAssistenteCalculadoraRepository ||
        !possuiEventoVinculado ||
        usandoContextoHistorico.value) {
      throw StateError('Abra um evento salvo para usar a leitura inteligente.');
    }
    final contexto = contextoEvento.assinatura;
    final resultado = await (repo as EntradaAssistenteCalculadoraRepository)
        .interpretarEntradaCalculadora({
      'evento': idEventoAtual.value,
      'texto': texto,
      'documento': documento,
      'anexo': anexo ?? {},
      'regras': {
        for (final item in [
          ...cardapiosEvento.values.expand((i) => i),
          ...itensCardapio
        ])
          if (_revisao.regraPara(item, regrasDisponiveis) case final regra?)
            regra.id: regra.toPlanejamento(),
        for (final regra in regrasManuais.where((r) =>
            r.premissas['id_evento'] == idEventoAtual.value &&
            r.premissas['id_item_cardapio'] != null))
          regra.id: regra.toPlanejamento(),
      }.values.toList(),
    });
    if (contexto != contextoEvento.assinatura) {
      throw StateError('O planejamento mudou. Faça a leitura novamente.');
    }
    return resultado;
  }

  Future<bool> aplicarEntradaAssistente(Map<String, dynamic> proposta,
      List<String> selecionadas, String assinatura,
      {bool conferiuDuplicidade = false}) async {
    if (assinatura != assinaturaProposta ||
        usandoContextoHistorico.value ||
        !possuiEventoVinculado ||
        _repository is! EntradaAssistenteCalculadoraRepository) {
      throw StateError('O planejamento mudou. Prepare a leitura novamente.');
    }
    final usuario = _uidAtual;
    final geracao = _versaoPreparacao;
    final evento = idEventoAtual.value;
    final limiteAntes = orcamentoDisponivel.value;
    final regrasAntes = {
      for (final r in regrasManuais)
        r.id: assinaturaExecucao(r.toPlanejamento())
    };
    medicaoUso.registrarDecisao('entrada_inteligente');
    try {
      final aplicado =
          await (_repository as EntradaAssistenteCalculadoraRepository)
              .aplicarEntradaCalculadora({
        'evento': idEventoAtual.value,
        'id': proposta['id'],
        'assinatura': proposta['assinatura'],
        'selecionadas': selecionadas,
        'conferiu_duplicidade': conferiuDuplicidade,
      });
      medicaoUso.registrarResultado('entrada_inteligente', sucesso: true);
      if (usuario == _uidAtual &&
          geracao == _versaoPreparacao &&
          idEventoAtual.value == evento &&
          !usandoContextoHistorico.value) {
        if (aplicado['limite_atual'] is num &&
            orcamentoDisponivel.value == limiteAntes) {
          orcamentoDisponivel.value =
              (aplicado['limite_atual'] as num).toDouble();
        }
        final dados = OperacaoCalculadoraService.mapa(aplicado['operacao']);
        final ids = (aplicado['regras_alteradas'] as List? ?? []).toSet();
        for (final raw in OperacaoCalculadoraService.lista(
            OperacaoCalculadoraService.mapa(dados['execucao'])['regras'])) {
          final r = ItemEstimativaFinanceira.fromPlanejamento(raw);
          if (!ids.contains(r.id) || r.premissas['id_evento'] != evento) {
            continue;
          }
          final atuais = regrasManuais.where((a) => a.id == r.id).toList();
          if (atuais.isNotEmpty &&
              regrasAntes[r.id] !=
                  assinaturaExecucao(atuais.single.toPlanejamento()) &&
              assinaturaExecucao(atuais.single.toPlanejamento()) !=
                  assinaturaExecucao(raw)) {
            continue;
          }
          regrasManuais.removeWhere((a) => a.id == r.id);
          regrasManuais.add(r);
          _regrasExecucaoRecebidas[r.id] =
              assinaturaExecucao(r.toPlanejamento());
        }
        if ((dados['revisao'] as num? ?? 0) >=
            (operacaoEvento['revisao'] as num? ?? 0)) {
          restaurarConfiguracaoEntrada(dados);
          operacaoEvento.assignAll(dados);
        }
        calcular();
      }
      return aplicado['aplicado'] == true;
    } catch (_) {
      medicaoUso.registrarResultado('entrada_inteligente', sucesso: false);
      rethrow;
    }
  }

  void restaurarConfiguracaoEntrada(Map<String, dynamic> op) {
    final cfg =
        OperacaoCalculadoraService.mapa(op['configuracao_planejamento']);
    if (cfg.isEmpty || usandoContextoHistorico.value) return;
    restaurarEscolhasConfiguracao(cfg);
  }
}
