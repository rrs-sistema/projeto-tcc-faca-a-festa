import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:app_faca_festa/domain/entities/financeiro/alerta_financeiro.dart';
import 'package:app_faca_festa/domain/services/previsao_financeira_gerente_service.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_gerente_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/financeiro_fornecedor_controller.dart'
    show agruparAlertasFinanceiros;
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';

/// Detalhe financeiro de um evento do organizador.
class FinanceiroGerenteDetalhePage extends StatefulWidget {
  const FinanceiroGerenteDetalhePage({
    super.key,
    required this.controller,
    required this.themeController,
    required this.idEvento,
  });

  final FinanceiroGerenteController controller;
  final EventThemeController themeController;
  final String idEvento;

  @override
  State<FinanceiroGerenteDetalhePage> createState() =>
      _FinanceiroGerenteDetalhePageState();
}

class _FinanceiroGerenteDetalhePageState
    extends State<FinanceiroGerenteDetalhePage> {
  final _fmt = DateFormat('dd/MM/yyyy');
  bool _comoCalculado = false;

  FinanceiroGerenteController get c => widget.controller;

  String _reais(double? v) {
    if (v == null) return '—';
    return 'R\$ ${Biblioteca.formatarValorDecimal(v)}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = c.detalheAtual.value;
      final primary = widget.themeController.primaryColor.value;
      final surface = widget.themeController.surfaceColor.value;
      c.linhasDetalhe.length;
      c.simulacaoAtual.value;

      if (p == null || p.idEvento != widget.idEvento) {
        return Scaffold(
          backgroundColor: surface.withValues(alpha: 0.35),
          appBar: FestaAppBar(
            titulo: 'Financeiro',
            themeController: widget.themeController,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sem dados autorizados deste evento.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ),
        );
      }

      final w = MediaQuery.sizeOf(context).width;
      final pad = w >= 1100 ? 28.0 : (w >= 720 ? 20.0 : 16.0);
      final maxW = w >= 1280 ? 1400.0 : w;

      return Scaffold(
        backgroundColor: surface.withValues(alpha: 0.35),
        appBar: FestaAppBar(
          titulo: p.nomeEvento,
          themeController: widget.themeController,
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: ListView(
              padding: EdgeInsets.fromLTRB(pad, FestaPageInsets.belowAppBar, pad, 32),
              children: [
                _cabecalhoEvento(p, primary),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => Get.toNamed(
                      '/acompanhamento-organizador',
                      arguments: {
                        'idEvento': widget.idEvento,
                        'nomeEvento': p.nomeEvento,
                      },
                    ),
                    icon: const Icon(Icons.handshake_outlined, size: 18),
                    label: Text(
                      'Acompanhar contratações e pagamento à plataforma',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _blocoOrcamento(p, primary),
                const SizedBox(height: 12),
                _blocoRealizado(p, primary),
                const SizedBox(height: 12),
                _alertas(p.alertas, primary),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      setState(() => _comoCalculado = !_comoCalculado),
                  child: Text(
                    _comoCalculado ? 'Ocultar cálculo' : 'Como é calculado',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
                if (_comoCalculado) _explicacaoCalculo(p),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => c.simularCenariosEvento(widget.idEvento),
                    icon: const Icon(Icons.science_outlined, size: 18),
                    label: Text(
                      'Simular orçamento',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      minimumSize: const Size(48, 48),
                      side: BorderSide(color: primary.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
                _simulacao(primary),
                const SizedBox(height: 16),
                Text(
                  'Serviços e compromissos',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                if (w >= 768)
                  _tabelaLinhas(primary)
                else
                  _listaLinhas(primary),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _cabecalhoEvento(PrevisaoFinanceiraGerente p, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.nomeEvento,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          p.dataEvento != null
              ? _fmt.format(p.dataEvento!)
              : 'Data não informada',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _blocoOrcamento(PrevisaoFinanceiraGerente p, Color primary) {
    final statusTxt = !p.completo
        ? 'Projeção parcial — não afirma que cabe no orçamento.'
        : p.limiteConfirmado == null
            ? 'Limite não informado.'
            : p.cabeNoLimite == true
                ? 'Previsão cabe no limite (antes da reserva).'
                : p.cabeNoLimite == false
                    ? 'Previsão acima do limite.'
                    : 'Sem conclusão de orçamento.';
    final statusCor = !p.completo || p.cabeNoLimite == false
        ? Colors.orange.shade800
        : primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orçamento e previsão',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _metricLine('Limite', _reais(p.limiteConfirmado), destaque: true),
          _metricLine('Previsão final', _reais(p.custoFinalPrevisto),
              destaque: true),
          if (p.folgaAntesReserva != null)
            _metricLine(
              p.folgaAntesReserva! >= 0
                  ? 'Folga (antes da reserva)'
                  : 'Excesso (antes da reserva)',
              _reais(p.folgaAntesReserva),
            ),
          if (p.reservaContingencia > 0)
            _metricLine('Reserva de contingência', _reais(p.reservaContingencia)),
          if (p.folgaAposReserva != null)
            _metricLine('Folga após reserva', _reais(p.folgaAposReserva)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                !p.completo
                    ? Icons.info_outline
                    : (p.cabeNoLimite == false
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline),
                size: 18,
                color: statusCor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTxt,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: statusCor,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blocoRealizado(PrevisaoFinanceiraGerente p, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contratos e pagamentos',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pagamentos já incluídos no contrato não entram de novo no custo.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          _metricLine('Contratado', _reais(p.contratado)),
          _metricLine('Pago', _reais(p.pagoLiquido)),
          _metricLine('Saldo a pagar', _reais(p.saldoContratado)),
          _metricLine('Falta contratar', _reais(p.faltaContratar)),
          _metricLine('Despesas adicionais', _reais(p.despesasAdicionais)),
        ],
      ),
    );
  }

  Widget _metricLine(String label, String value, {bool destaque = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: destaque ? 14 : 13,
                color: const Color(0xFF64748B),
                fontWeight: destaque ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: destaque ? 20 : 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertas(List<AlertaFinanceiro> alertas, Color primary) {
    final grupos = agruparAlertasFinanceiros(alertas);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atenções',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (grupos.isEmpty)
            Text(
              'Nenhum alerta verificável no momento.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            )
          else
            ...grupos.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.orange.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.quantidade > 1
                              ? '${a.mensagem} (${a.quantidade})'
                              : a.mensagem,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _explicacaoCalculo(PrevisaoFinanceiraGerente p) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        'Previsão final = contratos + o que ainda falta contratar + '
        'despesas adicionais + cancelamentos devidos.\n'
        'Saldo a pagar = contratado − pago.\n'
        'Folga = limite − previsão (quando limite e projeção estão completos).\n'
        'Pagamentos já contidos nos contratos não são somados de novo.',
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          color: const Color(0xFF64748B),
          height: 1.4,
        ),
      ),
    );
  }

  Widget _simulacao(Color primary) {
    final s = c.simulacaoAtual.value;
    if (s == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hipótese de orçamento',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Não altera contratos, pagamentos nem o limite. '
            'Separada dos fatos do evento.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Livre antes de despesas/reserva: '
            '${_reais(s.orcamentoLivreAntesDespesasCentavos / 100.0)}',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          ...s.cenarios.map((cen) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  cen.disponivel
                      ? '${cen.tipo.name}: previsão ${_reais(cen.previsaoCentavos / 100.0)}, '
                          'folga/excesso ${_reais(cen.folgaOuExcessoCentavos / 100.0)}'
                      : '${cen.tipo.name}: ${cen.motivoIndisponivel ?? 'indisponível'}',
                  style: GoogleFonts.poppins(fontSize: 12.5),
                ),
              )),
          if (!s.completo)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Projeção parcial na simulação (itens sem preço).',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabelaLinhas(Color primary) {
    final linhas = c.linhasDetalhe;
    if (linhas.isEmpty) {
      return Text(
        'Nenhum compromisso neste recorte.',
        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
          dataTextStyle: GoogleFonts.poppins(fontSize: 13),
          columns: const [
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('Categoria')),
            DataColumn(label: Text('Fornecedor')),
            DataColumn(label: Text('Contratado'), numeric: true),
            DataColumn(label: Text('Pago'), numeric: true),
            DataColumn(label: Text('Saldo'), numeric: true),
          ],
          rows: linhas
              .map((l) => DataRow(cells: [
                    DataCell(Text(l.necessidade)),
                    DataCell(Text(l.categoria ?? '—')),
                    DataCell(Text(l.fornecedor ?? '—')),
                    DataCell(Text(_reais(l.valorContratado))),
                    DataCell(Text(_reais(l.pagoLiquido))),
                    DataCell(Text(_reais(l.saldo))),
                  ]))
              .toList(),
        ),
      ),
    );
  }

  Widget _listaLinhas(Color primary) {
    final linhas = c.linhasDetalhe;
    if (linhas.isEmpty) {
      return Text(
        'Nenhum compromisso neste recorte.',
        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF64748B)),
      );
    }
    return Column(
      children: linhas.map((l) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.necessidade,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  if (l.categoria != null) l.categoria!,
                  if (l.fornecedor != null) l.fornecedor!,
                  l.estadoComercial ?? '—',
                ].join(' · '),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Contratado ${_reais(l.valorContratado)} · '
                'Pago ${_reais(l.pagoLiquido)} · '
                'Saldo ${_reais(l.saldo)}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
