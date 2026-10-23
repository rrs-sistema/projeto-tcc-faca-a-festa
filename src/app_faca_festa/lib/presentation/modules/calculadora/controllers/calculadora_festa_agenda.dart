part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaAgenda on CalculadoraFestaController {
  List<OcorrenciaServico> get agendaServicos => const AgendaServicoService()
      .ler(operacaoEvento['agenda'], evento: idEventoAtual.value)
      .toList()
    ..sort((a, b) =>
        '${a.dataLocal ?? '9999-99-99'}/${a.horaLocal ?? '99:99'}/${a.id}'
            .compareTo(
                '${b.dataLocal ?? '9999-99-99'}/${b.horaLocal ?? '99:99'}/${b.id}'));
  String tituloDaOcorrencia(String id, String titulo) {
    final o =
        const AgendaServicoService().porCardapio(Map.of(operacaoEvento), id);
    return o == null
        ? titulo
        : OcorrenciaServico.fromMap({...o, 'titulo': titulo}).resumo;
  }

  Future<void> confirmarOcorrencia(OcorrenciaServico o,
      {required int revisao,
      required String pedido,
      required Map<String, dynamic> config,
      required List<CardapioItem> itensModelo,
      bool somenteModelo = true}) async {
    if (usandoContextoHistorico.value ||
        o.evento != idEventoAtual.value ||
        !possuiEventoVinculado) {
      throw StateError('Abra o planejamento atual do evento desta ocorrência.');
    }
    o.validar();
    final itens = [
      for (final i in itensModelo)
        {
          'id_item': i.idItem,
          'nome': i.nome,
          'tipo': i.tipo.name,
          'publico_alvo': i.publicoAlvo.name,
          'unidade': i.unidade
        }
    ]..sort((a, b) => a['id_item']!.compareTo(b['id_item']!));
    final evento = idEventoAtual.value,
        usuario = _uidAtual,
        geracao = _versaoPreparacao;
    await alterarOperacao({
      'tipo': 'agenda',
      'ocorrencia': o.toMap(),
      'config': config,
      'revisao': revisao,
      'pedido': pedido,
      'somente_modelo': somenteModelo,
      'fonte_itens': itens
    });
    if (evento != idEventoAtual.value ||
        usuario != _uidAtual ||
        geracao != _versaoPreparacao) {
      return;
    }
    final atual = const AgendaServicoService()
        .porCardapio(Map.of(operacaoEvento), o.cardapio);
    if (assinaturaExecucao(atual) != assinaturaExecucao(o.toMap())) {
      throw StateError(
          'A ocorrência mudou em outro acesso. Seus valores foram mantidos para revisão.');
    }
    final confirmada = const OperacaoCalculadoraService()
        .refeicao(Map.of(operacaoEvento), o.cardapio);
    if (config.entries.any((e) =>
        assinaturaExecucao(e.value) != assinaturaExecucao(confirmada[e.key]))) {
      throw StateError(
          'O público desta ocorrência mudou em outro acesso. Revise antes de confirmar novamente.');
    }
    calcular();
  }
}
