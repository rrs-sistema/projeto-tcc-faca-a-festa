import 'caixa_fornecedor_service.dart';
export 'caixa_fornecedor_service.dart';
import 'package:app_faca_festa/domain/entities/financeiro/alerta_financeiro.dart';

/// Visão privada do fornecedor: vendas ≠ lucro; adiantamento ≠ receita realizada.
class ResumoFinanceiroFornecedor {
  const ResumoFinanceiroFornecedor({
    required this.idFornecedor,
    this.idEvento,
    this.liquidoPrevisto,
    this.comissaoContratada,
    this.repasseAutorizado,
    this.recebimentoNaoAlocado = 0,
    this.creditoExcedente = 0,
    this.contratado = 0,
    this.recebido = 0,
    this.aReceber = 0,
    this.custoRealizado = 0,
    this.custoRestantePrevisto = 0,
    this.custoDiretoPrevisto = 0,
    this.outrasDespesasInformadas = 0,
    this.outrasDespesasAusentes = true,
    this.comissaoInformada,
    this.taxasInformadas,
    this.tributosInformados,
    this.receitaRealizada = 0,
    this.adiantamentosCaixa = 0,
    this.resultadoDiretoPrevisto = 0,
    this.resultadoDiretoRealizado = 0,
    this.margemContribuicao,
    this.saldoInicialInformado,
    this.entradasCaixa = 0,
    this.saidasCaixa = 0,
    this.saldoFinal,
    this.movimentoLiquido = 0,
    this.contasVencidas = 0,
    this.completo = false,
    this.formulaResultado =
        'resultado_direto = receita_aplicavel − custo_direto (− comissão/taxas/tributos informados)',
    this.origem = 'financeiro_fornecedor_privado',
    this.alertas = const [],
  });

  final String idFornecedor;
  final String? idEvento;
  final double? liquidoPrevisto;
  final double? comissaoContratada;
  final double? repasseAutorizado;
  final double recebimentoNaoAlocado;
  final double creditoExcedente;
  final double contratado;
  final double recebido;
  final double aReceber;
  final double custoRealizado;
  final double custoRestantePrevisto;
  final double custoDiretoPrevisto;
  final double outrasDespesasInformadas;
  final bool outrasDespesasAusentes;
  final double? comissaoInformada;
  final double? taxasInformadas;
  final double? tributosInformados;

  /// Receita reconhecida por execução/entrega — não por mero adiantamento.
  final double receitaRealizada;
  final double adiantamentosCaixa;
  final double resultadoDiretoPrevisto;
  final double resultadoDiretoRealizado;

  /// Margem de contribuição — nunca rotulada como lucro líquido.
  final double? margemContribuicao;
  final double? saldoInicialInformado;
  final double entradasCaixa;
  final double saidasCaixa;
  final double? saldoFinal;
  final double movimentoLiquido;
  final double contasVencidas;
  final bool completo;
  final String formulaResultado;
  final String origem;
  final List<AlertaFinanceiro> alertas;
}

class VendaFornecedorFato {
  const VendaFornecedorFato({
    required this.id,
    required this.idEvento,
    required this.valorContratado,
    this.liquidoPrevisto,
    this.comissao,
    this.repasseAutorizado = 0,
    this.recebimentoProprioDeclarado = 0,
    this.revisao,
    this.repasseConfirmado = 0,
    this.saldoContrato,
    this.recebidoConfirmado = 0,
    this.adiantamentoCaixa = 0,
    this.receitaRealizada = 0,
    this.execucaoConfirmada = false,
    this.categoria,
    this.nomeServico,
    this.situacao,
    this.vencimento,
  });

  final String id;
  final String idEvento;
  final double valorContratado;
  final double? liquidoPrevisto;
  final double? comissao;
  final double repasseAutorizado;
  final double recebimentoProprioDeclarado;
  final String? revisao;

  /// Recebimento na perspectiva do fornecedor (não copia pagamento do cliente).
  final double repasseConfirmado;
  final double? saldoContrato;
  final double recebidoConfirmado;
  final double adiantamentoCaixa;
  final double receitaRealizada;
  final bool execucaoConfirmada;
  final String? categoria;
  final String? nomeServico;

  /// aguardando_repasse | parcial | recebido
  final String? situacao;
  final DateTime? vencimento;

  double get aReceber => situacao == 'cancelado'
      ? 0
      : (saldoContrato ??
          (liquidoPrevisto ?? valorContratado) - recebidoConfirmado);
}

class CustoFornecedorFato {
  const CustoFornecedorFato({
    required this.id,
    required this.idEvento,
    required this.incorrido,
    this.restantePrevisto = 0,
    this.desembolsoCaixa = 0,
    this.origem = 'manual',
    this.tipo = 'outro',
    this.direto = true,
    this.categoria,
  });

