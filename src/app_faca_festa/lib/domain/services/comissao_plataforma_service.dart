import 'package:app_faca_festa/domain/entities/financeiro/comissao_plataforma.dart';
import 'package:app_faca_festa/domain/entities/financeiro/valor_monetario.dart';

class ResultadoSimulacaoComissao {
  const ResultadoSimulacaoComissao({
    required this.valorCentavos,
    required this.baseLiquidaCentavos,
    required this.percentualBps,
    required this.podeGerar,
    this.motivoBloqueio,
  });

  final int valorCentavos;
  final int baseLiquidaCentavos;
  final int percentualBps;
  final bool podeGerar;
  final String? motivoBloqueio;
}

class ResultadoAjusteComissao {
  const ResultadoAjusteComissao({
    required this.ajusteCentavos,
    required this.tipo,
    this.creditoReembolsoExplicito = false,
  });

  /// Negativo = redução da obrigação / crédito.
  final int ajusteCentavos;
  final String tipo;
  final bool creditoReembolsoExplicito;
}

/// Comissão da plataforma sobre contratações elegíveis.
/// Volume contratado ≠ receita da plataforma até geração da obrigação.
class ComissaoPlataformaService {
  /// Valida percentual em basis points (0–10000). Null = ausente.
  static void validarPercentualBps(int? bps) {
    if (bps == null) {
      throw ArgumentError('Percentual ausente (diferente de zero válido).');
    }
    if (bps < 0 || bps > 10000) {
      throw ArgumentError('Percentual deve estar entre 0% e 100%.');
    }
  }

  /// Base líquida = bruta − descontos − exclusões (centavos).
  static int baseLiquidaElegivel({
    required int baseBrutaCentavos,
    int descontosCentavos = 0,
    int exclusoesCentavos = 0,
  }) {
    if (baseBrutaCentavos < 0 ||
        descontosCentavos < 0 ||
        exclusoesCentavos < 0) {
      throw ArgumentError('Valores da base não podem ser negativos.');
    }
    final liquida = baseBrutaCentavos - descontosCentavos - exclusoesCentavos;
    if (liquida < 0) {
      throw ArgumentError('Descontos/exclusões excedem a base bruta.');
    }
    return liquida;
  }

  /// Arredondamento explícito para o centavo mais próximo.
  static int calcularComissaoCentavos({
    required int baseLiquidaCentavos,
    required int percentualBps,
  }) {
    validarPercentualBps(percentualBps);
    if (baseLiquidaCentavos < 0 ||
        baseLiquidaCentavos > ValorMonetario.limiteCentavos) {
      throw ArgumentError('Base fora dos limites.');
    }
    return ((baseLiquidaCentavos * percentualBps) / 10000).round();
  }

  static bool politicaPodeGerarDivida(PoliticaComissaoPlataforma? politica) {
    if (politica == null) return false;
    if (!politica.ativa) return false;
    if (!politica.completa) return false;
    return true;
  }

  /// Simulação: não altera financeiro.
  static ResultadoSimulacaoComissao simular({
    required PoliticaComissaoPlataforma? politica,
    required int baseBrutaCentavos,
    int descontosCentavos = 0,
    int exclusoesCentavos = 0,
  }) {
    if (politica == null) {
      return const ResultadoSimulacaoComissao(
        valorCentavos: 0,
        baseLiquidaCentavos: 0,
        percentualBps: 0,
        podeGerar: false,
        motivoBloqueio: 'Política ausente — não gera dívida.',
      );
    }
    if (!politica.ativa) {
      return ResultadoSimulacaoComissao(
        valorCentavos: 0,
        baseLiquidaCentavos: 0,
        percentualBps: politica.percentualBps,
        podeGerar: false,
        motivoBloqueio: 'Política inativa — não gera dívida.',
      );
    }
    if (!politica.completa) {
      return ResultadoSimulacaoComissao(
        valorCentavos: 0,
        baseLiquidaCentavos: 0,
        percentualBps: politica.percentualBps,
        podeGerar: false,
        motivoBloqueio: 'Política incompleta — não gera dívida.',
      );
    }
    if (politica.baseElegivel == BaseElegivelComissao.limiteGlobalCliente) {
      return ResultadoSimulacaoComissao(
        valorCentavos: 0,
        baseLiquidaCentavos: 0,
        percentualBps: politica.percentualBps,
        podeGerar: false,
        motivoBloqueio:
            'Base limite global do cliente exige autorização comercial explícita.',
      );
    }
    final liquida = baseLiquidaElegivel(
      baseBrutaCentavos: baseBrutaCentavos,
      descontosCentavos: descontosCentavos,
      exclusoesCentavos: exclusoesCentavos,
    );
    final valor = calcularComissaoCentavos(
      baseLiquidaCentavos: liquida,
      percentualBps: politica.percentualBps,
    );
    return ResultadoSimulacaoComissao(
      valorCentavos: valor,
      baseLiquidaCentavos: liquida,
      percentualBps: politica.percentualBps,
      podeGerar: true,
    );
  }

