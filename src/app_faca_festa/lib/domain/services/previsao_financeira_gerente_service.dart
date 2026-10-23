import 'package:app_faca_festa/domain/entities/financeiro/alerta_financeiro.dart';
import 'package:app_faca_festa/domain/services/cobertura_parcial_necessidade_service.dart';
import 'package:app_faca_festa/domain/services/resumo_financeiro_evento_service.dart';

/// Necessidade descoberta ainda não (totalmente) contratada.
class NecessidadeFinanceiraDescoberta {
  const NecessidadeFinanceiraDescoberta({
    required this.id,
    required this.descricao,
    this.categoria,
    this.quantidadeNecessaria,
    this.quantidadeContratada = 0,
    this.precoUnitario,
    this.custoEstimadoTotal,
    this.cobertaPorBuffet = false,
    this.eliminada = false,
    this.fonte = 'descoberta',
  });

  final String id;
  final String descricao;
  final String? categoria;
  final double? quantidadeNecessaria;
  final double quantidadeContratada;
  final double? precoUnitario;

  /// Quando já se conhece o custo restante em reais (ex.: compras da calculadora).
  final double? custoEstimadoTotal;
  final bool cobertaPorBuffet;
  final bool eliminada;
  final String fonte;
}

class LinhaDetalheFinanceiroGerente {
  const LinhaDetalheFinanceiroGerente({
    required this.id,
    required this.necessidade,
    this.categoria,
    this.fornecedor,
    this.contrato,
    this.vencimento,
    this.estadoComercial,
    this.valorContratado = 0,
    this.pagoLiquido = 0,
    this.saldo = 0,
    this.fonte = 'orcamento',
  });

  final String id;
  final String necessidade;
  final String? categoria;
  final String? fornecedor;
  final String? contrato;
  final DateTime? vencimento;
  final String? estadoComercial;
  final double valorContratado;
  final double pagoLiquido;
  final double saldo;
  final String fonte;
}

/// Visão do gerente do evento: contratado, pago, falta contratar e se cabe no limite.
class PrevisaoFinanceiraGerente {
  const PrevisaoFinanceiraGerente({
    required this.idEvento,
    required this.nomeEvento,
    this.dataEvento,
    this.limiteConfirmado,
    this.contratado = 0,
    this.pagoLiquido = 0,
    this.saldoContratado = 0,
    this.faltaContratar = 0,
    this.despesasAdicionais = 0,
    this.custosCancelamentoDevidos = 0,
    this.custoFinalPrevisto = 0,
    this.reservaContingencia = 0,
    this.folgaAntesReserva,
    this.folgaAposReserva,
    this.completo = false,
    this.cabeNoLimite,
    this.origem = 'previsao_gerente',
    this.eixoTemporal = 'mes_evento',
    this.alertas = const [],
    this.detalhes = const [],
    this.qtdContratos = 0,
    this.qtdLinhasServico = 0,
    this.qtdFornecedores = 0,
  });

  final String idEvento;
  final String nomeEvento;
  final DateTime? dataEvento;
  final double? limiteConfirmado;
  final double contratado;
  final double pagoLiquido;

  /// Contratado − pago líquido (sem clamp que esconda excesso).
  final double saldoContratado;
  final double faltaContratar;
  final double despesasAdicionais;
  final double custosCancelamentoDevidos;

  /// Contratos + necessidades restantes + despesas fora dos contratos + cancelamentos devidos.
  /// Pagamentos já contidos nos contratos não entram de novo.
  final double custoFinalPrevisto;
  final double reservaContingencia;
  final double? folgaAntesReserva;
  final double? folgaAposReserva;
  final bool completo;

  /// null = não afirma (projeção parcial / sem limite).
  final bool? cabeNoLimite;
  final String origem;

  /// `mes_evento` | `mes_pagamento` — recortes distintos.
  final String eixoTemporal;
  final List<AlertaFinanceiro> alertas;
  final List<LinhaDetalheFinanceiroGerente> detalhes;
  final int qtdContratos;
  final int qtdLinhasServico;
  final int qtdFornecedores;
}

class PrevisaoFinanceiraGerenteService {
  const PrevisaoFinanceiraGerenteService({
    this.resumoService = const ResumoFinanceiroEventoService(),
    this.coberturaParcial = const CoberturaParcialNecessidadeService(),
  });

  final ResumoFinanceiroEventoService resumoService;
  final CoberturaParcialNecessidadeService coberturaParcial;

