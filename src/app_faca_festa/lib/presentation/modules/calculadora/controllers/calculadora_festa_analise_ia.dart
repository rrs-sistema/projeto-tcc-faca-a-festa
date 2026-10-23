part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaAnaliseIa on CalculadoraFestaController {
  bool get _historicoMotorAntigo =>
      usandoContextoHistorico.value &&
      ((calculoAtual.value?.contextoPlanejamento['versao_motor'] as num?)
                  ?.toInt() ??
              0) !=
          6;

  static const _avisoHistoricoAntigo =
      'Esta simulação usa uma versão anterior do cálculo. Atualize com os dados atuais do evento antes de solicitar a análise.';

  void _agendarAnaliseIA() {
    _versaoAnaliseIA.value++;
    analiseIA.value = null;
    erroAnaliseIA.value = '';
    analisandoIA.value = false;
  }

  Future<void> tentarAnaliseIA() async => _executarAnaliseIA();

  Future<void> _executarAnaliseIA() async {
    if (_historicoMotorAntigo) {
      analiseIA.value = null;
      erroAnaliseIA.value = _avisoHistoricoAntigo;
      return;
    }
    if (loading.value ||
        (usandoContextoHistorico.value && analiseIA.value != null)) {
      return;
    }
    final contexto = contextoEvento.assinatura;
    final estimativa = estimativaAtual.value;
    final calculoReferencia = calculoAtual.value;
    final versaoSolicitada = _versaoAnaliseIA.value;
    final requisicao = ++_ultimaRequisicaoIA;

    if (estimativa == null ||
        calculoReferencia == null ||
        itensCalculados.isEmpty) {
      analiseIA.value = null;
      return;
    }

    try {
      analisandoIA.value = true;
      erroAnaliseIA.value = '';
      analiseIA.value = null;

      final analise = await _aiService.analisarEstimativa(
        contextoPlanejamento: contextoPlanejamento,
        estimativa: estimativa,
        itensCalculados: itensCalculados.toList(),
        tipoEvento: tipoEventoAtual.value,
        orcamentoDisponivel: orcamentoDisponivel.value,
        idCalculo: calculoReferencia.idCalculo,
        idEvento: calculoReferencia.idEvento,
        idUsuario: calculoReferencia.idUsuario ?? _uidAtual,
      );

      if (contexto != contextoEvento.assinatura ||
          versaoSolicitada != _versaoAnaliseIA.value ||
          requisicao != _ultimaRequisicaoIA) {
        return;
      }

      final calculoAtualizado = calculoAtual.value;

      if (calculoAtualizado == null ||
          calculoAtualizado.idCalculo != calculoReferencia.idCalculo) {
        return;
      }

      analiseIA.value = analise;

      calculoAtual.value = calculoAtualizado.copyWith(
        analiseIA: analise,
        orcamentoDisponivel: orcamentoDisponivel.value,
        limparOrcamentoDisponivel: orcamentoDisponivel.value == null,
        dataAtualizacao: DateTime.now(),
      );
    } catch (e) {
      if (versaoSolicitada == _versaoAnaliseIA.value &&
          requisicao == _ultimaRequisicaoIA) {
        erroAnaliseIA.value =
            'A análise está indisponível. As quantidades calculadas continuam disponíveis.';
      }
      debugPrint('Erro ao executar análise inteligente da calculadora: $e');
    } finally {
      if (versaoSolicitada == _versaoAnaliseIA.value &&
          requisicao == _ultimaRequisicaoIA) {
        analisandoIA.value = false;
      }
    }
  }
}
