import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/convidado_controller.dart';
import './../../../../data/models/model.dart';

class EstatisticasTab extends StatefulWidget {
  const EstatisticasTab({super.key});

  @override
  State<EstatisticasTab> createState() => _EstatisticasTabState();
}

class _EstatisticasTabState extends State<EstatisticasTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _loaded = false;

  final controller = Get.find<ConvidadoController>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.totalConvidados;
      final confirmados = controller.totalConfirmados;
      final pendentes = controller.totalPendentes;
      final recusados = controller.totalRecusados;

      final totalAdultos = controller.totalAdultos;
      final totalCriancas = controller.totalCriancas;
      final totalBebes = (controller.convidados
              .where((c) => (c.adulto == false && c.status == StatusConvidado.confirmado))
              .length ~/
          3); // regra opcional: 1/3 das crianças são bebês (ajuste se quiser)

      final percentConfirmados = total > 0 ? confirmados / total : 0.0;
      final percentPendentes = total > 0 ? pendentes / total : 0.0;

      return AnimatedOpacity(
        opacity: _loaded ? 1 : 0,
        duration: const Duration(milliseconds: 800),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Text(
                '📊 Estatísticas do Evento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 30),

            /// === Gráfico de distribuição por faixa etária ===
            AnimatedScale(
              scale: _loaded ? 1 : 0.7,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 55,
                          startDegreeOffset: -90,
                          sections: _pieSections(
                            totalAdultos,
                            totalCriancas,
                            totalBebes,
                          ),
                        ),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Distribuição de convidados por faixa etária',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            /// === Cards de Faixa Etária ===
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricCard(Icons.person, 'Adultos', totalAdultos, Colors.teal),
                _metricCard(Icons.child_care, 'Crianças', totalCriancas, Colors.amber),
                _metricCard(Icons.baby_changing_station, 'Bebês', totalBebes, Colors.deepPurple),
              ],
            ),

            const SizedBox(height: 32),

            /// === Barras de Progresso ===
            _progressCard(
              title: "Confirmados",
              value: percentConfirmados,
              color: Colors.teal,
              subtitle: "$confirmados de $total convidados confirmaram presença",
            ),
            const SizedBox(height: 16),
            _progressCard(
              title: "Pendentes",
              value: percentPendentes,
              color: Colors.orangeAccent,
              subtitle: "$pendentes convidados ainda não responderam",
            ),
            const SizedBox(height: 16),
            _progressCard(
              title: "Recusados",
              value: total > 0 ? recusados / total : 0.0,
              color: Colors.redAccent,
              subtitle: "$recusados convidados recusaram o convite",
            ),

            const SizedBox(height: 40),
            const Center(
              child: Text(
                "📅 Estatísticas atualizadas automaticamente conforme as confirmações.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      );
    });
  }

  /// === Gráfico de Pizza (distribuição por faixa etária) ===
  List<PieChartSectionData> _pieSections(
    int adultos,
    int criancas,
    int bebes,
  ) {
    final total = (adultos + criancas + bebes).toDouble();
    if (total == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 1,
          title: '0%',
          radius: 60,
          titleStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ];
    }
    return [
      _section("Adultos", adultos / total, Colors.teal),
      _section("Crianças", criancas / total, Colors.amber),
      _section("Bebês", bebes / total, Colors.deepPurple),
    ];
  }

  PieChartSectionData _section(String label, double percent, Color color) {
    return PieChartSectionData(
      color: color,
      value: percent,
      radius: 65,
      title: "${(percent * 100).toStringAsFixed(0)}%",
      titleStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      badgeWidget: _badge(label, color),
      badgePositionPercentageOffset: 1.3,
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// === Card de métrica ===
  Widget _metricCard(IconData icon, String label, int value, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth / 2) - 28;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: cardWidth,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            "$value",
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// === Card com barra de progresso ===
  Widget _progressCard({
    required String title,
    required double value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              color: color,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
