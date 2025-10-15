import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EstatisticasTab extends StatefulWidget {
  const EstatisticasTab({super.key});

  @override
  State<EstatisticasTab> createState() => _EstatisticasTabState();
}

class _EstatisticasTabState extends State<EstatisticasTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _loaded = false;

  final int total = 42;
  final int homens = 18;
  final int mulheres = 14;
  final int criancas = 8;
  final int bebes = 2;

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
    final percentConfirmados = 0.76;
    final percentPendentes = 0.24;

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

          /// === Gráfico de Pizza ===
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
                        sections: _pieSections(),
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Distribuição de convidados',
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

          /// === Cards de Gênero e Idade ===
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricCard(Icons.male, 'Homens', homens, Colors.teal),
              _metricCard(Icons.female, 'Mulheres', mulheres, Colors.pinkAccent),
              _metricCard(Icons.child_care, 'Crianças', criancas, Colors.amber),
              _metricCard(Icons.baby_changing_station, 'Bebês', bebes, Colors.deepPurple),
            ],
          ),

          const SizedBox(height: 32),

          /// === Barra de progresso: Confirmações ===
          _progressCard(
            title: "Confirmados",
            value: percentConfirmados,
            color: Colors.teal,
            subtitle: "32 convidados confirmaram presença",
          ),
          const SizedBox(height: 16),
          _progressCard(
            title: "Pendentes",
            value: percentPendentes,
            color: Colors.orangeAccent,
            subtitle: "10 convidados ainda não responderam",
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
  }

  /// === Seções do gráfico ===
  List<PieChartSectionData> _pieSections() {
    final totalDouble = total.toDouble();
    return [
      _section("Homens", homens / totalDouble, Colors.teal),
      _section("Mulheres", mulheres / totalDouble, Colors.pinkAccent),
      _section("Crianças", criancas / totalDouble, Colors.amber),
      _section("Bebês", bebes / totalDouble, Colors.deepPurple),
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

    // Define largura dinâmica: 2 por linha, com espaçamento proporcional
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
