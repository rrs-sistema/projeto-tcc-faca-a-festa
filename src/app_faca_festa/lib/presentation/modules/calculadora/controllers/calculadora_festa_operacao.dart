part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaOperacao on CalculadoraFestaController {
  Map<String, dynamic>? regraPersistida(String id) {
    final exec = OperacaoCalculadoraService.mapa(operacaoEvento['execucao']);
    for (final raw in OperacaoCalculadoraService.lista(exec['regras'])) {
      if (raw['id'] == id) {
        return Map<String, dynamic>.from(jsonDecode(jsonEncode(raw)) as Map);
      }
    }
    return null;
  }

  Future<void> salvarItemManual(ItemEstimativaFinanceira item,
      {required Map<String, dynamic>? anterior}) async {
    if (!possuiEventoVinculado) {
      adicionarItemManual(item);
      return;
    }
    final evento = idEventoAtual.value;
    final sessao = sessaoPlanejador;
    if ((item.premissas['id_evento']?.toString() ?? '').isNotEmpty &&
        item.premissas['id_evento'] != evento) {
      throw StateError('O ajuste pertence a outro evento.');
    }
    final regra =
        item.copyWith(premissas: {...item.premissas, 'id_evento': evento});
    await alterarOperacao({
      'tipo': 'regras',
      'regras': [regra.toPlanejamento()],
      'anteriores': {regra.id: anterior}
    });
    if (idEventoAtual.value != evento ||
        usandoContextoHistorico.value ||
        sessao != sessaoPlanejador) return;
    adicionarItemManual(regra);
    _regrasExecucaoRecebidas[regra.id] =
        assinaturaExecucao(regra.toPlanejamento());
  }

  Future<void> salvarAjustesManuais() async {
    if (!possuiEventoVinculado ||
        usandoContextoHistorico.value ||
        regrasManuais.isEmpty) {
      return;
    }
    final evento = idEventoAtual.value;
    if (regrasManuais.any((r) =>
        (r.premissas['id_evento']?.toString() ?? '').isNotEmpty &&
        r.premissas['id_evento'] != evento)) {
      throw StateError(
          'Há ajustes de outro evento. Atualize os dados antes de salvar.');
    }
    final regras = regrasManuais
        .map(
            (r) => r.copyWith(premissas: {...r.premissas, 'id_evento': evento}))
        .toList();
    await alterarOperacao({
      'tipo': 'regras',
      'regras': regras.map((r) => r.toPlanejamento()).toList(),
      'anteriores': {for (final r in regras) r.id: regraPersistida(r.id)}
    });
    if (idEventoAtual.value != evento || usandoContextoHistorico.value) return;
    for (final r in regras) {
      regrasManuais.removeWhere((atual) => atual.id == r.id);
      regrasManuais.add(r);
      _regrasExecucaoRecebidas[r.id] = assinaturaExecucao(r.toPlanejamento());
    }
    calcular();
  }

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

  Future<void> iniciarOperacaoEvento({bool aguardarPrimeira = false}) async {
    final primeira = Completer<void>();
    void concluir() {
      if (!primeira.isCompleted) primeira.complete();
    }

    consultaOperacaoIniciada.value = true;
    unawaited(carregarPreferencias().catchError((Object _) {}));
    final usuario = _uidAtual;
    final versao = ++_versaoOperacao;
    final anterior = _operacaoSubscription;
    _operacaoSubscription = null;
    await anterior?.cancel();
    if (versao != _versaoOperacao) return;
    final id = idEventoAtual.value;
    if (id.isEmpty || usandoContextoHistorico.value) return;
    operacaoCarregada.value = false;
    erroOperacao.value = '';
    try {
      _operacaoSubscription =
          _repository.observarOperacaoEvento(id).listen((dados) {
        if (usuario != _uidAtual ||
            versao != _versaoOperacao ||
            id != idEventoAtual.value ||
            usandoContextoHistorico.value) {
          return;
        }
        if ((dados['revisao'] as num? ?? 0) <
            (operacaoEvento['revisao'] as num? ?? 0)) {
          return;
        }
        restaurarRegrasExecucao(dados);
        restaurarConfiguracaoEntrada(dados);
        operacaoEvento.assignAll(dados);
        operacaoCarregada.value = true;
        concluir();
        erroOperacao.value = '';
        calcular();
      }, onError: (Object e) {
        if (usuario != _uidAtual ||
            versao != _versaoOperacao ||
            id != idEventoAtual.value ||
            usandoContextoHistorico.value) {
          return;
        }
        operacaoCarregada.value = false;
        erroOperacao.value =
            'Não foi possível consultar público, grupos e estoque da festa. Tente novamente.';
        concluir();
        _agendarAnaliseIA();
      });
    } catch (_) {
      if (usuario != _uidAtual ||
          versao != _versaoOperacao ||
          usandoContextoHistorico.value) {
        return;
      }
      operacaoCarregada.value = false;
      erroOperacao.value =
          'Não foi possível consultar público, grupos e estoque da festa. Tente novamente.';
      concluir();
    }
    if (aguardarPrimeira) {
      await primeira.future.timeout(const Duration(seconds: 8), onTimeout: () {
        if (usuario == _uidAtual &&
            versao == _versaoOperacao &&
            !usandoContextoHistorico.value) {
          operacaoCarregada.value = false;
          erroOperacao.value =
              'A confirmação do planejamento está indisponível. Atualize antes de calcular.';
        }
      });
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
    final usuario = _uidAtual;
    final geracao = _versaoPreparacao;
    final id = idEventoAtual.value;
    if (escritaContextoPendente.value) {
      throw StateError('Aguarde a confirmação do planejamento.');
    }
    escritaContextoPendente.value = true;
    try {
      final resultado = await _repository.alterarOperacaoEvento(id, {
        ...acao,
        'revisao': acao['revisao'] ?? operacaoEvento['revisao'] ?? 0
      });
      if (usuario != _uidAtual ||
          geracao != _versaoPreparacao ||
          id != idEventoAtual.value ||
          usandoContextoHistorico.value) {
        return;
      }
      if ((resultado['revisao'] as num? ?? 0) <
          (operacaoEvento['revisao'] as num? ?? 0)) {
        return;
      }
      operacaoEvento.assignAll(resultado);
      calcular();
    } finally {
      if (geracao == _versaoPreparacao) {
        escritaContextoPendente.value = false;
        _agendarAnaliseIA();
      }
    }
  }
}
