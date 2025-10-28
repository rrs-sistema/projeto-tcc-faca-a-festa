import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/contacao/cotacao_controller.dart';
import '../../../../controllers/orcamento_controller.dart';
import '../../../../data/models/model.dart';

enum TipoVisualizacao { semana, mes }

class FinanceiroSection extends StatelessWidget {
  const FinanceiroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final orcamentoController = Get.find<OrcamentoController>();
    final cotacaoController = Get.find<CotacaoController>();
    final Rx<TipoVisualizacao> tipoVisualizacao = TipoVisualizacao.semana.obs;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final orcamentos = orcamentoController.orcamentos;
        final cotacoes = cotacaoController.cotacoes;

        // === INDICADORES ===
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "💼 Financeiro do Fornecedor",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),

            // === INDICADORES ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _indicador("Recebido", recebido, Colors.green, Icons.check_circle_rounded),
                _indicador("Estimativa", estimado, Colors.teal, Icons.timeline_rounded),
                _indicador(
                    "Faturamento Mês", faturamentoMes, Colors.blue, Icons.show_chart_rounded),
              ],
            ),

            const SizedBox(height: 32),

            // === GRÁFICO ===
            _graficoComCabecalho(tipoVisualizacao, orcamentoController),

            const SizedBox(height: 40),

            // === CONTRATOS ===
            Text(
              "📋 Últimos Contratos Fechados",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            _tabelaContratos(topContratos),

            const SizedBox(height: 32),

            // === CATEGORIAS ===
            Text(
              "📈 Faturamento por Categoria",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            _listaCategorias(resumoCategorias),

            const SizedBox(height: 24),

            // === BOTÃO PDF ===
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Get.snackbar(
                  "Relatório Financeiro",
                  "Exportando relatório completo...",
                  backgroundColor: Colors.teal.shade700,
                  colorText: Colors.white,
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: Text(
                  "Exportar relatório em PDF",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // === CABEÇALHO + GRÁFICO ===
  Widget _graficoComCabecalho(
      Rx<TipoVisualizacao> tipoVisualizacao, OrcamentoController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stacked_line_chart_rounded, color: Colors.teal.shade600),
                  const SizedBox(width: 8),
                  Text(
                    tipoVisualizacao.value == TipoVisualizacao.semana
                        ? "Faturamento Semanal"
                        : "Faturamento Mensal",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              DropdownButton<TipoVisualizacao>(
                value: tipoVisualizacao.value,
                underline: const SizedBox(),
                icon: const Icon(Icons.expand_more_rounded, color: Colors.teal),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                onChanged: (v) => tipoVisualizacao.value = v!,
                items: const [
                  DropdownMenuItem(value: TipoVisualizacao.semana, child: Text('Semanal')),
                  DropdownMenuItem(value: TipoVisualizacao.mes, child: Text('Mensal')),
                ],
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _graficoHistorico(
            tipoVisualizacao.value == TipoVisualizacao.semana
                ? _gerarHistoricoSemanal(controller)
                : _gerarHistoricoMensal(controller),
            tipoVisualizacao.value,
            key: ValueKey(tipoVisualizacao.value),
          ),
        ),
      ],
    );
  }

  // === GRÁFICO ===
  Widget _graficoHistorico(List<Map<String, dynamic>> dados, TipoVisualizacao tipo, {Key? key}) {
    if (dados.isEmpty) {
      return Container(
        key: key,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_chart_outlined_rounded, size: 42, color: Colors.teal.shade300),
              const SizedBox(height: 8),
              Text(
                "Sem dados de faturamento",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final valores = dados.map((e) => (e['valor'] as num).toDouble()).toList();
    final maxValor = valores.reduce((a, b) => a > b ? a : b);
    final topY = (maxValor * 1.2).clamp(300, double.infinity);
    final spots = valores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Container(
      key: key,
      height: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: topY.toDouble(),
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: topY / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
                      ? '${dados[idx]['semana']}º Semana'
                      : dados[idx]['mes'].toString().substring(0, 3).toUpperCase();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label,
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: topY / 4,
                reservedSize: 46,
                getTitlesWidget: (v, _) => Text(
                  'R\$${v.toInt()}',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade800],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade200.withValues(alpha: 0.4),
                    Colors.teal.shade50.withValues(alpha: 0.05)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4.5,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: Colors.teal.shade600,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.all(10),
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.x.toInt();
                final label = tipo == TipoVisualizacao.semana
                    ? '${dados[idx]['semana']}º Semana'
                    : dados[idx]['mes'];
                final valor = s.y.toStringAsFixed(2);
                return LineTooltipItem(
                  "$label\nR\$ $valor",
                  GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
      ),
    );
  }

  // === INDICADOR ===
  Widget _indicador(String titulo, double valor, Color cor, IconData icone) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cor.withValues(alpha: 0.6), cor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icone, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          "R\$ ${valor.toStringAsFixed(2)}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: cor,
            fontSize: 15,
          ),
        ),
        Text(
          titulo,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

// === TABELA CONTRATOS (versão full width e elegante) ===
  Widget _tabelaContratos(List<OrcamentoModel> contratos) {
    if (contratos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 40, color: Colors.teal.shade300),
            const SizedBox(height: 8),
            Text(
              "Nenhum contrato fechado ainda.",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity, // 🔹 ocupa toda a largura
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === CABEÇALHO COM GRADIENTE ===
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade400, Colors.teal.shade700],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.shade100.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  "Últimos Contratos",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // === TABELA ===
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // 🔹 garante rolagem horizontal se necessário
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 600), // 🔹 largura mínima bonita
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DataTable(
                    headingTextStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade800,
                    ),
                    dataTextStyle: GoogleFonts.poppins(fontSize: 13),
                    headingRowColor: WidgetStateProperty.all(
                      Colors.teal.shade50.withValues(alpha: 0.4),
                    ),
                    dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.teal.shade50.withValues(alpha: 0.5);
                        }
                        return null;
                      },
                    ),
                    columnSpacing: 22,
                    horizontalMargin: 16,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.6,
                      ),
                    ),
                    columns: [
                      DataColumn(
                        label: Row(
                          children: [
                            const Icon(Icons.category_outlined, size: 18, color: Colors.teal),
                            const SizedBox(width: 6),
                            const Text("Categoria"),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            const Icon(Icons.monetization_on_outlined,
                                size: 18, color: Colors.teal),
                            const SizedBox(width: 6),
                            const Text("Valor"),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Row(
                          children: [
                            const Icon(Icons.event_outlined, size: 18, color: Colors.teal),
                            const SizedBox(width: 6),
                            const Text("Data"),
                          ],
                        ),
                      ),
                    ],
                    rows: contratos.asMap().entries.map((entry) {
                      final i = entry.key;
                      final o = entry.value;
                      final corLinha = i.isEven ? Colors.grey.shade50 : Colors.white;
                      final valor = o.custoEstimado ?? 0;
                      return DataRow(
                        color: WidgetStateProperty.all(corLinha),
                        cells: [
                          DataCell(Row(
                            children: [
                              const Icon(Icons.label_outline_rounded, color: Colors.grey, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  o.idCategoria ?? "-",
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          )),
                          DataCell(Row(
                            children: [
                              Icon(
                                valor > 0 ? Icons.arrow_upward_rounded : Icons.remove_rounded,
                                color: valor > 0 ? Colors.green.shade600 : Colors.grey.shade500,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "R\$ ${valor.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  color: valor > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )),
                          DataCell(Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: Colors.grey, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                o.dataFechamento != null
                                    ? DateFormat('dd/MM/yyyy').format(o.dataFechamento!)
                                    : "-",
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === LISTA CATEGORIAS ===
  Widget _listaCategorias(Map<String, double> categorias) {
    if (categorias.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text("Sem dados de faturamento por categoria.",
            style: GoogleFonts.poppins(color: Colors.grey.shade500)),
      );
    }

    return Column(
      children: categorias.entries.map((e) {
        final total = categorias.values.fold(0.0, (soma, v) => soma + v);
        final percentual = total == 0 ? 0 : (e.value / total) * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: percentual / 100,
                  color: Colors.teal,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${e.key} (${percentual.toStringAsFixed(1)}%)",
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // === AUXILIARES ===
  List<Map<String, dynamic>> _gerarHistoricoSemanal(OrcamentoController controller) {
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

    return List.generate(5, (i) {
      final idx = i + 1;
      return {'semana': idx, 'valor': agrupado[idx] ?? 0.0};
    });
  }

  List<Map<String, dynamic>> _gerarHistoricoMensal(OrcamentoController controller) {
    final orcs = controller.orcamentos
        .where((o) => o.status == StatusOrcamento.fechado && o.dataFechamento != null)
        .toList();

    final agrupado = <int, double>{};
    for (final o in orcs) {
      final mes = o.dataFechamento!.month;
      agrupado[mes] = (agrupado[mes] ?? 0) + (o.custoEstimado ?? 0);
    }

    return List.generate(12, (i) {
      final mes = i + 1;
      final nomeMes = DateFormat('MMM', 'pt_BR').format(DateTime(0, mes));
      return {'mes': nomeMes, 'valor': agrupado[mes] ?? 0.0};
    });
  }

  int _semanaDoMes(DateTime date) {
    final primeiroDia = DateTime(date.year, date.month, 1);
    return ((date.day + primeiroDia.weekday - 1) / 7).ceil();
  }

  List<OrcamentoModel> _pegarContratosRecentes(List<OrcamentoModel> orcs) {
    final fechados = orcs.where((o) => o.status == StatusOrcamento.fechado).toList()
      ..sort((a, b) => b.dataFechamento!.compareTo(a.dataFechamento!));
    return fechados.take(5).toList();
  }

  Map<String, double> _agruparPorCategoria(List<OrcamentoModel> orcs) {
    final mapa = <String, double>{};
    for (var o in orcs.where((o) => o.status == StatusOrcamento.fechado)) {
      mapa[o.idCategoria ?? "Outros"] =
          (mapa[o.idCategoria ?? "Outros"] ?? 0) + (o.custoEstimado ?? 0);
    }
    return mapa;
  }
}
