import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/contacao/cotacao_controller.dart';
import '../../../../controllers/orcamento_controller.dart';
import '../../../../data/models/model.dart';
import 'fornecedor_premium_layout.dart';

enum TipoVisualizacao { semana, mes }

class FinanceiroSection extends StatelessWidget {
  const FinanceiroSection({super.key});

  static final Rx<TipoVisualizacao> _tipoVisualizacao = TipoVisualizacao.semana.obs;

  @override
  Widget build(BuildContext context) {
    final orcamentoController = Get.find<OrcamentoController>();
    final cotacaoController = Get.find<CotacaoController>();

    return Obx(() {
      final orcamentos = orcamentoController.orcamentos;
      final cotacoes = cotacaoController.cotacoes;

      final recebido = orcamentos
          .where((o) => o.status == StatusOrcamento.fechado)
          .fold(0.0, (soma, o) => soma + (o.custoEstimado ?? 0));
      final estimado = cotacoes
          .where((c) =>
              c.status == StatusCotacao.pendente ||
              c.status == StatusCotacao.respondida ||
              c.status == StatusCotacao.parcial)
          .fold(0.0, (soma, c) => soma + (c.valorEstimadoTotal ?? 0));
      final agora = DateTime.now();
      final faturamentoMes = orcamentos
          .where((o) =>
              o.status == StatusOrcamento.fechado &&
              o.dataFechamento != null &&
              o.dataFechamento!.month == agora.month &&
              o.dataFechamento!.year == agora.year)
          .fold(0.0, (soma, o) => soma + (o.custoEstimado ?? 0));

      final topContratos = _pegarContratosRecentes(orcamentos);
      final resumoCategorias = _agruparPorCategoria(orcamentos);

      return PremiumSectionShell(
        title: 'Relatório financeiro',
        subtitle: 'Receita, oportunidades abertas e evolução de contratos fechados.',
        icon: Icons.monetization_on_outlined,
        color: FornecedorPremiumPalette.emerald,
        trailing: OutlinedButton.icon(
          onPressed: () => Get.snackbar(
            'Relatório',
            'Gerando documento em PDF...',
            backgroundColor: FornecedorPremiumPalette.dark,
            colorText: Colors.white,
          ),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: Text(
            'Exportar PDF',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 11.5),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: FornecedorPremiumPalette.dark,
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveWrapGrid(
              minTileWidth: 215,
              maxColumns: 3,
              children: [
                PremiumMetricTile(
                  label: 'Recebido',
                  value: _money(recebido),
                  subtitle: 'contratos fechados',
                  icon: Icons.payments_rounded,
                  color: FornecedorPremiumPalette.emerald,
                ),
                PremiumMetricTile(
                  label: 'Estimado aberto',
                  value: _money(estimado),
                  subtitle: 'cotações em andamento',
                  icon: Icons.trending_up_rounded,
                  color: FornecedorPremiumPalette.sky,
                ),
                PremiumMetricTile(
                  label: 'Faturamento do mês',
                  value: _money(faturamentoMes),
                  subtitle: DateFormat('MMMM', 'pt_BR').format(agora),
                  icon: Icons.calendar_month_rounded,
                  color: FornecedorPremiumPalette.dark,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GraficoComCabecalho(
                tipoVisualizacao: _tipoVisualizacao, controller: orcamentoController),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 820;
                final contratos = _ContratosRecentes(contratos: topContratos);
                final categorias = _CategoriasReceita(categorias: resumoCategorias);

                if (!twoColumns) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [contratos, const SizedBox(height: 12), categorias],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: contratos),
                    const SizedBox(width: 12),
                    Expanded(flex: 5, child: categorias),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }

  static String _money(double valor) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2).format(valor);

  static List<Map<String, dynamic>> _gerarHistoricoSemanal(OrcamentoController controller) {
    final agora = DateTime.now();
    final orcs = controller.orcamentos
        .where((o) =>
            o.status == StatusOrcamento.fechado &&
            o.dataFechamento != null &&
            o.dataFechamento!.month == agora.month &&
            o.dataFechamento!.year == agora.year)
        .toList();
    final agrupado = <int, double>{};
    for (final o in orcs) {
      final semana = _semanaDoMes(o.dataFechamento!);
      agrupado[semana] = (agrupado[semana] ?? 0) + (o.custoEstimado ?? 0);
    }
    return List.generate(5, (i) => {'semana': i + 1, 'valor': agrupado[i + 1] ?? 0.0});
  }

  static List<Map<String, dynamic>> _gerarHistoricoMensal(OrcamentoController controller) {
    final orcs = controller.orcamentos
        .where((o) => o.status == StatusOrcamento.fechado && o.dataFechamento != null)
        .toList();
    final agrupado = <int, double>{};
    for (final o in orcs) {
      final mes = o.dataFechamento!.month;
      agrupado[mes] = (agrupado[mes] ?? 0) + (o.custoEstimado ?? 0);
    }
    return List.generate(
      12,
      (i) => {
        'mes': DateFormat('MMM', 'pt_BR').format(DateTime(0, i + 1)),
        'valor': agrupado[i + 1] ?? 0.0,
      },
    );
  }

  static int _semanaDoMes(DateTime date) {
    final primeiroDia = DateTime(date.year, date.month, 1);
    return ((date.day + primeiroDia.weekday - 1) / 7).ceil();
  }

  static List<OrcamentoModel> _pegarContratosRecentes(List<OrcamentoModel> orcs) {
    final fechados = orcs
        .where((o) => o.status == StatusOrcamento.fechado && o.dataFechamento != null)
        .toList()
      ..sort((a, b) => b.dataFechamento!.compareTo(a.dataFechamento!));
    return fechados.take(4).toList();
  }

  static Map<String, double> _agruparPorCategoria(List<OrcamentoModel> orcs) {
    final mapa = <String, double>{};
    for (final o in orcs.where((o) => o.status == StatusOrcamento.fechado)) {
      final categoria = o.idCategoria ?? 'Outros';
      mapa[categoria] = (mapa[categoria] ?? 0) + (o.custoEstimado ?? 0);
    }
    return mapa;
  }
}

class _GraficoComCabecalho extends StatelessWidget {
  final Rx<TipoVisualizacao> tipoVisualizacao;
  final OrcamentoController controller;

  const _GraficoComCabecalho({required this.tipoVisualizacao, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dados = tipoVisualizacao.value == TipoVisualizacao.semana
          ? FinanceiroSection._gerarHistoricoSemanal(controller)
          : FinanceiroSection._gerarHistoricoMensal(controller);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FornecedorPremiumPalette.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FornecedorPremiumPalette.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                final title = Text(
                  'Evolução de receita',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: FornecedorPremiumPalette.text,
                  ),
                );
                final dropdown = Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: FornecedorPremiumPalette.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<TipoVisualizacao>(
                    value: tipoVisualizacao.value,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.expand_more_rounded,
                        color: FornecedorPremiumPalette.muted, size: 18),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: FornecedorPremiumPalette.text,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (v) {
                      if (v != null) tipoVisualizacao.value = v;
                    },
                    items: const [
                      DropdownMenuItem(value: TipoVisualizacao.semana, child: Text('Semanal')),
                      DropdownMenuItem(value: TipoVisualizacao.mes, child: Text('Mensal')),
                    ],
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 10), dropdown],
                  );
                }

                return Row(children: [Expanded(child: title), const SizedBox(width: 12), dropdown]);
              },
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _GraficoHistorico(
                key: ValueKey(tipoVisualizacao.value),
                dados: dados,
                tipo: tipoVisualizacao.value,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _GraficoHistorico extends StatelessWidget {
  final List<Map<String, dynamic>> dados;
  final TipoVisualizacao tipo;

  const _GraficoHistorico({super.key, required this.dados, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final valores = dados.map((e) => (e['valor'] as num).toDouble()).toList();
    final temValor = valores.any((v) => v > 0);

    if (!temValor) {
      return const SizedBox(
        height: 188,
        child: PremiumEmptyState(
          icon: Icons.query_stats_rounded,
          title: 'Sem faturamento no período',
          message: 'Quando contratos forem fechados, a evolução financeira aparecerá aqui.',
          color: FornecedorPremiumPalette.primary,
        ),
      );
    }

    final maxValor = valores.reduce((a, b) => a > b ? a : b);
    final topY = (maxValor * 1.2).clamp(100, double.infinity).toDouble();
    final spots = valores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: topY,
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: topY / 4,
            getDrawingHorizontalLine: (value) =>
                const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= dados.length) return const SizedBox.shrink();
                  final label = tipo == TipoVisualizacao.semana
                      ? '${dados[idx]['semana']}ª S'
                      : dados[idx]['mes'].toString().substring(0, 3).toUpperCase();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                          fontSize: 10.5, color: FornecedorPremiumPalette.muted),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: topY / 4,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                  'R\$${v.toInt()}',
                  style:
                      GoogleFonts.poppins(fontSize: 9.5, color: FornecedorPremiumPalette.softMuted),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: FornecedorPremiumPalette.dark,
              barWidth: 2.6,
              belowBarData: BarAreaData(
                show: true,
                color: FornecedorPremiumPalette.dark.withValues(alpha: 0.06),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: FornecedorPremiumPalette.dark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContratosRecentes extends StatelessWidget {
  final List<OrcamentoModel> contratos;

  const _ContratosRecentes({required this.contratos});

  @override
  Widget build(BuildContext context) {
    if (contratos.isEmpty) {
      return const PremiumEmptyState(
        icon: Icons.handshake_outlined,
        title: 'Nenhum contrato recente',
        message: 'Os contratos fechados aparecerão aqui em ordem de conclusão.',
        color: FornecedorPremiumPalette.emerald,
      );
    }

    return _MiniPanel(
      title: 'Últimos contratos',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: contratos.map((o) {
          final valor = o.custoEstimado ?? 0;
          final data =
              o.dataFechamento != null ? DateFormat('dd/MM/yyyy').format(o.dataFechamento!) : '-';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FornecedorPremiumPalette.emerald.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      size: 17, color: FornecedorPremiumPalette.emerald),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        o.idCategoria ?? 'Categoria não informada',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: FornecedorPremiumPalette.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(data,
                          style: GoogleFonts.poppins(
                              fontSize: 10.8, color: FornecedorPremiumPalette.muted)),
                    ],
                  ),
                ),
                Text(
                  FinanceiroSection._money(valor),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: FornecedorPremiumPalette.emerald,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoriasReceita extends StatelessWidget {
  final Map<String, double> categorias;

  const _CategoriasReceita({required this.categorias});

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return const PremiumEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        title: 'Sem receita categorizada',
        message: 'Ao fechar contratos, a distribuição por categoria será exibida aqui.',
        color: FornecedorPremiumPalette.primary,
      );
    }

    final total = categorias.values.fold(0.0, (soma, v) => soma + v);

    return _MiniPanel(
      title: 'Receita por categoria',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: categorias.entries.map((e) {
          final percentual = total == 0 ? 0.0 : (e.value / total).clamp(0.0, 1.0).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.8,
                          color: FornecedorPremiumPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${(percentual * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: FornecedorPremiumPalette.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: percentual,
                    minHeight: 7,
                    color: FornecedorPremiumPalette.dark,
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _MiniPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FornecedorPremiumPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: FornecedorPremiumPalette.text,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
