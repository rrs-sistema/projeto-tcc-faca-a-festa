part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaHistorico on CalculadoraFestaController {
  Future<void> salvarCalculo() async {
    if (salvando.value) return;
    final calculo = calculoAtual.value;

    if (!possuiEventoVinculado) {
      Get.snackbar(
        'Estimativa ainda não vinculada',
        'Salve o evento primeiro para gravar este cálculo no histórico.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (calculo == null || !possuiResultado) {
      Get.snackbar(
        'Atenção',
        'Calcule as quantidades antes de salvar.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      salvando.value = true;
      await salvarAjustesManuais();
      final versao = _versaoAnaliseIA.value;

      final calculoParaSalvar = (calculoAtual.value ?? calculo).copyWith(
        contextoPlanejamento: snapshotPlanejamento,
        orcamentoDisponivel: orcamentoDisponivel.value,
        limparOrcamentoDisponivel: orcamentoDisponivel.value == null,
        analiseIA: analiseIA.value,
        limparAnaliseIA: analiseIA.value == null,
        dataAtualizacao: DateTime.now(),
        idUsuario: calculo.idUsuario ?? _uidAtual,
      );

      await _repository.salvarSimulacao(
        calculo: calculoParaSalvar,
        itens: itensCalculados.toList(),
      );
      medicaoUso.registrarResultado('salvar_simulacao', sucesso: true);

      if (versao == _versaoAnaliseIA.value &&
          calculoAtual.value?.idCalculo == calculoParaSalvar.idCalculo) {
        calculoAtual.value = calculoParaSalvar;
      }
      await carregarSimulacoesSalvas();

      Get.snackbar(
        'Simulação salva',
        'A simulação foi salva com sucesso.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } on FirebaseException catch (e) {
      medicaoUso.registrarResultado('salvar_simulacao', sucesso: false);
      final mensagem = e.code == 'permission-denied'
          ? 'Sem permissão para salvar. Confirme que você está logado e é o organizador desta festa.'
          : 'Não foi possível salvar a simulação: ${e.message ?? e.code}';
      Get.snackbar(
        'Erro',
        mensagem,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      medicaoUso.registrarResultado('salvar_simulacao', sucesso: false);
      Get.snackbar(
        'Erro',
        'Não foi possível salvar a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      salvando.value = false;
    }
  }

  Future<void> carregarSimulacoesSalvas() async {
    final geracao = _versaoPreparacao;
    final evento = idEventoAtual.value;
    if (!possuiEventoVinculado) {
      simulacoesSalvas.clear();
      return;
    }

    try {
      carregandoSimulacoes.value = true;
      final simulacoes = await _repository.listarSimulacoesPorEvento(evento);
      if (geracao != _versaoPreparacao || evento != idEventoAtual.value) return;
      simulacoesSalvas.assignAll(simulacoes);
    } catch (e) {
      if (geracao != _versaoPreparacao) return;
      Get.snackbar(
        'Erro',
        'Não foi possível carregar as simulações: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      if (geracao == _versaoPreparacao) carregandoSimulacoes.value = false;
    }
  }

  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(
      String idCalculo) async {
    return _repository.listarItensDaSimulacao(idCalculo);
  }

  /// Aplica uma simulação salva no estado atual da calculadora.
  ///
  /// Uso principal: BottomSheet "Minhas simulações". O usuário abre um cenário
  /// antigo, revisa os itens e pode continuar trabalhando sobre ele.
  Future<void> carregarSimulacaoNoEditor(CalculadoraFesta simulacao) async {
    final preparacao = ++_versaoPreparacao;
    _versaoCarregamentoItens++;
    carregandoItensBase.value = false;
    _agendarAnaliseIA();
    try {
      loading.value = true;

      final itens = await _repository.listarItensDaSimulacao(
        simulacao.idCalculo,
      );

      if (preparacao != _versaoPreparacao) return;
      usandoContextoHistorico.value = true;
      idEventoAtual.value = simulacao.idEvento;
      tipoEventoAtual.value = simulacao.tipoEvento;
      estimativaSemEvento.value = false;
      baseCalculo.value = simulacao.baseCalculo;
      perfilSelecionado.value = simulacao.perfilFesta;
      margemPersonalizada.value = simulacao.margemPersonalizada;
      orcamentoDisponivel.value = simulacao.orcamentoDisponivel;
      totalAdultos.value = _normalizarQuantidade(simulacao.totalAdultos);
      totalCriancas.value = _normalizarQuantidade(simulacao.totalCriancas);
      totalBebes.value = _normalizarQuantidade(simulacao.totalBebes);
      duracaoHoras.value =
          simulacao.duracaoHoras <= 0 ? 4 : simulacao.duracaoHoras;
      calculoAtual.value = simulacao;
      analiseIA.value = _historicoMotorAntigo ? null : simulacao.analiseIA;
      revisarCardapio.value = false;
      regrasManuais.clear();
      itensEstimativa.assignAll(itens.map((item) => ItemEstimativaFinanceira(
            id: item.idItemResultado.startsWith('${simulacao.idCalculo}_')
                ? item.idItemResultado.substring(simulacao.idCalculo.length + 1)
                : item.idItemResultado,
            categoria: item.categoria,
            nome: item.nome,
            tipoItem: item.tipoItem,
            publicoAlvo: item.publicoAlvo,
            unidade: _unidadeEstimativaFromString(item.unidade),
            quantidadePorConvidadoEquivalente:
                item.quantidadePorConvidadoEquivalente,
            valorUnitarioMedio: item.valorUnitarioMedio,
          )));
      _modoEscolhido = true;
      final contexto = simulacao.contextoPlanejamento;
      final politica =
          OperacaoCalculadoraService.mapa(contexto['politica_publico']);
      basePublicoConfirmada.value = politica['base_confirmada'] != false;
      completudeLista.value = completudeDaLista(politica['lista_completude']);
      restaurarVerbaAlimentacao(contexto['verba_alimentacao']);
      _versaoOperacao++;
      await _operacaoSubscription?.cancel();
      _operacaoSubscription = null;
      operacaoEvento
          .assignAll(OperacaoCalculadoraService.mapa(contexto['operacao']));
      operacaoCarregada.value = contexto['operacao'] is Map;
      erroOperacao.value = '';
      final publicoSalvo =
          OperacaoCalculadoraService.mapa(contexto['publico_evento']);
      if (publicoSalvo.isNotEmpty) {
        totalAdultos.value =
            OperacaoCalculadoraService.inteiro(publicoSalvo['adultos']);
        totalCriancas.value =
            OperacaoCalculadoraService.inteiro(publicoSalvo['criancas']);
        totalBebes.value =
            OperacaoCalculadoraService.inteiro(publicoSalvo['bebes']);
      }

      if (contexto['regras'] is List) {
        itensEstimativa.assignAll((contexto['regras'] as List).map((r) =>
            ItemEstimativaFinanceira.fromPlanejamento(
                Map<String, dynamic>.from(r as Map))));
        if (contexto['regras_catalogo'] is List &&
            contexto['regras_manuais'] is List) {
          itensEstimativa.assignAll((contexto['regras_catalogo'] as List).map(
              (r) => ItemEstimativaFinanceira.fromPlanejamento(
                  Map<String, dynamic>.from(r as Map))));
          regrasManuais.assignAll((contexto['regras_manuais'] as List).map(
              (r) => ItemEstimativaFinanceira.fromPlanejamento(
                  Map<String, dynamic>.from(r as Map))));
        }
        revisarCardapio.value = contexto['modo_revisao'] == true;
        idCardapioAtual = contexto['id_cardapio']?.toString() ?? '';
        tituloCardapio = contexto['titulo_cardapio']?.toString() ?? '';
        escopoCardapioAtual =
            EscopoCardapio.fromString(contexto['escopo_cardapio']?.toString());
        cardapioDisponivel.value = contexto['cardapio_disponivel'] == true;
        regrasRejeitadas.assignAll(
            List<String>.from(contexto['regras_rejeitadas'] as List? ?? []));
        itensCardapio
            .assignAll((contexto['cardapio'] as List? ?? []).map((raw) {
          final i = Map<String, dynamic>.from(raw as Map);
          return CardapioItem(
              idItem: i['id'] as String,
              idEvento: i['evento'] as String,
              idCardapio: i['cardapio'] as String,
              nome: i['nome'] as String,
              tipo: TipoItemCardapio.fromString(i['tipo'] as String),
              publicoAlvo:
                  PublicoAlvoCardapio.fromString(i['publico'] as String),
              unidade: i['unidade'] as String,
              quantidadeFinal: (i['final'] as num).toDouble(),
              quantidadeSugerida: (i['sugerida'] as num).toDouble(),
              confirmado: i['confirmado'] == true,
              disponibilidade:
                  DisponibilidadeCardapio.fromMap(i['disponibilidade']));
        }));
        await _orcamentoSubscription?.cancel();
        _orcamentoSubscription = null;
        _versaoOrcamento++;
        compromissosOrcamento.assignAll(
            (contexto['compromissos'] as List? ?? [])
                .map((g) => Map<String, dynamic>.from(g as Map)));
        carregandoOrcamento.value = false;
        erroOrcamento.value = (contexto['financeiro']
                    as Map?)?['orcamento_carregado'] ==
                false
            ? 'A consulta financeira estava incompleta nesta simulação. Atualize para consultar os dados atuais.'
            : '';
      }
      cardapiosEvento.clear();
      titulosCardapiosEvento.clear();
      final todos = contexto['cardapios_evento'];
      if (todos is Map) {
        for (final e in todos.entries) {
          cardapiosEvento[e.key.toString()] = (e.value as List)
              .map((i) => restaurarItem(Map<String, dynamic>.from(i as Map)))
              .toList();
        }
        titulosCardapiosEvento.assignAll(Map<String, String>.from(
            contexto['titulos_cardapios_evento'] as Map? ?? {}));
      }
      consultaCardapiosCompleta.value =
          todos is Map && contexto['consulta_cardapios_completa'] == true;
      origemItensCalculadora.value = OrigemItensCalculadora.simulacao;
      itensCalculados.assignAll(itens);

      // Mantém a estimativa em memória coerente para novas análises de IA.
      estimativaAtual.value = _service.calcularEstimativa(
        calculo: simulacao,
        itensBase: itensParaCalculo,
      );
      if (analiseIA.value == null) {
        _agendarAnaliseIA();
      }
      if (_historicoMotorAntigo) {
        erroAnaliseIA.value = CalculadoraFestaAnaliseIa._avisoHistoricoAntigo;
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> aprovarSimulacao(String idCalculo) async {
    try {
      await _repository.atualizarStatusSimulacao(
        idCalculo: idCalculo,
        status: StatusSimulacaoCalculadora.aprovada,
      );
      await carregarSimulacoesSalvas();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível aprovar a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> excluirSimulacao(String idCalculo) async {
    try {
      await _repository.excluirSimulacao(idCalculo);
      simulacoesSalvas.removeWhere((item) => item.idCalculo == idCalculo);

      if (calculoAtual.value?.idCalculo == idCalculo) {
        calculoAtual.value = null;
        itensCalculados.clear();
        estimativaAtual.value = null;
        analiseIA.value = null;
        _agendarAnaliseIA();
      }

      Get.snackbar(
        'Simulação excluída',
        'A simulação foi removida com sucesso.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível excluir a simulação: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Converte uma simulação aprovada em itens oficiais do orçamento.
  ///
  /// Fluxo:
  /// 1. Valida se a simulação pertence a um evento salvo.
  /// 2. Exige status "aprovada" para evitar converter rascunhos por acidente.
  /// 3. Cria/atualiza os itens na coleção de orçamento.
  /// 4. Marca os itens da calculadora como enviados para orçamento.
  /// 5. Marca a simulação como convertida.
  Future<void> transformarSimulacaoEmOrcamento(
      CalculadoraFesta simulacao) async {
    if (simulacao.idEvento.trim().isEmpty ||
        simulacao.idEvento == 'estimativa_temporaria') {
      Get.snackbar(
        'Evento não salvo',
        'Salve o evento antes de transformar a simulação em orçamento.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (simulacao.convertidoEmOrcamento ||
        simulacao.statusSimulacao ==
            StatusSimulacaoCalculadora.convertidaOrcamento) {
      Get.snackbar(
        'Simulação já convertida',
        'Esta simulação já foi transformada em orçamento.',
        backgroundColor: Colors.blueGrey,
        colorText: Colors.white,
      );
      return;
    }

    if (simulacao.statusSimulacao != StatusSimulacaoCalculadora.aprovada) {
      Get.snackbar(
        'Aprovação necessária',
        'Aprove a simulação antes de transformar em orçamento.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      convertendoOrcamento.value = true;

      final itens = await _repository.listarItensDaSimulacao(
        simulacao.idCalculo,
      );
      final itensPendentes =
          itens.where((item) => !item.adicionadoAoOrcamento).toList();

      if (itensPendentes.isEmpty) {
        await _repository.marcarComoConvertidaEmOrcamento(simulacao.idCalculo);
        await carregarSimulacoesSalvas();

        Get.snackbar(
          'Orçamento já atualizado',
          'Não há novos itens pendentes para adicionar ao orçamento.',
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
        );
        return;
      }

      final agora = DateTime.now();
      final idsOrcamentoPorItem =
          await _repository.transformarSimulacaoEmOrcamento(
        simulacao: simulacao,
        itensPendentes: itensPendentes,
      );

      if (calculoAtual.value?.idCalculo == simulacao.idCalculo) {
        calculoAtual.value = calculoAtual.value!.copyWith(
          statusSimulacao: StatusSimulacaoCalculadora.convertidaOrcamento,
          convertidoEmOrcamento: true,
          dataConversaoOrcamento: agora,
          dataAtualizacao: agora,
        );

        final idsConvertidos =
            itensPendentes.map((e) => e.idItemResultado).toSet();
        itensCalculados.assignAll(
          itensCalculados.map((item) {
            if (!idsConvertidos.contains(item.idItemResultado)) return item;

            return item.copyWith(
              adicionadoAoOrcamento: true,
              idOrcamentoGerado: idsOrcamentoPorItem[item.idItemResultado],
              dataAdicionadoAoOrcamento: agora,
            );
          }).toList(),
        );
      }

      await carregarSimulacoesSalvas();
      await carregarContextoOrcamento();

      Get.snackbar(
        'Orçamento atualizado',
        '${itensPendentes.length} item(ns) foram vinculados ao orçamento. Gastos existentes foram preservados.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível transformar a simulação em orçamento: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      convertendoOrcamento.value = false;
    }
  }

  Future<void> enviarResultadoParaCardapio(
      {required String idCardapio,
      List<CalculadoraFestaItem>? itensRevisados}) async {
    final calculo = calculoAtual.value;
    final versao = _versaoAnaliseIA.value;
    final historico = itensCalculados.toList();

    if (!possuiEventoVinculado) {
      Get.snackbar(
        'Evento não salvo',
        'Salve o evento primeiro para enviar a estimativa ao cardápio.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (calculo == null || itensCalculados.isEmpty) {
      Get.snackbar(
        'Atenção',
        'Nenhum cálculo disponível para enviar ao cardápio.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (idCardapio.trim().isEmpty) {
      Get.snackbar(
        'Atenção',
        'Selecione um cardápio para receber os itens.',
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      enviandoParaCardapio.value = true;
      await _repository.enviarResultadoParaCardapio(
        calculo: calculo,
        itens: itensRevisados ?? itensCalculados.toList(),
        idCardapio: idCardapio,
        itensSimulacao: historico,
      );
      medicaoUso.registrarResultado('aplicar_cardapio', sucesso: true);

      if (versao == _versaoAnaliseIA.value &&
          calculoAtual.value?.idCalculo == calculo.idCalculo) {
        itensCalculados.assignAll(
          itensCalculados
              .map((i) => (itensRevisados ?? itensCalculados).any(
                      (enviado) => enviado.idItemResultado == i.idItemResultado)
                  ? i.copyWith(adicionadoAoCardapio: true)
                  : i)
              .toList(),
        );
      }
      await carregarSimulacoesSalvas();

      Get.snackbar(
        'Cardápio atualizado',
        'As sugestões foram adicionadas ao cardápio.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível enviar as sugestões para o cardápio: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      medicaoUso.registrarResultado('aplicar_cardapio', sucesso: false);
    } finally {
      enviandoParaCardapio.value = false;
    }
  }
}
