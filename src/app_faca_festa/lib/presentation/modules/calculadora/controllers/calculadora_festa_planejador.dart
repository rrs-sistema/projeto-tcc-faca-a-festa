part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaPlanejador on CalculadoraFestaController {
  String get sessaoPlanejador => assinaturaExecucao(
      [_uidAtual, _versaoPreparacao, idEventoAtual.value, idCardapioAtual]);
  Map<String, dynamic> get decisaoPlanejador =>
      OperacaoCalculadoraService.mapa(OperacaoCalculadoraService.mapa(
          operacaoEvento['planejador'])[idCardapioAtual]);
  Map<String, dynamic> get dimensoesConsumoPlanejador {
    final cfg = const OperacaoCalculadoraService()
            .refeicao(Map.of(operacaoEvento), idCardapioAtual),
        o = OperacaoCalculadoraService.mapa(cfg['ocorrencia']);
    if (o.isEmpty && decisaoPlanejador.isEmpty) return {};
    return {
      'servico': cfg['servico'],
      'formato': o['formato'],
      'duracao_minutos': o['duracao_minutos'],
      'hora_local': o['hora_local'],
      'infraestrutura':
          OperacaoCalculadoraService.mapa(decisaoPlanejador['infraestrutura'])
    };
  }

  ContextoServicoPlanejador get contextoServicoPlanejador {
    final cfg = const OperacaoCalculadoraService()
            .refeicao(Map.of(operacaoEvento), idCardapioAtual),
        o = OperacaoCalculadoraService.mapa(cfg['ocorrencia']);
    return ContextoServicoPlanejador(
        evento: idEventoAtual.value,
        cardapio: idCardapioAtual,
        publico: publicoDaRefeicao(idCardapioAtual),
        origemPublico:
            cfg['publico'] != null ? 'proprio' : baseCalculo.value.name,
        itens: itensCardapio.toList(),
        regras: regrasDisponiveis,
        servico: cfg['servico'],
        formato: o['formato'] == 'nao_definido' ? null : o['formato'],
        data: o['data_local'],
        hora: o['hora_local'],
        minutos: o['duracao_minutos'],
        objetivo: decisaoPlanejador['objetivo'],
        infraestrutura: Map<String, bool?>.from(OperacaoCalculadoraService.mapa(
            decisaoPlanejador['infraestrutura'])),
        verba: verbaAlimentacao.value,
        compromissos: compromissosOrcamento.toList(),
        grupos: OperacaoCalculadoraService.lista(cfg['grupos']),
        destinos: OperacaoCalculadoraService.mapa(cfg['destinos_itens']),
        catalogoVersoes:
            catalogoContextual.value.referencias.map((r) => r.chave).toList());
  }

  Future<ContextoExecucaoPlano> prepararPlanejador() async {
    final usuario = _uidAtual,
        evento = idEventoAtual.value,
        geracao = _versaoPreparacao;
    final menu = idCardapioAtual, repo = _repository;
    if (repo is! ExecucaoCalculadoraRepository) {
      throw StateError('A consulta do planejamento não está disponível.');
    }
    final fonte = await (repo as ExecucaoCalculadoraRepository)
        .carregarContextoExecucao(evento);
    if (usuario != _uidAtual ||
        evento != idEventoAtual.value ||
        geracao != _versaoPreparacao ||
        menu != idCardapioAtual ||
        usandoContextoHistorico.value) {
      throw StateError('O contexto mudou. Reabra o planejador.');
    }
    operacaoEvento.assignAll(fonte.operacao);
    restaurarRegrasExecucao(fonte.operacao);
    calcular();
    return fonte;
  }

  ResultadoPlanejadorHibrido proporPlanejador(
      {Map<String, String> respostas = const {},
      List<RegistroConsumoCalculadora> consumos = const []}) {
    final observados = <String, ResumoConsumoObservado>{},
        bases = <String, ItemEstimativaFinanceira>{};
    final cfg = const OperacaoCalculadoraService()
        .refeicao(Map.of(operacaoEvento), idCardapioAtual);
    final infra = {...dimensoesConsumoPlanejador};
    if (infra.isNotEmpty) {
      final declarada =
          OperacaoCalculadoraService.mapa(infra['infraestrutura']);
      for (final k in ContextoServicoPlanejador.recursos) {
        final v = respostas['infra_$k'];
        if (v == 'sim' || v == 'nao') declarada[k] = v == 'sim';
      }
      infra['infraestrutura'] = declarada;
    }
    for (final i in itensCardapio) {
      var r = _revisao.regraPara(i, regrasDisponiveis);
      if (r == null) {
        final candidatos = consumos
            .where((registro) =>
                RevisaoCardapioService.normalizar(registro.regra.nome) ==
                    RevisaoCardapioService.normalizar(i.nome) &&
                registro.regra.publicoAlvo == i.publicoAlvo.name &&
                RevisaoCardapioService.unidade(registro.regra.unidade.label) ==
                    RevisaoCardapioService.unidade(i.unidade))
            .toList()
          ..sort((a, b) => b.dataRegistro.compareTo(a.dataRegistro));
        if (candidatos.isNotEmpty) {
          r = candidatos.first.regra
              .copyWith(id: 'menu_${i.idCardapio}_${i.idItem}', premissas: {
            ...candidatos.first.regra.premissas,
            'id_evento': i.idEvento,
            'id_cardapio': i.idCardapio,
            'id_item_cardapio': i.idItem
          });
          bases[i.idItem] = r;
        }
      }
      if (r == null) continue;
      final contexto = const ConsumoObservadoService().contexto(
          r, [...itensParaCalculo, if (bases.containsKey(i.idItem)) r],
          servicoPlanejador: infra,
          duracaoHoras: duracaoHoras.value,
          publicoDietario: restricoesDoItem(r),
          gruposAlimentares: OperacaoCalculadoraService.lista(cfg['grupos']),
          refeicao: tituloCardapio,
          tipoEvento: tipoEventoAtual.value,
          itensSemRegra: itensSemRegra
              .where((item) => item.idItem != i.idItem)
              .map((item) => RevisaoCardapioService.identidade(
                  item.nome, item.unidade, item.publicoAlvo.name)));
      observados[i.idItem] = const ConsumoObservadoService().resumir(
          registros: consumos,
          contexto: contexto,
          eventoAtual: idEventoAtual.value,
          pessoas: publicoDaRefeicao(idCardapioAtual));
    }

    return const PlanejadorHibridoService().gerar(
        contexto: contextoServicoPlanejador,
        catalogo: catalogoContextual.value,
        respostas: respostas,
        observados: observados,
        basesObservadas: bases,
        calcular: resultadosDaProposta);
  }

  Future<Map<String, dynamic>> interpretarBriefingPlanejador(
      String texto) async {
    final assinatura = assinaturaProposta, usuario = _uidAtual;
    final repo = _repository;
    if (repo is! PlanejadorHibridoRepository) {
      throw StateError(
          'Leitura indisponível neste ambiente; o cálculo continua disponível.');
    }
    final resultado = await (repo as PlanejadorHibridoRepository)
        .sugerirCandidatosPlanejador({
      'evento': idEventoAtual.value,
      'cardapio': idCardapioAtual,
      'texto': texto
    });
    if (usuario != _uidAtual || assinatura != assinaturaProposta) {
      throw StateError(
          'O contexto mudou durante a leitura. Reabra o planejador.');
    }
    // Segundo limite: IDs precisam existir no catálogo já consultado pelo cliente.
    final candidatos =
        OperacaoCalculadoraService.lista(resultado['candidatos']);
    for (final c in candidatos) {
      final item = itensCardapio.where((i) => i.idItem == c['id_item']);
      final refs = catalogoContextual.value.referencias
          .where((r) => r.id == c['referencia_id'] && r.versao == c['versao']);
      if (item.length != 1 ||
          refs.length != 1 ||
          !refs.single.reconhece(item.single.nome)) {
        throw StateError(
            'A leitura retornou um candidato fora do contexto. O cálculo não foi alterado.');
      }
    }
    return resultado;
  }

  Future<void> confirmarPlanoServico(
      {required ContextoExecucaoPlano fontes,
      required ResultadoPlanejadorHibrido proposta,
      required Map<String, String> respostas,
      required String assinatura,
      required String pedido}) async {
    final repo = _repository,
        usuario = _uidAtual,
        evento = idEventoAtual.value,
        menu = idCardapioAtual,
        geracao = _versaoPreparacao;
    if (repo is! PlanejadorHibridoRepository ||
        usandoContextoHistorico.value ||
        assinatura != assinaturaProposta ||
        fontes.evento != evento) {
      throw StateError('Atualize as fontes antes de confirmar.');
    }
    final ctx = contextoServicoPlanejador;
    final infra = <String, bool?>{...ctx.infraestrutura};
    for (final k in ContextoServicoPlanejador.recursos) {
      final v = respostas['infra_$k'];
      if (v == 'sim' || v == 'nao') infra[k] = v == 'sim';
    }
    final decisao = {
      'versao': 1,
      'objetivo': respostas['objetivo'] ?? ctx.objetivo,
      'infraestrutura': infra,
      'respostas': respostas,
      'assinatura_material': ctx.assinatura
    };
    validarDecisaoServicoPlanejador(decisao);
    final regras = proposta.principal.regras
        .map((r) => proposta.principal.preservados.contains(r.id)
            ? r
            : r.copyWith(premissas: {
                ...r.premissas,
                'revisada_pelo_organizador': true,
                'proposta_respostas': respostas
              }))
        .toList();
    final resultado =
        await (repo as PlanejadorHibridoRepository).confirmarPlanejador({
      'evento': evento,
      'cardapio': menu,
      'pedido': pedido,
      'revisao': fontes.operacao['revisao'] ?? 0,
      'fontes': fontes.fontes,
      'decisao': decisao,
      'regras': regras.map((r) => r.toPlanejamento()).toList()
    });
    if (usuario != _uidAtual ||
        evento != idEventoAtual.value ||
        menu != idCardapioAtual ||
        geracao != _versaoPreparacao) {
      return;
    }
    final recebida = OperacaoCalculadoraService.mapa(
        OperacaoCalculadoraService.mapa(resultado['planejador'])[menu]);
    if (assinaturaExecucao(recebida) != assinaturaExecucao(decisao)) {
      throw StateError(
          'A confirmação foi superada por outra revisão. Atualize o planejador.');
    }
    operacaoEvento.assignAll(resultado);
    restaurarRegrasExecucao(resultado);
    calcular();
  }
}
