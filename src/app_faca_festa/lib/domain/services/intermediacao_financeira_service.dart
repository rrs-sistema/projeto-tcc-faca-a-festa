import 'package:app_faca_festa/domain/entities/financeiro/intermediacao_financeira.dart';

/// Espelho determinístico do serviço TS — testes e simulação UI.
class IntermediacaoFinanceiraService {
  const IntermediacaoFinanceiraService();

  DireitosContratoIntermediado calcularDireitos({
    required int valorContratadoCentavos,
    required int percentualBps,
    ModoComissaoIntermediacao modo =
        ModoComissaoIntermediacao.descontadaFornecedor,
  }) {
    final comissao =
        ((valorContratadoCentavos * percentualBps) / 10000).round();
    if (modo == ModoComissaoIntermediacao.descontadaFornecedor) {
      return DireitosContratoIntermediado(
        comissaoPrevistaCentavos: comissao,
        direitoFornecedorPrevistoCentavos:
            valorContratadoCentavos - comissao,
        precoClienteCentavos: valorContratadoCentavos,
      );
    }
    return DireitosContratoIntermediado(
      comissaoPrevistaCentavos: comissao,
      direitoFornecedorPrevistoCentavos: valorContratadoCentavos,
      precoClienteCentavos: valorContratadoCentavos + comissao,
    );
  }

  /// Retorna null se inválido (excede disponível).
  int? tentarAlocar({
    required int valorRecebimentoCentavos,
    required int jaAlocadoCentavos,
    required int pedidoCentavos,
  }) {
    if (pedidoCentavos <= 0) return null;
    if (jaAlocadoCentavos + pedidoCentavos > valorRecebimentoCentavos) {
      return null;
    }
    return jaAlocadoCentavos + pedidoCentavos;
  }

  ({bool aceitoA, bool aceitoB, int restante}) concorrenciaAlocacao({
    required int disponivelCentavos,
    required int pedidoACentavos,
    required int pedidoBCentavos,
  }) {
    var restante = disponivelCentavos;
    var aceitoA = false;
    var aceitoB = false;
    if (pedidoACentavos <= restante) {
      restante -= pedidoACentavos;
      aceitoA = true;
    }
    if (pedidoBCentavos <= restante) {
      restante -= pedidoBCentavos;
      aceitoB = true;
    }
    return (aceitoA: aceitoA, aceitoB: aceitoB, restante: restante);
  }

  ({EstadoRepasse estado, int elegivelCentavos, String? motivo})
      avaliarElegibilidade({
    required int direitoFornecedorCentavos,
    required int alocadoCentavos,
    required int jaRepassadoCentavos,
    required int jaAuthCentavos,
    required bool politicaAtiva,
    bool permiteParcial = false,
    int? tetoParcialCentavos,
  }) {
    final teto = (direitoFornecedorCentavos - jaRepassadoCentavos - jaAuthCentavos)
        .clamp(0, direitoFornecedorCentavos);
    final financiado =
        (alocadoCentavos - jaRepassadoCentavos - jaAuthCentavos).clamp(0, alocadoCentavos);
    final bruto = teto < financiado ? teto : financiado;

    if (!politicaAtiva) {
      return (
        estado: EstadoRepasse.elegivelPendente,
        elegivelCentavos: 0,
        motivo:
            'Política de liberação ausente ou inativa — sem repasse automático.',
      );
    }
    var elegivel = bruto;
    if (permiteParcial && tetoParcialCentavos != null) {
      elegivel = elegivel < tetoParcialCentavos ? elegivel : tetoParcialCentavos;
    } else if (!permiteParcial && financiado < teto) {
      return (
        estado: EstadoRepasse.elegivelPendente,
        elegivelCentavos: 0,
        motivo: 'Política exige financiamento integral.',
      );
    }
    if (elegivel <= 0) {
      return (
        estado: EstadoRepasse.previsto,
        elegivelCentavos: 0,
        motivo: 'Sem valor elegível.',
      );
    }
    return (
      estado: EstadoRepasse.autorizado,
      elegivelCentavos: elegivel,
      motivo: null,
    );
  }

  EstadoRepasse confirmarManual(EstadoRepasse atual) {
    if (atual != EstadoRepasse.autorizado &&
        atual != EstadoRepasse.emProcessamento) {
      throw StateError('Confirmação exige autorização prévia.');
    }
    return EstadoRepasse.confirmado;
  }

  ({
    int semAlocacao,
    int residual,
    bool ok,
  }) conciliarCaixa({
    required int recebidoCentavos,
    required int alocadoCentavos,
    required int repassadoCentavos,
  }) {
    final ok = alocadoCentavos <= recebidoCentavos &&
        repassadoCentavos <= alocadoCentavos;
    return (
      semAlocacao: (recebidoCentavos - alocadoCentavos).clamp(0, recebidoCentavos),
      residual: (alocadoCentavos - repassadoCentavos).clamp(0, alocadoCentavos),
      ok: ok,
    );
  }

  ({
    int creditoCliente,
    int recuperacaoPendente,
    int repassePreservado,
  }) chargebackPosRepasse({
    required int valorChargebackCentavos,
    required int repassadoConfirmadoCentavos,
  }) {
    return (
      creditoCliente: valorChargebackCentavos,
      recuperacaoPendente: valorChargebackCentavos < repassadoConfirmadoCentavos
          ? valorChargebackCentavos
          : repassadoConfirmadoCentavos,
      repassePreservado: repassadoConfirmadoCentavos,
    );
  }
}
