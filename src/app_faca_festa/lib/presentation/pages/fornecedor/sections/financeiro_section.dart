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

  static final Rx<TipoVisualizacao> _tipoVisualizacao = TipoVisualizacao.semana.obs;

  @override
  Widget build(BuildContext context) {
    final orcamentoController = Get.find<OrcamentoController>();
    final cotacaoController = Get.find<CotacaoController>();
    final tipoVisualizacao = _tipoVisualizacao;

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

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 CABEÇALHO RESPONSIVO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.monetization_on_outlined,
                            size: 20, color: Colors.grey.shade800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Relatório Financeiro",
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade900),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Get.snackbar("Relatório", "Gerando documento em PDF...",
                      backgroundColor: Colors.grey.shade900, colorText: Colors.white),
                  icon: Icon(Icons.download_rounded, size: 16, color: Colors.grey.shade700),
                  label: Text("Exportar PDF",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey.shade800)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 🔹 INDICADORES FLEXÍVEIS (Wrap impede quebras no mobile)
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _indicador("Recebido (Fechado)", recebido, Colors.green.shade700),
                _indicador("Estimado (Aberto)", estimado, Colors.blue.shade700),
                _indicador("Faturamento do Mês", faturamentoMes, Colors.grey.shade900),
              ],
            ),

            const Divider(height: 48, color: Color(0xFFEEEEEE)),
            _graficoComCabecalho(tipoVisualizacao, orcamentoController),
            const Divider(height: 48, color: Color(0xFFEEEEEE)),

            Text("Últimos Contratos Firmados",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800)),
            const SizedBox(height: 16),
            _tabelaContratos(topContratos),

            const SizedBox(height: 32),
            Text("Distribuição de Receita por Categoria",
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800)),
            const SizedBox(height: 16),
            _listaCategorias(resumoCategorias),
          ],
        ),
      );
    });
  }

  Widget _indicador(String titulo, double valor, Color cor) {
    return SizedBox(
      width: 140, // Largura base para o Wrap distribuir bem na tela
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: GoogleFonts.poppins(
                  color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor),
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: cor, fontSize: 16, letterSpacing: -0.5),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _graficoComCabecalho(
      Rx<TipoVisualizacao> tipoVisualizacao, OrcamentoController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text("Evolução Mensal",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800)),
            ),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6)),
              child: DropdownButton<TipoVisualizacao>(
                value: tipoVisualizacao.value,
                underline: const SizedBox(),
                icon: Icon(Icons.expand_more_rounded, color: Colors.grey.shade600, size: 18),
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                onChanged: (v) => tipoVisualizacao.value = v!,
                items: const [
                  DropdownMenuItem(value: TipoVisualizacao.semana, child: Text('Semanal')),
                  DropdownMenuItem(value: TipoVisualizacao.mes, child: Text('Mensal')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
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

  Widget _graficoHistorico(List<Map<String, dynamic>> dados, TipoVisualizacao tipo, {Key? key}) {
    if (dados.isEmpty) {
      return Container(
        key: key,
        height: 200,
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200)),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 32, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text("Sem dados de faturamento para o período",
                style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }
    final valores = dados.map((e) => (e['valor'] as num).toDouble()).toList();
    final maxValor = valores.reduce((a, b) => a > b ? a : b);
    final topY = (maxValor * 1.2).clamp(100, double.infinity);
    final spots = valores.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Container(
      key: key,
      height: 200,
      padding: const EdgeInsets.only(right: 16),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: topY.toDouble(),
          gridData: FlGridData(
            drawHorizontalLine: true,
            horizontalInterval: topY / 4,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= dados.length) return const SizedBox.shrink();
                  final label = tipo == TipoVisualizacao.semana
                      ? '${dados[idx]['semana']}ª S'
                      : dados[idx]['mes'].toString().substring(0, 3).toUpperCase();
                  return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(label,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500)));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: topY / 4,
                reservedSize: 44,
                getTitlesWidget: (v, _) => Text('R\$${v.toInt()}',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade400)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.grey.shade900,
              barWidth: 2.5,
              belowBarData:
                  BarAreaData(show: true, color: Colors.grey.shade900.withValues(alpha: 0.05)),
              dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                      radius: 3.5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: Colors.grey.shade900)),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 DATATABLE PROTEGIDA CONTRA OVERFLOW (Scroll Horizontal)
  Widget _tabelaContratos(List<OrcamentoModel> contratos) {
    if (contratos.isEmpty) {
      return Text("Nenhum contrato fechado recentemente.",
          style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13));
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 40,
            dataRowMaxHeight: 48,
            horizontalMargin: 16,
            columnSpacing: 32,
            headingTextStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 12),
            dataTextStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade900),
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
            columns: const [
              DataColumn(label: Text("Categoria do Serviço")),
              DataColumn(label: Text("Valor Negociado")),
              DataColumn(label: Text("Data Efetiva"))
            ],
            rows: contratos.map((o) {
              final valor = o.custoEstimado ?? 0;
              return DataRow(cells: [
                DataCell(Text(o.idCategoria ?? "-", overflow: TextOverflow.ellipsis)),
                DataCell(Text("R\$ ${valor.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                DataCell(Text(
                    o.dataFechamento != null
                        ? DateFormat('dd/MM/yyyy').format(o.dataFechamento!)
                        : "-",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600))),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _listaCategorias(Map<String, double> categorias) {
    if (categorias.isEmpty) {
      return Text("Não há faturamento categorizado.",
          style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13));
    }
    return Column(
      children: categorias.entries.map((e) {
        final total = categorias.values.fold(0.0, (soma, v) => soma + v);
        final percentual = total == 0 ? 0 : (e.value / total) * 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text(e.key,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: percentual / 100,
                          color: Colors.grey.shade900,
                          backgroundColor: Colors.grey.shade100,
                          minHeight: 6),
                    )),
                    const SizedBox(width: 12),
                    Text("${percentual.toStringAsFixed(1)}%",
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Métodos auxiliares
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
    return List.generate(5, (i) => {'semana': i + 1, 'valor': agrupado[i + 1] ?? 0.0});
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
    return List.generate(
        12,
        (i) => {
              'mes': DateFormat('MMM', 'pt_BR').format(DateTime(0, i + 1)),
              'valor': agrupado[i + 1] ?? 0.0
            });
  }

  int _semanaDoMes(DateTime date) {
    final primeiroDia = DateTime(date.year, date.month, 1);
    return ((date.day + primeiroDia.weekday - 1) / 7).ceil();
  }

  List<OrcamentoModel> _pegarContratosRecentes(List<OrcamentoModel> orcs) {
    final fechados = orcs
        .where((o) => o.status == StatusOrcamento.fechado && o.dataFechamento != null)
        .toList()
      ..sort((a, b) => b.dataFechamento!.compareTo(a.dataFechamento!));
    return fechados.take(4).toList();
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
