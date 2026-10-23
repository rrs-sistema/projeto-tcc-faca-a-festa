import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';

/// Domínio puro — espelho do serviço TypeScript (Prompt 03).
class MediacaoOperacionalService {
  const MediacaoOperacionalService();

  List<CapacidadeMediacao> capacidadesParaTipo(String tipo) {
    if (tipo == 'A') {
      return CapacidadeMediacao.values.toList();
    }
    return [CapacidadeMediacao.consultaComercial];
  }

  bool temCapacidade(List<CapacidadeMediacao> caps, CapacidadeMediacao req) =>
      caps.contains(req);

  List<RegistroMediacaoView> filtrarRegistrosPorPapel({
    required List<RegistroMediacaoView> registros,
    required String papel,
    required List<CapacidadeMediacao> caps,
  }) {
    if (papel == 'admin' &&
        temCapacidade(caps, CapacidadeMediacao.notasInternas)) {
      return List.of(registros);
    }
    return registros
        .where((r) =>
            r.visibilidade == VisibilidadeRegistroMediacao.compartilhavel)
        .toList();
  }

  List<RegistroMediacaoView> registrosParaExportacao(
    List<RegistroMediacaoView> registros,
  ) {
    return registros
        .where((r) =>
            r.visibilidade == VisibilidadeRegistroMediacao.compartilhavel)
        .toList();
  }

  DimensoesFinanceirasContrato calcularDimensoes({
    required int valorContratadoCentavos,
    required int recebidoAlocadoCentavos,
    required int repassadoConfirmadoCentavos,
    int remuneracaoAppPrevistaCentavos = 0,
  }) {
    final valor =
        valorContratadoCentavos < 0 ? 0 : valorContratadoCentavos;
    final recebido =
        recebidoAlocadoCentavos < 0 ? 0 : recebidoAlocadoCentavos;
    final repassado =
        repassadoConfirmadoCentavos < 0 ? 0 : repassadoConfirmadoCentavos;
    final aReceber = (valor - recebido) < 0 ? 0 : valor - recebido;
    final pendente =
        (recebido - repassado) < 0 ? 0 : recebido - repassado;
    return DimensoesFinanceirasContrato(
      valorContratadoCentavos: valor,
      recebidoClienteAlocadoCentavos: recebido,
      aReceberClienteCentavos: aReceber,
      repassadoConfirmadoCentavos: repassado,
      pendenteRepasseCentavos: pendente,
      remuneracaoAppPrevistaCentavos:
          remuneracaoAppPrevistaCentavos < 0 ? 0 : remuneracaoAppPrevistaCentavos,
    );
  }

  /// Fechar caso nunca produz efeitos financeiros.
  List<String> efeitosFinanceirosAoFechar() => const [];

  /// Bloqueio/recomendação só no contrato alvo.
  ({List<String> afetados, List<String> naoAfetados}) escopoBloqueio({
    required String idContratoAlvo,
    required List<String> idsContratosDoEvento,
  }) {
    final afetados =
        idsContratosDoEvento.where((id) => id == idContratoAlvo).toList();
    final naoAfetados =
        idsContratosDoEvento.where((id) => id != idContratoAlvo).toList();
    return (afetados: afetados, naoAfetados: naoAfetados);
  }

  /// Sem política de retenção: só recomendação.
  ({bool retencaoAplicada, bool somenteRecomendacao}) aplicarRecomendacao({
    required String motivo,
    required bool politicaRetencaoAtiva,
  }) {
    if (motivo.trim().isEmpty) {
      throw ArgumentError('Informe o motivo da revisão.');
    }
    final retencao = politicaRetencaoAtiva;
    return (
      retencaoAplicada: retencao,
      somenteRecomendacao: !retencao,
    );
  }

  bool casoVisivelParaVinculo({
    required String? idContratanteCaso,
    required String? idFornecedorCaso,
    required String papel,
    required String uid,
    String? idFornecedorOperador,
  }) {
    if (papel == 'admin') return true;
    if (papel == 'cliente') return idContratanteCaso == uid;
    if (papel == 'fornecedor') {
      return idFornecedorOperador != null &&
          idFornecedorOperador.isNotEmpty &&
          idFornecedorCaso == idFornecedorOperador;
    }
    return false;
  }
}
