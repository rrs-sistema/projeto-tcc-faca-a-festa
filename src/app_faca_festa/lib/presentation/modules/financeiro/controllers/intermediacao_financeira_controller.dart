import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/intermediacao_financeira_remote.dart';
import 'package:app_faca_festa/domain/services/intermediacao_financeira_service.dart';

class IntermediacaoFinanceiraController extends GetxController {
  IntermediacaoFinanceiraController({
    required this.remote,
    IntermediacaoFinanceiraService? dominio,
  }) : dominio = dominio ?? const IntermediacaoFinanceiraService();

  final IntermediacaoFinanceiraRemote remote;
  final IntermediacaoFinanceiraService dominio;

  final carregando = false.obs;
  final enviando = false.obs;
  final erro = ''.obs;
  final aviso = ''.obs;
  final extrato = Rxn<Map<String, dynamic>>();
  final simulacao = Rxn<Map<String, dynamic>>();
  final idEvento = ''.obs;

  int _geracao = 0;

  @override
  void onClose() {
    _geracao++;
    super.onClose();
  }

  Future<void> carregarExtrato(String eventoId) async {
    final geracao = ++_geracao;
    idEvento.value = eventoId.trim();
    if (idEvento.value.isEmpty) {
      erro.value = 'Informe a referência do evento.';
      return;
    }
    erro.value = '';
    aviso.value = '';
    carregando.value = true;
    try {
      final res = await remote.consultarExtrato(idEvento.value);
      if (geracao != _geracao) return;
      extrato.value = res;
      aviso.value = (res['aviso'] ?? '').toString();
    } catch (e) {
      if (geracao != _geracao) return;
      // Fallback: simulação local se callable indisponível.
      erro.value = e.toString();
      extrato.value = null;
    } finally {
      if (geracao == _geracao) carregando.value = false;
    }
  }

  void simularCenarioAceite() {
    final direitos = dominio.calcularDireitos(
      valorContratadoCentavos: 1000000,
      percentualBps: 500,
    );
    final elegSemPolitica = dominio.avaliarElegibilidade(
      direitoFornecedorCentavos: direitos.direitoFornecedorPrevistoCentavos,
      alocadoCentavos: 400000,
      jaRepassadoCentavos: 0,
      jaAuthCentavos: 0,
      politicaAtiva: false,
    );
    final elegComPolitica = dominio.avaliarElegibilidade(
      direitoFornecedorCentavos: direitos.direitoFornecedorPrevistoCentavos,
      alocadoCentavos: 400000,
      jaRepassadoCentavos: 0,
      jaAuthCentavos: 0,
      politicaAtiva: true,
      permiteParcial: true,
      tetoParcialCentavos: 300000,
    );
    final conc = dominio.conciliarCaixa(
      recebidoCentavos: 400000,
      alocadoCentavos: 400000,
      repassadoCentavos: 300000,
    );
    final concorrencia = dominio.concorrenciaAlocacao(
      disponivelCentavos: 600000,
      pedidoACentavos: 400000,
      pedidoBCentavos: 300000,
    );
    simulacao.value = {
      'direito_fornecedor_centavos': direitos.direitoFornecedorPrevistoCentavos,
      'comissao_centavos': direitos.comissaoPrevistaCentavos,
      'a_receber_apos_4000_centavos': 600000,
      'elegivel_sem_politica': elegSemPolitica.elegivelCentavos,
      'motivo_sem_politica': elegSemPolitica.motivo,
      'elegivel_com_teto_3000': elegComPolitica.elegivelCentavos,
      'residual_apos_repasse_3000': conc.residual,
      'concorrencia_aceito_a': concorrencia.aceitoA,
      'concorrencia_aceito_b': concorrencia.aceitoB,
      'autorizar_nao_e_confirmado': true,
    };
  }

