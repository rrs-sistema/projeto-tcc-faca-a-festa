part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaHistorico on CalculadoraFestaController {
  Future<void> salvarCalculo() async {
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

    if (calculo == null) {
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

      final calculoParaSalvar = calculo.copyWith(
        orcamentoDisponivel: orcamentoDisponivel.value,
        limparOrcamentoDisponivel: orcamentoDisponivel.value == null,
        analiseIA: analiseIA.value,
        limparAnaliseIA: analiseIA.value == null,
        dataAtualizacao: DateTime.now(),
      );

      await _repository.salvarSimulacao(
        calculo: calculoParaSalvar,
        itens: itensCalculados,
      );

      calculoAtual.value = calculoParaSalvar;
      await carregarSimulacoesSalvas();

      Get.snackbar(
        'Simulação salva',
        'O cálculo e a análise inteligente foram salvos com sucesso.',
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } catch (e) {
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
    if (!possuiEventoVinculado) {
      simulacoesSalvas.clear();
      return;
    }

    try {
      carregandoSimulacoes.value = true;
      final simulacoes =
          await _repository.listarSimulacoesPorEvento(idEventoAtual.value);
      simulacoesSalvas.assignAll(simulacoes);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar as simulações: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      carregandoSimulacoes.value = false;
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
    try {
      loading.value = true;

      final itens = await _repository.listarItensDaSimulacao(
        simulacao.idCalculo,
      );

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
      analiseIA.value = simulacao.analiseIA;
      itensCalculados.assignAll(itens);

      // Mantém a estimativa em memória coerente para novas análises de IA.
      estimativaAtual.value = _service.calcularEstimativa(
        calculo: simulacao,
        itensBase: itensEstimativa,
      );
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

      Get.snackbar(
        'Orçamento criado',
        '${itensPendentes.length} item(ns) foram adicionados ao orçamento do evento.',
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

  Future<void> enviarResultadoParaCardapio({required String idCardapio}) async {
    final calculo = calculoAtual.value;

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
        itens: itensCalculados.toList(),
        idCardapio: idCardapio,
      );

      itensCalculados.assignAll(
        itensCalculados
            .map((i) => i.copyWith(adicionadoAoCardapio: true))
            .toList(),
      );

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
    } finally {
      enviandoParaCardapio.value = false;
    }
  }
}
