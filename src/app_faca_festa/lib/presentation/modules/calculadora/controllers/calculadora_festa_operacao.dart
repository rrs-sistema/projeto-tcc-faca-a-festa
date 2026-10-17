part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaOperacao on CalculadoraFestaController {
  static const _motorOperacao = OperacaoCalculadoraService();

  List<String> restricoesDoItem(ItemEstimativaFinanceira regra) {
    final config = _motorOperacao.refeicao(
        Map<String, dynamic>.from(operacaoEvento), _cardapioConsolidadoAtual);
    final destino = OperacaoCalculadoraService.mapa(
        OperacaoCalculadoraService.mapa(
            config['destinos_itens'])[regra.premissas['id_item_cardapio']]);
    final modo = destino['modo']?.toString() ?? 'todos';
    return [
      modo,
      for (final g in OperacaoCalculadoraService.lista(config['grupos']))
        if (modo == 'demais' ||
            (destino['grupos'] as List? ?? []).contains(g['id']))
          (List<String>.from(g['restricoes'] as List)..sort()).join('+')
    ];
  }

  ItemEstimativaFinanceira regraDoPublico(ItemEstimativaFinanceira regra) =>
      _motorOperacao.regraComPublico(
          regra,
          _motorOperacao.refeicao(
              Map<String, dynamic>.from(operacaoEvento),
              regra.premissas['id_cardapio']?.toString() ??
                  _cardapioConsolidadoAtual),
          publicoEvento);

  ConvidadosEquivalentes publicoDaRefeicao(String id) => _motorOperacao.publico(
      _motorOperacao.refeicao(Map<String, dynamic>.from(operacaoEvento), id),
      publicoEvento);

  CalculadoraFesta calculoDaRefeicao(CalculadoraFesta calculo, String id) {
    final p = publicoDaRefeicao(id);
    return calculo.copyWith(
        totalAdultos: p.adultos,
        totalCriancas: p.criancas,
        totalBebes: p.bebes);
  }

  ItemListaCompras analisarCompra(
      CalculadoraFestaItem resultado,
      ItemEstimativaFinanceira? regra,
      List<CardapioItem> itens,
      String refeicao) {
    final item = _revisao.correspondente(resultado, itens);
    double? reservado;
    String? erro = !operacaoCarregada.value || erroOperacao.value.isNotEmpty
        ? 'O estoque da festa ainda não foi consultado. Atualize o planejamento antes de concluir a compra.'
        : null;
    if (item != null) {
      try {
        reservado = _motorOperacao.reservado(
            Map<String, dynamic>.from(operacaoEvento),
            item,
            resultado.unidade,
            (regra?.premissas['estado_compra'] ??
                    regra?.premissas['estado'] ??
                    '')
                .toString());
      } catch (e) {
        erro = e.toString();
      }
    }
    return const ListaComprasCalculadoraService().analisar(
        resultado: resultado,
        regra: regra,
        cardapio: itens,
        compromissos: compromissosOrcamento.toList(),
        convidados: publicoDaRefeicao(refeicao),
        perfil: perfilSelecionado.value,
        duracao: duracaoHoras.value,
        margem: margemPersonalizada.value,
        estoqueReservado: reservado,
        erroEstoque: erro,
        exigirEstoqueCentral: true);
  }

  List<String> pendenciasAlimentares(
      String id, List<ItemEstimativaFinanceira> regras) {
    try {
      return _motorOperacao.analisarGrupos(
          _motorOperacao.refeicao(
              Map<String, dynamic>.from(operacaoEvento), id),
          const ComposicaoRefeicaoService()
              .compor(regras.map(regraDoPublico).toList()),
          publicoEvento,
          perfilSelecionado.value,
          duracaoHoras.value,
          margemPersonalizada.value);
    } catch (_) {
      return [
        'Configuração alimentar inválida. Confira público, grupos e porções destinadas.'
      ];
    }
  }

  List<String> get pendenciasAlimentaresEvento => [
        ...pendenciasAlimentares(_cardapioConsolidadoAtual, itensParaCalculo)
            .map((p) => '$tituloCardapio: $p'),
        for (final e in cardapiosEvento.entries
            .where((e) => e.key != _cardapioConsolidadoAtual))
          ...pendenciasAlimentares(
                  e.key,
                  e.value
                      .map((i) => _revisao.regraPara(i, regrasDisponiveis))
                      .whereType<ItemEstimativaFinanceira>()
                      .toList())
              .map((p) => '${titulosCardapiosEvento[e.key] ?? e.key}: $p')
      ];

  Future<void> iniciarOperacaoEvento() async {
    final versao = ++_versaoOperacao;
    await _operacaoSubscription?.cancel();
    final id = idEventoAtual.value;
    if (id.isEmpty || usandoContextoHistorico.value) return;
    operacaoCarregada.value = false;
    erroOperacao.value = '';
    try {
      _operacaoSubscription =
          _repository.observarOperacaoEvento(id).listen((dados) {
        if (versao != _versaoOperacao ||
            id != idEventoAtual.value ||
            usandoContextoHistorico.value) {
          return;
        }
        if ((dados['revisao'] as num? ?? 0) <
            (operacaoEvento['revisao'] as num? ?? 0)) {
          return;
        }
        operacaoEvento.assignAll(dados);
        operacaoCarregada.value = true;
        erroOperacao.value = '';
        calcular();
      }, onError: (Object e) {
        if (versao != _versaoOperacao ||
            id != idEventoAtual.value ||
            usandoContextoHistorico.value) {
          return;
        }
        operacaoCarregada.value = false;
        erroOperacao.value =
            'Não foi possível consultar público, grupos e estoque da festa. Tente novamente.';
        _agendarAnaliseIA();
      });
    } catch (_) {
      operacaoCarregada.value = false;
      erroOperacao.value =
          'Não foi possível consultar público, grupos e estoque da festa. Tente novamente.';
    }
  }

  Future<void> alterarOperacao(Map<String, dynamic> acao) async {
    if (usandoContextoHistorico.value ||
        !operacaoCarregada.value ||
        erroOperacao.value.isNotEmpty ||
        idEventoAtual.value.isEmpty) {
      throw StateError(
          'Atualize os dados do evento antes de alterar o planejamento.');
    }
    final id = idEventoAtual.value;
    final resultado = await _repository.alterarOperacaoEvento(id, {
      ...acao,
      'revisao': acao['revisao'] ?? operacaoEvento['revisao'] ?? 0
    });
    if (id != idEventoAtual.value || usandoContextoHistorico.value) return;
    operacaoEvento.assignAll(resultado);
    calcular();
  }
}