  /// Gera obrigação uma única vez; [jaExistente] preserva valor anterior.
  static ObrigacaoComissaoPlataforma gerarObrigacao({
    required PoliticaComissaoPlataforma politica,
    required String idObrigacao,
    required String idEvento,
    required String idContrato,
    required int baseBrutaCentavos,
    int descontosCentavos = 0,
    int exclusoesCentavos = 0,
    String? idPagador,
    String? idFornecedor,
    ObrigacaoComissaoPlataforma? jaExistente,
  }) {
    if (jaExistente != null) {
      return jaExistente; // idempotente — não recalcula
    }
    if (!politicaPodeGerarDivida(politica)) {
      throw StateError('Política ausente/inativa/incompleta não gera dívida.');
    }
    final sim = simular(
      politica: politica,
      baseBrutaCentavos: baseBrutaCentavos,
      descontosCentavos: descontosCentavos,
      exclusoesCentavos: exclusoesCentavos,
    );
    if (!sim.podeGerar) {
      throw StateError(sim.motivoBloqueio ?? 'Não é possível gerar obrigação.');
    }
    return ObrigacaoComissaoPlataforma(
      id: idObrigacao,
      idEvento: idEvento,
      idContrato: idContrato,
      baseElegivelCentavos: sim.baseLiquidaCentavos,
      valorOriginalCentavos: sim.valorCentavos,
      valorAjustesCentavos: 0,
      valorLiquidadoCentavos: 0,
      status: StatusObrigacaoComissao.gerada,
      politicaAplicada: politica.snapshotImutavel(),
      idPagador: idPagador,
      idFornecedor: idFornecedor,
    );
  }

  /// Liquidação manual — não afirma confirmação bancária.
  static ObrigacaoComissaoPlataforma liquidarManual({
    required ObrigacaoComissaoPlataforma obrigacao,
    required int valorCentavos,
  }) {
    if (valorCentavos <= 0) {
      throw ArgumentError('Informe valor de liquidação positivo.');
    }
    if (obrigacao.status == StatusObrigacaoComissao.estornada) {
      throw StateError('Obrigação estornada não aceita liquidação.');
    }
    final liquidado = obrigacao.valorLiquidadoCentavos + valorCentavos;
    final saldo = obrigacao.valorOriginalCentavos +
        obrigacao.valorAjustesCentavos -
        liquidado;
    final status = saldo <= 0
        ? StatusObrigacaoComissao.recebida
        : StatusObrigacaoComissao.aVencer;
    return ObrigacaoComissaoPlataforma(
      id: obrigacao.id,
      idEvento: obrigacao.idEvento,
      idContrato: obrigacao.idContrato,
      baseElegivelCentavos: obrigacao.baseElegivelCentavos,
      valorOriginalCentavos: obrigacao.valorOriginalCentavos,
      valorAjustesCentavos: obrigacao.valorAjustesCentavos,
      valorLiquidadoCentavos: liquidado,
      status: status,
      politicaAplicada: obrigacao.politicaAplicada,
      idPagador: obrigacao.idPagador,
      idFornecedor: obrigacao.idFornecedor,
    );
  }

  /// Redução elegível com reversão proporcional → ajuste + crédito explícito.
  static ResultadoAjusteComissao ajustePorReducaoElegivel({
    required int percentualBpsAplicado,
    required int reducaoBaseCentavos,
    required ReversaoComissao reversao,
  }) {
    if (reducaoBaseCentavos <= 0) {
      throw ArgumentError('Informe a redução elegível.');
    }
    if (reversao == ReversaoComissao.nenhuma) {
      return const ResultadoAjusteComissao(
        ajusteCentavos: 0,
        tipo: 'sem_reversao',
      );
    }
    if (reversao == ReversaoComissao.manual) {
      return const ResultadoAjusteComissao(
        ajusteCentavos: 0,
        tipo: 'reversao_manual_pendente',
      );
    }
    final credito = calcularComissaoCentavos(
      baseLiquidaCentavos: reducaoBaseCentavos,
      percentualBps: percentualBpsAplicado,
    );
    return ResultadoAjusteComissao(
      ajusteCentavos: -credito,
      tipo: 'reversao_proporcional',
      creditoReembolsoExplicito: credito > 0,
    );
  }

  static ObrigacaoComissaoPlataforma aplicarAjuste({
    required ObrigacaoComissaoPlataforma obrigacao,
    required int ajusteCentavos,
  }) {
    return ObrigacaoComissaoPlataforma(
      id: obrigacao.id,
      idEvento: obrigacao.idEvento,
      idContrato: obrigacao.idContrato,
      baseElegivelCentavos: obrigacao.baseElegivelCentavos,
      valorOriginalCentavos: obrigacao.valorOriginalCentavos,
      valorAjustesCentavos: obrigacao.valorAjustesCentavos + ajusteCentavos,
      valorLiquidadoCentavos: obrigacao.valorLiquidadoCentavos,
      status: obrigacao.status,
      politicaAplicada: obrigacao.politicaAplicada,
      idPagador: obrigacao.idPagador,
      idFornecedor: obrigacao.idFornecedor,
    );
  }
}
