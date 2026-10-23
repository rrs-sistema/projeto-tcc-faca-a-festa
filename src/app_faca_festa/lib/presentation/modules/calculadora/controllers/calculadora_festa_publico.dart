part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaPublico on CalculadoraFestaController {
  void retomarPoliticaPublicoAtual() {
    _baseLocalAlterada = false;
    _camposConfiguracaoEditados.clear();
    _configuracaoConfirmada = {};
    _politicaPublicoRecebida = "";
    duracaoHoras.value = 4;
    perfilSelecionado.value = PerfilFesta.padrao();
    margemPersonalizada.value = null;
    verbaAlimentacao.value = null;
    baseCalculo.value = BaseCalculoFesta.previstos;
    basePublicoConfirmada.value = false;
  }

  PrevisaoPublico get previsaoPublico {
    final soma = totalAdultosEvento.value +
        totalCriancasEvento.value +
        totalBebesEvento.value;
    final total = _previsaoTotal.value ?? (soma > 0 ? soma : null);
    return PrevisaoPublico(
        total,
        total != null && _previsaoIdadesConhecidas
            ? ConvidadosEquivalentes(
                adultos: totalAdultosEvento.value,
                criancas: totalCriancasEvento.value,
                bebes: totalBebesEvento.value)
            : null);
  }

  PublicoPlanejado get publicoPlanejado {
    if (usandoContextoHistorico.value && calculoAtual.value != null) {
      final c = calculoAtual.value!;
      final politica = OperacaoCalculadoraService.mapa(
          c.contextoPlanejamento['politica_publico']);
      return PublicoPlanejado(
          base: c.baseCalculo,
          previsao: PrevisaoPublico(
              (politica['previstos_total'] as num?)?.toInt(), null),
          completude: completudeDaLista(politica['lista_completude']),
          cadastrados: null,
          confirmados: null,
          naoRecusados: null,
          total: c.totalAdultos + c.totalCriancas + c.totalBebes,
          idades: c.convidadosEquivalentes);
    }
    return const PublicoPlanejamentoService().resolver(
        evento: idEventoAtual.value,
        previsao: previsaoPublico,
        convidados: convidados,
        base: baseCalculo.value,
        manual: publicoEvento,
        completude: completudeLista.value,
        listaDisponivel:
            estadoConvidados.value == EstadoFontePlanejamento.disponivel ||
                estadoConvidados.value == EstadoFontePlanejamento.vazia);
  }

  PublicoPlanejado publicoDaBase(BaseCalculoFesta base) =>
      const PublicoPlanejamentoService().resolver(
          evento: idEventoAtual.value,
          previsao: previsaoPublico,
          convidados: convidados,
          base: base,
          manual: publicoEvento,
          completude: completudeLista.value,
          listaDisponivel:
              estadoConvidados.value == EstadoFontePlanejamento.disponivel ||
                  estadoConvidados.value == EstadoFontePlanejamento.vazia);

  Future<void> confirmarBasePublico(BaseCalculoFesta base,
      {required String assinatura}) async {
    if (assinatura != contextoEvento.assinatura ||
        usandoContextoHistorico.value) {
      throw StateError('Os dados mudaram. Revise a fonte novamente.');
    }
    if (publicoDaBase(base).idades == null) {
      throw StateError(base == BaseCalculoFesta.previstos
          ? 'Confira a previsão e informe a distribuição etária.'
          : 'Aguarde a consulta da lista antes de confirmar esta fonte.');
    }
    if (!possuiEventoVinculado) {
      alterarBaseCalculo(base);
      return;
    }
    await confirmarConfiguracao(prepararConfirmacaoConfiguracao({
      'base': valorBasePublico(base),
      'base_confirmada': true,
      if (base == BaseCalculoFesta.manual)
        'publico': {
          'adultos': totalAdultos.value,
          'criancas': totalCriancas.value,
          'bebes': totalBebes.value
        },
    }));
  }

  Future<void> declararCompletude(CompletudeLista estado,
      {required String assinatura}) async {
    if (assinatura != contextoEvento.assinatura ||
        usandoContextoHistorico.value) {
      throw StateError('Os dados mudaram. Reabra a declaração da lista.');
    }
    final usuario = _uidAtual;
    final evento = idEventoAtual.value, geracao = _versaoPreparacao;
    await alterarOperacao({
      'tipo': 'publico_planejamento',
      'alteracoes': {'lista_completude': estado.valor}
    });
    if (usuario != _uidAtual ||
        evento != idEventoAtual.value ||
        geracao != _versaoPreparacao ||
        usandoContextoHistorico.value) {
      return;
    }
    sincronizarPoliticaPublico(OperacaoCalculadoraService.mapa(
        operacaoEvento['configuracao_planejamento']));
  }

  void sincronizarPoliticaPublico(Map<String, dynamic> cfg,
      {bool forcar = false}) {
    if (usandoContextoHistorico.value) return;
    completudeLista.value = completudeDaLista(cfg['lista_completude']);
    final base = basePublicoDoValor(cfg['base']);
    if (base == null || cfg['base_confirmada'] == false) return;
    final assinatura = assinaturaExecucao([cfg['base'], cfg['publico']]);
    if (assinatura == _politicaPublicoRecebida && !forcar) return;
    _politicaPublicoRecebida = assinatura;
    final p = OperacaoCalculadoraService.mapa(cfg['publico']);
    if (_baseLocalAlterada && !forcar) {
      final mudou = base != baseCalculo.value ||
          base == BaseCalculoFesta.manual &&
              assinaturaExecucao(p) !=
                  assinaturaExecucao({
                    'adultos': totalAdultos.value,
                    'criancas': totalCriancas.value,
                    'bebes': totalBebes.value
                  });
      if (mudou) {
        avisoPublico.value =
            'A fonte de público mudou em outro acesso. Seu público local foi preservado; revise antes de confirmar.';
      }
      return;
    }
    baseCalculo.value = base;
    basePublicoConfirmada.value = true;
    if (base == BaseCalculoFesta.manual && p.isNotEmpty) {
      totalAdultos.value = OperacaoCalculadoraService.inteiro(p['adultos']);
      totalCriancas.value = OperacaoCalculadoraService.inteiro(p['criancas']);
      totalBebes.value = OperacaoCalculadoraService.inteiro(p['bebes']);
    } else {
      aplicarTotaisDosConvidados();
    }
  }
}
