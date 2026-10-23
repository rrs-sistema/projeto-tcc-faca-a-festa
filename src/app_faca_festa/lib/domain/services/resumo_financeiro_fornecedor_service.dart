import 'package:app_faca_festa/domain/entities/financeiro/alerta_financeiro.dart';

/// Visão privada do fornecedor: vendas ≠ lucro; adiantamento ≠ receita realizada.
class ResumoFinanceiroFornecedor {
  const ResumoFinanceiroFornecedor({
    required this.idFornecedor,
    this.idEvento,
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

  /// Recebimento na perspectiva do fornecedor (não copia pagamento do cliente).
  final double recebidoConfirmado;
  final double adiantamentoCaixa;
  final double receitaRealizada;
  final bool execucaoConfirmada;
  final String? categoria;
  final String? nomeServico;
  /// aguardando_repasse | parcial | recebido
  final String? situacao;
  final DateTime? vencimento;

  double get aReceber =>
      (valorContratado - recebidoConfirmado).clamp(0, double.infinity);
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
    this.idEvento,
    this.vencimento,
    this.descricao,
  });

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
    double? saldoInicialInformado,
    double? comissaoInformada,
    double? taxasInformadas,
    double? tributosInformados,
    bool consultaCompleta = true,
    DateTime? agora,
  }) {
    final agoraRef = agora ?? DateTime.now();
    var contratado = 0.0,
        recebido = 0.0,
        aReceber = 0.0,
        receitaRealizada = 0.0,
        adiantamentos = 0.0,
        contasVencidas = 0.0;
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
      recebido += v.recebidoConfirmado;
      adiantamentos += v.adiantamentoCaixa;
      // A receber independente dos custos.
      final saldo = v.valorContratado - v.recebidoConfirmado;
      aReceber += saldo;
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

    var entradas = 0.0, saidas = 0.0;
    for (final m in movimentos) {
      if (idEvento != null && m.idEvento != null && m.idEvento != idEvento) {
        continue;
      }
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
    // Adiantamentos e recebimentos confirmados entram no caixa.
    entradas += recebido;
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
