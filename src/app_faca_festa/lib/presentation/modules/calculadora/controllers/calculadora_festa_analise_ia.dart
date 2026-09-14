part of 'calculadora_festa_controller.dart';

extension CalculadoraFestaAnaliseIa on CalculadoraFestaController {
  void _agendarAnaliseIA() {
    _versaoAnaliseIA.value++;
  }

  Future<void> _executarAnaliseIA({bool force = false}) async {
    final estimativa = estimativaAtual.value;
    final calculoReferencia = calculoAtual.value;
    final versaoSolicitada = _versaoAnaliseIA.value;

    if (estimativa == null ||
        calculoReferencia == null ||
        itensCalculados.isEmpty) {
      analiseIA.value = null;
      return;
    }

    try {
      analisandoIA.value = true;

      final analise = await _aiService.analisarEstimativa(
        estimativa: estimativa,
        itensCalculados: itensCalculados.toList(),
        tipoEvento: tipoEventoAtual.value,
        orcamentoDisponivel: orcamentoDisponivel.value,
      );

      if (!force && versaoSolicitada != _versaoAnaliseIA.value) {
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
      debugPrint('Erro ao executar análise inteligente da calculadora: $e');
    } finally {
      analisandoIA.value = false;
    }
  }
}