  Future<bool> registrarRecebimento({
    required int valorCentavos,
    String? referencia,
  }) async {
    if (enviando.value || idEvento.value.isEmpty) return false;
    enviando.value = true;
    erro.value = '';
    try {
      final chave =
          'rec-${idEvento.value}-$valorCentavos-${DateTime.now().millisecondsSinceEpoch}';
      await remote.registrarRecebimento(
        idEvento: idEvento.value,
        valorCentavos: valorCentavos,
        chaveIdempotencia: chave,
        referencia: referencia,
      );
      await carregarExtrato(idEvento.value);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> alocarManual({
    required String idRecebimento,
    required String idOrcamento,
    required String idContrato,
    required int valorCentavos,
    String? idFornecedor,
  }) async {
    if (enviando.value) return false;
    enviando.value = true;
    erro.value = '';
    try {
      await remote.alocar(
        idRecebimento: idRecebimento,
        chaveIdempotencia:
            'aloc-$idRecebimento-$idOrcamento-$valorCentavos-${DateTime.now().millisecondsSinceEpoch}',
        alocacoes: [
          {
            'idContrato': idContrato,
            'idOrcamento': idOrcamento,
            'valorCentavos': valorCentavos,
            if (idFornecedor != null) 'idFornecedor': idFornecedor,
          },
        ],
      );
      await carregarExtrato(idEvento.value);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  /// Prepara o repasse do contrato; com política ativa e saldo elegível
  /// já nasce `autorizado` (pronto para conferência no passo 4).
  Future<String?> prepararRepasse(Map<String, dynamic> contrato) async {
    if (enviando.value) return null;
    final idOrcamento = (contrato['id_orcamento'] ?? '').toString();
    final idFornecedor = (contrato['id_fornecedor'] ?? '').toString();
    final elegivel = _int(contrato['elegivel_centavos']);
    if (idOrcamento.isEmpty || idFornecedor.isEmpty || elegivel <= 0) {
      erro.value = 'Contrato sem valor elegível para repasse.';
      return null;
    }
    enviando.value = true;
    erro.value = '';
    try {
      final res = await remote.prepararRepasse(
        idContrato: (contrato['id_contrato'] ?? idOrcamento).toString(),
        idOrcamento: idOrcamento,
        idFornecedor: idFornecedor,
        valorCentavos: elegivel,
        percentualBps: _int(contrato['percentual_bps'], padrao: 500),
        valorContratadoCentavos: _int(contrato['valor_contratado_centavos']),
        chaveIdempotencia:
            'rep-$idOrcamento-$elegivel-${DateTime.now().millisecondsSinceEpoch}',
      );
      await carregarExtrato(idEvento.value);
      return (res['estado'] ?? '').toString();
    } catch (e) {
      erro.value = e.toString();
      return null;
    } finally {
      enviando.value = false;
    }
  }

  Future<bool> salvarPolitica({
    required bool ativa,
    required bool permiteParcial,
    int? tetoParcialCentavos,
  }) async {
    if (enviando.value) return false;
    enviando.value = true;
    erro.value = '';
    try {
      final atual = extrato.value?['politica_liberacao'];
      final idAtual = atual is Map ? (atual['id'] ?? '').toString() : null;
      await remote.salvarPoliticaLiberacao(
        idPolitica: idAtual,
        ativa: ativa,
        permiteRepasseParcial: permiteParcial,
        tetoParcialCentavos: permiteParcial ? tetoParcialCentavos : null,
      );
      if (idEvento.value.isNotEmpty) await carregarExtrato(idEvento.value);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }

  static int _int(dynamic v, {int padrao = 0}) =>
      v is num ? v.toInt() : padrao;

  Future<bool> confirmarRepasse(String idRepasse) async {
    if (enviando.value) return false;
    enviando.value = true;
    erro.value = '';
    try {
      await remote.confirmarRepasseManual(
        idRepasse: idRepasse,
        evidencias: 'Conferência manual — sem transferência bancária integrada.',
      );
      await carregarExtrato(idEvento.value);
      return true;
    } catch (e) {
      erro.value = e.toString();
      return false;
    } finally {
      enviando.value = false;
    }
  }
}
