import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/fornecedor_controller.dart';

class FinanceiroSection extends StatelessWidget {
  const FinanceiroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    // 🔹 Mock de valores financeiros (futuro: Firestore)
    final List<Map<String, dynamic>> valores = [
      {'mes': 'Jun', 'valor': 1800.0},
      {'mes': 'Jul', 'valor': 2300.0},
      {'mes': 'Ago', 'valor': 2500.0},
      {'mes': 'Set', 'valor': 2100.0},
      {'mes': 'Out', 'valor': 2800.0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "💰 Financeiro",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() {
          final faturamento = controller.faturamentoMes.value;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 🔹 Indicadores principais
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _indicadorFinanceiro(
                      titulo: "Recebido",
                      valor: 2350.00,
                      cor: Colors.green.shade700,
                      icone: Icons.attach_money_rounded,
                    ),
                    _indicadorFinanceiro(
                      titulo: "Pendente",
                      valor: 450.00,
                      cor: Colors.orange.shade700,
                      icone: Icons.timelapse_rounded,
                    ),
                    _indicadorFinanceiro(
                      titulo: "Faturamento Mês",
                      valor: faturamento,
                      cor: Colors.teal.shade700,
                      icone: Icons.show_chart_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 🔹 Gráfico de faturamento
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        drawHorizontalLine: true,
                        horizontalInterval: 500,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade300,
                          strokeWidth: 0.8,
                        ),
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 500,
                            reservedSize: 40,
                            getTitlesWidget: (v, _) => Text(
                              'R\$${v.toInt()}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              int index = v.toInt();
                              if (index >= 0 && index < valores.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    valores[index]['mes']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            reservedSize: 24,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: Colors.teal.shade700,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal.shade100,
                                Colors.teal.shade50,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          spots: valores
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(), e.value['valor']!))
                              .toList(),
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.snackbar(
                      "Financeiro",
                      "Abrindo relatório completo...",
                      backgroundColor: Colors.teal.shade700,
                      colorText: Colors.white,
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                    label: Text(
                      "Ver relatório completo",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _indicadorFinanceiro({
    required String titulo,
    required double valor,
    required Color cor,
    required IconData icone,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icone, color: cor, size: 22),
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
}