  final String id;
  final String idEvento;
  final double incorrido;
  final double restantePrevisto;
  final double desembolsoCaixa;
  final String origem;
  final String tipo;
  final bool direto;
  final String? categoria;
}

class MovimentoCaixaFornecedor {
  const MovimentoCaixaFornecedor({
    required this.id,
    required this.valor,
    required this.entrada,
    this.referenciaRecebimento,
    this.chaveIdempotencia,
    this.idEvento,
    this.vencimento,
    this.descricao,
  });

  final String? referenciaRecebimento, chaveIdempotencia;
  final String id;
  final double valor;
  final bool entrada;
  final String? idEvento;
  final DateTime? vencimento;
  final String? descricao;
}

class ResumoFinanceiroFornecedorService {
  const ResumoFinanceiroFornecedorService();

  ResumoFinanceiroFornecedor calcular({
    required String idFornecedor,
    String? idEvento,
    List<VendaFornecedorFato> vendas = const [],
    List<CustoFornecedorFato> custos = const [],
    List<MovimentoCaixaFornecedor> movimentos = const [],
    List<RecebimentoCaixaFato>? recebimentos,
    double? saldoInicialInformado,
    double? comissaoInformada,
    double? taxasInformadas,
    double? tributosInformados,
    bool consultaCompleta = true,
    DateTime? agora,
  }) {
    final caixa = recebimentos == null
        ? null
        : conciliarCaixaFornecedor(
            recebimentos: recebimentos,
            contratosConhecidos: vendas.map((v) => v.id).toSet(),
            movimentos: movimentos
                .map((m) => CaixaMovimentoFato(
                    id: m.id,
                    idEvento: m.idEvento ?? '',
                    valorCentavos: (m.valor * 100).round(),
                    entrada: m.entrada,
                    referencia: m.referenciaRecebimento,
                    chave: m.chaveIdempotencia,
                    origem: m.descricao))
                .toList(),
            idEvento: idEvento);
    final agoraRef = agora ?? DateTime.now();
    var contratado = 0.0,
        recebido = 0.0,
        aReceber = 0.0,
        receitaRealizada = 0.0,
        adiantamentos = 0.0,
        contasVencidas = 0.0;
    var creditoExcedente = 0.0;
    var custoRealizado = 0.0, custoRestante = 0.0, outras = 0.0;
    var temOutras = false;
    var completo = consultaCompleta;
    final alertas = <AlertaFinanceiro>[];

    for (final v in vendas) {
      if (idEvento != null && v.idEvento != idEvento) continue;
      if (!_fin(v.valorContratado) ||
          !_fin(v.recebidoConfirmado) ||
          !_fin(v.receitaRealizada)) {
        completo = false;
        continue;
      }
      contratado += v.valorContratado;
      recebido += caixa == null ? v.recebidoConfirmado : v.repasseConfirmado;
      adiantamentos += v.adiantamentoCaixa;
      // A receber independente dos custos.
      final saldo = v.situacao == 'cancelado'
          ? 0.0
          : v.saldoContrato ??
              (caixa == null
                  ? v.aReceber
                  : (v.liquidoPrevisto ?? v.valorContratado) -
                      v.repasseConfirmado -
                      (caixa.porContrato[v.id] ?? 0) / 100);
      if (saldo >= 0) {
        aReceber += saldo;
      } else {
        creditoExcedente -= saldo;
      }
      if (v.execucaoConfirmada) {
        receitaRealizada +=
            v.receitaRealizada > 0 ? v.receitaRealizada : v.valorContratado;
      } else if (v.receitaRealizada > 0) {
        // Receita só com regra explícita de execução/entrega.
        receitaRealizada += v.receitaRealizada;
      }
      // Adiantamento afeta caixa, não vira receita automática.
      if (v.vencimento != null &&
          saldo > 0 &&
          v.vencimento!.isBefore(agoraRef)) {
        contasVencidas += saldo;
      }
    }

    for (final c in custos) {
      if (idEvento != null && c.idEvento != idEvento) continue;
      if (!_fin(c.incorrido) || !_fin(c.restantePrevisto)) {
        completo = false;
        continue;
      }
      if (c.direto) {
        custoRealizado += c.incorrido;
        custoRestante += c.restantePrevisto;
      } else {
        temOutras = true;
        outras += c.incorrido + c.restantePrevisto;
      }
    }

    final custoDiretoPrevisto = custoRealizado + custoRestante;
    final outrasAusentes = !temOutras;

    double deducoes = 0;
    var temDeducoes = false;
    if (comissaoInformada != null && _fin(comissaoInformada)) {
      deducoes += comissaoInformada;
      temDeducoes = true;
    }
    if (taxasInformadas != null && _fin(taxasInformadas)) {
      deducoes += taxasInformadas;
      temDeducoes = true;
    }
    if (tributosInformados != null && _fin(tributosInformados)) {
      deducoes += tributosInformados;
      temDeducoes = true;
    }
    if (!temDeducoes || outrasAusentes) {
      // Componentes relevantes ausentes → resultado parcial.
      if (!temDeducoes || outrasAusentes) completo = false;
      if (!temDeducoes) {
        alertas.add(const AlertaFinanceiro(
          tipo: TipoAlertaFinanceiro.consultaIncompleta,
          mensagem:
              'Comissão, taxas ou tributos não informados: resultado parcial.',
        ));
      }
      if (outrasAusentes) {
        alertas.add(const AlertaFinanceiro(
          tipo: TipoAlertaFinanceiro.consultaIncompleta,
          mensagem:
              'Outras despesas não informadas: ficam explícitas como ausentes.',
        ));
      }
    }

    final receitaPrevista = contratado;
    final resultadoPrevisto =
        receitaPrevista - custoDiretoPrevisto - deducoes - outras;
    final resultadoRealizado = receitaRealizada - custoRealizado - deducoes;

    // Margem de contribuição (não é lucro líquido).
    final margem =
        receitaRealizada > 0 ? receitaRealizada - custoRealizado : null;

    if ((caixa?.legadoNaoConciliado ?? 0) > 0) {
      completo = false;
      alertas.add(const AlertaFinanceiro(
          tipo: TipoAlertaFinanceiro.consultaIncompleta,
          mensagem:
              'Registros legados de caixa sem origem conciliada foram preservados, sem somar uma entrada incerta.'));
    }
    var entradas = 0.0, saidas = 0.0, naoAlocado = 0.0;
    if (caixa != null) {
      recebido += recebimentos!
          .where((r) =>
              !r.repasseLegado && (idEvento == null || r.idEvento == idEvento))
          .fold<double>(
              0, (s, r) => s + (r.estorno ? -1 : 1) * r.valorCentavos / 100);
      entradas = caixa.entradas / 100 +
          vendas
              .where((v) => idEvento == null || v.idEvento == idEvento)
              .fold<double>(0, (s, v) => s + v.repasseConfirmado);
      saidas = caixa.saidas / 100;
      naoAlocado = caixa.naoAlocado / 100;
      adiantamentos = caixa.adiantamentos / 100;
    } else {
      final filtrados = movimentos
          .where((m) => idEvento == null || m.idEvento == idEvento)
          .toList();
      for (final m in filtrados) {
        if (!_fin(m.valor)) {
          completo = false;
          continue;
        }
        if (m.entrada) {
          entradas += m.valor;
        } else {
          saidas += m.valor;
        }
      }
      if (filtrados.any((m) => m.entrada) && recebido > 0) {
        completo = false;
        alertas.add(const AlertaFinanceiro(
            tipo: TipoAlertaFinanceiro.consultaIncompleta,
            mensagem:
                'Caixa legado sem identidade de origem: entradas não são somadas novamente aos recebimentos agregados.'));
      } else {
        entradas += recebido;
      }
    }
    // Desembolsos de custo (não consumo de estoque prévio).
    for (final c in custos) {
      if (idEvento != null && c.idEvento != idEvento) continue;
      if (c.origem == 'estoque_consumo') continue; // custo sem nova saída
      saidas += c.desembolsoCaixa;
    }

    final movimentoLiquido = entradas - saidas;
    double? saldoFinal;
    if (saldoInicialInformado != null && _fin(saldoInicialInformado)) {
      saldoFinal = saldoInicialInformado + movimentoLiquido;
    }

    return ResumoFinanceiroFornecedor(
      idFornecedor: idFornecedor,
      idEvento: idEvento,
      contratado: contratado,
      recebimentoNaoAlocado: naoAlocado,
      creditoExcedente: creditoExcedente,
      recebido: recebido,
      aReceber: aReceber,
      custoRealizado: custoRealizado,
      custoRestantePrevisto: custoRestante,
      custoDiretoPrevisto: custoDiretoPrevisto,
      outrasDespesasInformadas: outras,
      outrasDespesasAusentes: outrasAusentes,
      comissaoInformada: comissaoInformada,
      taxasInformadas: taxasInformadas,
      tributosInformados: tributosInformados,
      receitaRealizada: receitaRealizada,
      adiantamentosCaixa: adiantamentos,
      resultadoDiretoPrevisto: resultadoPrevisto,
      resultadoDiretoRealizado: resultadoRealizado,
      margemContribuicao: margem,
      saldoInicialInformado: saldoInicialInformado,
      entradasCaixa: entradas,
      saidasCaixa: saidas,
      saldoFinal: saldoFinal,
      movimentoLiquido: movimentoLiquido,
      contasVencidas: contasVencidas,
      completo: completo,
      alertas: alertas,
    );
  }

  bool _fin(num? v) => v != null && v.isFinite && v >= 0;
}