  PrevisaoFinanceiraGerente calcular({
    required String idEvento,
    required String nomeEvento,
    DateTime? dataEvento,
    double? limiteConfirmado,
    double reservaContingencia = 0,
    List<Map<String, dynamic>> compromissos = const [],
    List<NecessidadeFinanceiraDescoberta> necessidades = const [],
    bool consultaCompleta = true,
    String eixoTemporal = 'mes_evento',
    DateTime? agora,
  }) {
    final agoraRef = agora ?? DateTime.now();
    final resumo = resumoService.calcular(
      compromissos,
      consultaCompleta: consultaCompleta,
      limiteConfirmado: limiteConfirmado,
    );

    final contratado = resumo.contratado;
    final pagoLiquido = resumo.pagoLiquido;
    final saldoContratado = contratado - pagoLiquido;

    var faltaContratar = 0.0;
    var despesasAdicionais = 0.0;
    var custosCancelamento = 0.0;
    var completo = resumo.completo;
    final alertas = <AlertaFinanceiro>[];

    // Despesas fora de contratos ativos + cancelamentos ainda devidos.
    for (final c in compromissos) {
      final despesas = _num(c['despesas']);
      final cancelado = c['cancelado'] == true;
      final contratadoFlag = c['contratado'] == true;
      if (cancelado) {
        final saldo = c['saldo_devido'];
        if (saldo is num && saldo.isFinite && saldo > 0) {
          custosCancelamento += saldo.toDouble();
        } else {
          final retencao = _num(c['retencao']);
          final pago = _num(c['pago'], permiteNegativo: true);
          final valor = _num(c['valor_contratado'] ?? c['valor']);
          final devido = valor - pago + retencao - _num(c['reembolso']);
          if (devido > 0) custosCancelamento += devido;
        }
        continue;
      }
      if (!contratadoFlag && despesas > 0) {
        despesasAdicionais += despesas;
      }
    }

    for (final n in necessidades) {
      if (n.eliminada) continue; // retira escopo sem apagar história na origem
      if (n.cobertaPorBuffet) continue; // sem compra duplicada

      if (n.quantidadeNecessaria != null) {
        final proj = coberturaParcial.projetar(
          necessidade: n.quantidadeNecessaria!,
          quantidadeContratada: n.quantidadeContratada,
          precoUnitario: n.precoUnitario,
        );
        if (proj.coberturaIntegral) continue;
        if (proj.precoAusente) {
          completo = false;
          alertas.add(AlertaFinanceiro(
            tipo: TipoAlertaFinanceiro.precoAusente,
            mensagem:
                'Necessidade "${n.descricao}" sem preço: projeção parcial.',
            idEvento: idEvento,
            idNecessidade: n.id,
          ));
          alertas.add(AlertaFinanceiro(
            tipo: TipoAlertaFinanceiro.necessidadeSemContratacao,
            mensagem:
                'Necessidade "${n.descricao}" ainda sem contratação completa.',
            idEvento: idEvento,
            idNecessidade: n.id,
          ));
          continue;
        }
        faltaContratar += proj.custoProjetado ?? 0;
        if (proj.quantidadeRestante > 0) {
          alertas.add(AlertaFinanceiro(
            tipo: TipoAlertaFinanceiro.necessidadeSemContratacao,
            mensagem:
                'Faltam ${proj.quantidadeRestante.toStringAsFixed(0)} un. de "${n.descricao}".',
            idEvento: idEvento,
            idNecessidade: n.id,
          ));
        }
        continue;
      }

      final estimado = n.custoEstimadoTotal;
      if (estimado == null || !estimado.isFinite || estimado < 0) {
        completo = false;
        alertas.add(AlertaFinanceiro(
          tipo: TipoAlertaFinanceiro.precoAusente,
          mensagem: 'Necessidade "${n.descricao}" sem preço: projeção parcial.',
          idEvento: idEvento,
          idNecessidade: n.id,
        ));
        continue;
      }
      if (estimado > 0) {
        faltaContratar += estimado;
        alertas.add(AlertaFinanceiro(
          tipo: TipoAlertaFinanceiro.necessidadeSemContratacao,
          mensagem: 'Necessidade "${n.descricao}" ainda não contratada.',
          idEvento: idEvento,
          idNecessidade: n.id,
        ));
      }
    }

    final previsto =
        contratado + faltaContratar + despesasAdicionais + custosCancelamento;

    double? folgaAntes;
    double? folgaApos;
    bool? cabe;
    final limite = limiteConfirmado != null &&
            limiteConfirmado.isFinite &&
            limiteConfirmado >= 0
        ? limiteConfirmado
        : null;
    if (limite != null && completo) {
      folgaAntes = limite - previsto;
      final reserva = reservaContingencia.isFinite && reservaContingencia > 0
          ? reservaContingencia
          : 0.0;
      folgaApos = limite - previsto - reserva;
      cabe = previsto <= limite;
      if (previsto > limite) {
        alertas.add(AlertaFinanceiro(
          tipo: TipoAlertaFinanceiro.excessoPrevisto,
          mensagem:
              'Previsão R\$ ${previsto.toStringAsFixed(2)} acima do limite R\$ ${limite.toStringAsFixed(2)}.',
          idEvento: idEvento,
        ));
      }
    } else if (limite != null && !completo) {
      // Informação incompleta não sustenta afirmação de que cabe.
      cabe = null;
      alertas.add(const AlertaFinanceiro(
        tipo: TipoAlertaFinanceiro.consultaIncompleta,
        mensagem:
            'Projeção parcial: não é possível afirmar que o evento cabe no orçamento.',
      ));
    }

    // Vencimentos / atrasos nas linhas contratadas.
    final detalhes = <LinhaDetalheFinanceiroGerente>[];
    final fornecedores = <String>{};
    var qtdContratos = 0;
    for (final c in compromissos) {
      if (c['contratado'] == true) qtdContratos++;
      final forn =
          c['fornecedor']?.toString() ?? c['nome_fornecedor']?.toString();
      if (forn != null && forn.trim().isNotEmpty) fornecedores.add(forn);
      final venc = _data(c['vencimento'] ?? c['data_vencimento']);
      if (venc != null && c['contratado'] == true) {
        final saldo = _num(c['saldo_devido'], permiteNegativo: true);
        if (saldo > 0) {
          if (venc.isBefore(agoraRef)) {
            alertas.add(AlertaFinanceiro(
              tipo: TipoAlertaFinanceiro.atraso,
              mensagem:
                  'Pagamento em atraso desde ${_fmtData(venc)} (${c['descricao'] ?? c['id']}).',
              idEvento: idEvento,
              idOrcamento: c['id']?.toString(),
            ));
          } else if (venc.difference(agoraRef).inDays <= 7) {
            alertas.add(AlertaFinanceiro(
              tipo: TipoAlertaFinanceiro.vencimentoProximo,
              mensagem:
                  'Vencimento em ${_fmtData(venc)} (${c['descricao'] ?? c['id']}).',
              idEvento: idEvento,
              idOrcamento: c['id']?.toString(),
            ));
          }
        }
      }
      detalhes.add(LinhaDetalheFinanceiroGerente(
        id: (c['id'] ?? '').toString(),
        necessidade:
            (c['descricao'] ?? c['id_necessidade'] ?? 'Item').toString(),
        categoria: c['categoria']?.toString(),
        fornecedor: forn,
        contrato: c['contratado'] == true
            ? (c['id']?.toString() ?? 'contrato')
            : null,
        vencimento: venc,
        estadoComercial: c['contratado'] == true
            ? 'contratado'
            : (c['cancelado'] == true ? 'cancelado' : 'aberto'),
        valorContratado: c['contratado'] == true
            ? _num(c['valor_contratado'] ?? c['valor'])
            : 0,
        pagoLiquido: _num(c['pago'], permiteNegativo: true),
        saldo: _num(c['saldo_devido'], permiteNegativo: true),
        fonte: (c['fonte_financeira'] ?? 'orcamento').toString(),
      ));
    }

    return PrevisaoFinanceiraGerente(
      idEvento: idEvento,
      nomeEvento: nomeEvento,
      dataEvento: dataEvento,
      limiteConfirmado: limite,
      contratado: contratado,
      pagoLiquido: pagoLiquido,
      saldoContratado: saldoContratado,
      faltaContratar: faltaContratar,
      despesasAdicionais: despesasAdicionais,
      custosCancelamentoDevidos: custosCancelamento,
      custoFinalPrevisto: previsto,
      reservaContingencia:
          reservaContingencia.isFinite && reservaContingencia > 0
              ? reservaContingencia
              : 0,
      folgaAntesReserva: folgaAntes,
      folgaAposReserva: folgaApos,
      completo: completo,
      cabeNoLimite: cabe,
      eixoTemporal: eixoTemporal,
      alertas: alertas,
      detalhes: detalhes,
      qtdContratos: qtdContratos,
      qtdLinhasServico: detalhes.length,
      qtdFornecedores: fornecedores.length,
    );
  }

  double _num(dynamic v, {bool permiteNegativo = false}) {
    if (v is! num || !v.isFinite) return 0;
    if (v < 0 && !permiteNegativo) return 0;
    return v.toDouble();
  }

  DateTime? _data(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _fmtData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
