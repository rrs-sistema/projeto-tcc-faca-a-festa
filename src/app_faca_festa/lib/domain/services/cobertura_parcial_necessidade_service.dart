/// Projeta apenas a quantidade ainda não contratada.
/// Preço ausente não vira zero: marca projeção parcial.
class ProjecaoNecessidadeParcial {
  const ProjecaoNecessidadeParcial({
    required this.quantidadeRestante,
    required this.custoProjetado,
    required this.precoAusente,
    required this.coberturaIntegral,
  });

  final double quantidadeRestante;
  final double? custoProjetado;
  final bool precoAusente;
  final bool coberturaIntegral;
}

class CoberturaParcialNecessidadeService {
  const CoberturaParcialNecessidadeService();

  /// Ex.: necessidade 100, contratadas 60 → projeta só 40 restantes.
  ProjecaoNecessidadeParcial projetar({
    required num necessidade,
    required num quantidadeContratada,
    num? precoUnitario,
  }) {
    if (!necessidade.isFinite || necessidade < 0) {
      return const ProjecaoNecessidadeParcial(
        quantidadeRestante: 0,
        custoProjetado: null,
        precoAusente: true,
        coberturaIntegral: false,
      );
    }
    final contratado = quantidadeContratada.isFinite && quantidadeContratada > 0
        ? quantidadeContratada.toDouble()
        : 0.0;
    final restante =
        (necessidade.toDouble() - contratado).clamp(0.0, double.infinity);
    if (restante <= 0) {
      return const ProjecaoNecessidadeParcial(
        quantidadeRestante: 0,
        custoProjetado: 0,
        precoAusente: false,
        coberturaIntegral: true,
      );
    }
    if (precoUnitario == null ||
        !precoUnitario.isFinite ||
        precoUnitario <= 0) {
      return ProjecaoNecessidadeParcial(
        quantidadeRestante: restante,
        custoProjetado: null,
        precoAusente: true,
        coberturaIntegral: false,
      );
    }
    return ProjecaoNecessidadeParcial(
      quantidadeRestante: restante,
      custoProjetado: restante * precoUnitario.toDouble(),
      precoAusente: false,
      coberturaIntegral: false,
    );
  }
}
