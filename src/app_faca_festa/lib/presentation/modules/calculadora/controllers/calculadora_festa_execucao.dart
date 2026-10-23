part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaExecucao on CalculadoraFestaController {
  Future<ContextoExecucaoPlano> carregarExecucao() async {
    if (estimativaSemEvento.value ||
        usandoContextoHistorico.value ||
        idEventoAtual.value.isEmpty) {
      throw StateError('Abra os dados atuais de um evento salvo.');
    }
    final repo = _repository;
    if (repo is! ExecucaoCalculadoraRepository) {
      throw StateError('O executor não está disponível neste ambiente.');
    }
    final sessao = sessaoPlanejador;
    final contexto = await (repo as ExecucaoCalculadoraRepository)
        .carregarContextoExecucao(idEventoAtual.value);
    if (sessao != sessaoPlanejador || usandoContextoHistorico.value) {
      throw StateError('O contexto mudou. Reabra o evento.');
    }
    restaurarRegrasExecucao(contexto.operacao);
    return contexto;
  }

  PropostaExecucaoPlano proporExecucao(
      ContextoExecucaoPlano contexto, String pedido,
      {bool declararSemCompras = false, bool criarTarefas = true}) {
    final agora = DateTime.now();
    return const PlanoExecucaoService().gerar(
        catalogo: catalogoParaPropostas,
        pedido: pedido,
        contexto: contexto,
        calculo: CalculadoraFesta(
            idCalculo: 'execucao',
            idEvento: idEventoAtual.value,
            tipoEvento: tipoEventoAtual.value,
            baseCalculo: baseCalculo.value,
            totalAdultos: totalAdultos.value,
            totalCriancas: totalCriancas.value,
            totalBebes: totalBebes.value,
            duracaoHoras: duracaoHoras.value,
            dataCalculo: agora,
            dataAtualizacao: agora,
            perfilFesta: perfilSelecionado.value,
            margemPersonalizada: margemPersonalizada.value,
            orcamentoDisponivel: orcamentoDisponivel.value),
        regras: regrasDisponiveis,
        declararSemCompras: declararSemCompras,
        criarTarefas: criarTarefas);
  }

  void restaurarRegrasExecucao(Map<String, dynamic> dados,
      {bool substituir = false}) {
    if (_eventoRegrasExecucao != idEventoAtual.value) {
      _regrasExecucaoRecebidas.clear();
      _eventoRegrasExecucao = idEventoAtual.value;
    }
    final exec = OperacaoCalculadoraService.mapa(dados['execucao']);
    for (final raw in OperacaoCalculadoraService.lista(exec['regras'])) {
      final r = ItemEstimativaFinanceira.fromPlanejamento(raw);
      if (r.premissas['id_evento'] != idEventoAtual.value) continue;
      final locais = regrasManuais.where((a) => a.id == r.id).toList();
      if (substituir ||
          (locais.length == 1 &&
              _regrasExecucaoRecebidas[r.id] ==
                  assinaturaExecucao(locais.single.toPlanejamento()))) {
        regrasManuais.removeWhere((a) => a.id == r.id);
      }
      if (!regrasManuais.any((a) => a.id == r.id)) regrasManuais.add(r);
      _regrasExecucaoRecebidas[r.id] = assinaturaExecucao(r.toPlanejamento());
    }
  }

  Future<bool> aplicarExecucao(
      PropostaExecucaoPlano proposta, String assinaturaLocal) async {
    if (assinaturaLocal != assinaturaProposta ||
        usandoContextoHistorico.value ||
        proposta.contexto.evento != idEventoAtual.value) {
      throw StateError('O planejamento mudou. Atualize a proposta.');
    }
    final repo = _repository;
    if (repo is! ExecucaoCalculadoraRepository) {
      throw StateError('O executor não está disponível.');
    }
    String parametros() => assinaturaExecucao([
          idEventoAtual.value,
          baseCalculo.value.name,
          totalAdultos.value,
          totalCriancas.value,
          totalBebes.value,
          perfilSelecionado.value.tipo.name,
          duracaoHoras.value,
          margemPersonalizada.value
        ]);
    final parametrosAntes = parametros();
    final sessao = sessaoPlanejador;
    medicaoUso.registrarDecisao('aplicar_execucao');
    try {
      final criado = await (repo as ExecucaoCalculadoraRepository)
          .aplicarPlanoExecucao(proposta);
      medicaoUso.registrarResultado('aplicar_execucao', sucesso: true);
      if (proposta.contexto.evento == idEventoAtual.value &&
          sessao == sessaoPlanejador &&
          assinaturaLocal == assinaturaProposta &&
          !usandoContextoHistorico.value &&
          criado &&
          parametrosAntes == parametros() &&
          (operacaoEvento['revisao'] as num? ?? 0) <=
              (proposta.operacao['revisao'] as num)) {
        for (final r in proposta.regras) {
          regrasManuais.removeWhere((a) => a.id == r.id);
          regrasManuais.add(r);
        }
        // O stream confirma o documento e a revisão; não substitui uma revisão mais nova.
        if ((operacaoEvento['revisao'] as num? ?? 0) <
            (proposta.operacao['revisao'] as num)) {
          operacaoEvento.assignAll(proposta.operacao);
        }
        totalAdultos.value = (proposta.publico['adultos'] as num).toInt();
        totalCriancas.value = (proposta.publico['criancas'] as num).toInt();
        totalBebes.value = (proposta.publico['bebes'] as num).toInt();
        calcular();
      }
      return criado;
    } catch (_) {
      medicaoUso.registrarResultado('aplicar_execucao', sucesso: false);
      rethrow;
    }
  }
}
