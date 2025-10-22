import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/convidado/convidado_controller.dart';
import '../../../../core/utils/biblioteca.dart';
import '../../../../data/models/model.dart';

class MesasTab extends StatelessWidget {
  const MesasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ConvidadoController>();

    return Obx(() {
      final grupos = controller.convidadosPorMesa;
      final estat = controller.estatisticasMesas;

      if (controller.carregando.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (grupos.isEmpty) {
        return const Center(
          child: Text(
            'Nenhuma mesa cadastrada ainda.',
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        );
      }

      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFF9F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "🍷 Disposição das Mesas",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Mesas dinâmicas -- Amigos da Faculdade
            ...grupos.entries.map((entry) {
              final nome = entry.key;
              final convidados = entry.value;
              final confirmados =
                  convidados.where((c) => c.status == StatusConvidado.confirmado).length;
              final convidadoModel = convidados.where((c) => c.grupoMesa!.contains(nome)).first;

              final dataHora = DateTime.timestamp().millisecondsSinceEpoch;

              final nomeAlterado = ('${convidadoModel.nome}-$dataHora${convidadoModel.grupoMesa!}');

              //final color = Colors.primaries[nome.hashCode % Colors.primaries.length];
              final color = Biblioteca.gerarCorPorChaves(
                  [nomeAlterado, convidadoModel.status.label, convidadoModel.contato]);

              return _MesaCard(
                nome: nome,
                assentos: convidados.length,
                ocupados: confirmados,
                color: color,
                icon: Icons.chair,
                convidados: convidados
                    .map((c) => _ConvidadoItem(
                          nome: c.nome,
                          confirmado: c.status == StatusConvidado.confirmado,
                        ))
                    .toList(),
              );
            }),

            const SizedBox(height: 24),
            _ResumoMesas(estat: estat),
            const SizedBox(height: 32),
            _GraficoMesas(estat: estat),
            const SizedBox(height: 110),
          ],
        ),
      );
    });
  }
}

class _ResumoMesas extends StatelessWidget {
  final Map<String, dynamic> estat;
  const _ResumoMesas({required this.estat});

  @override
  Widget build(BuildContext context) {
    final resumo = [
      {"label": "Mesas totais", "value": estat['totalMesas'], "color": Colors.teal},
      {"label": "Assentos totais", "value": estat['assentos'], "color": Colors.orange},
      {"label": "Ocupados", "value": estat['ocupados'], "color": Colors.pinkAccent},
      {"label": "Livres", "value": estat['livres'], "color": Colors.blueAccent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            "📊 Resumo geral das mesas",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: resumo
              .map((r) => _metricCard(
                    context,
                    r["label"] as String,
                    r["value"].toString(),
                    r["color"] as Color,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _metricCard(BuildContext context, String label, String value, Color color) {
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
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
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
}

/// === CARD de Mesa ===
class _MesaCard extends StatelessWidget {
  final String nome;
  final int assentos;
  final int ocupados;
  final IconData icon;
  final Color color;
  final List<Widget> convidados;
  const _MesaCard({
    required this.nome,
    required this.assentos,
    required this.ocupados,
    required this.icon,
    required this.color,
    required this.convidados,
  });
  @override
  Widget build(BuildContext context) {
    final livres = assentos - ocupados;
    final ocupacao = (ocupados / assentos).clamp(0, 1);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ExpansionTile(
        backgroundColor: Colors.white,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(
          nome,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              "$livres assentos livres",
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: ocupacao.toDouble(),
                color: color,
                backgroundColor: Colors.grey.shade200,
                minHeight: 5,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: convidados,
      ),
    );
  }
}

/// === ITEM Convidado ===
class _ConvidadoItem extends StatelessWidget {
  final String nome;
  final bool confirmado;
  const _ConvidadoItem({required this.nome, required this.confirmado});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        confirmado ? Icons.event_available : Icons.event_busy,
        color: confirmado ? Colors.teal : Colors.redAccent,
      ),
      title: Text(
        nome,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: confirmado ? Colors.black87 : Colors.black54,
        ),
      ),
      trailing: confirmado
          ? const Icon(Icons.check_circle, color: Colors.teal, size: 18)
          : const Icon(Icons.hourglass_empty, color: Colors.redAccent, size: 18),
    );
  }
}

/// === GRÁFICO das MESAS (Dinâmico) ===
class _GraficoMesas extends StatelessWidget {
  final Map<String, dynamic> estat;
  const _GraficoMesas({required this.estat});

  @override
  Widget build(BuildContext context) {
    final totalAssentos = (estat['assentos'] ?? 0).toDouble();
    final totalOcupados = (estat['ocupados'] ?? 0).toDouble();
    final totalLivres = (estat['livres'] ?? 0).toDouble();

    if (totalAssentos == 0) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Ainda não há dados suficientes para gerar o gráfico.',
            style: TextStyle(color: Colors.black54, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final ocupadosPercent = totalOcupados / totalAssentos;
    final livresPercent = totalLivres / totalAssentos;

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "🪑 Distribuição dos Assentos",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 240,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 55,
              sections: [
                _pieSection("Ocupados", ocupadosPercent, Colors.teal),
                _pieSection("Livres", livresPercent, Colors.orangeAccent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _graficoLegenda("Ocupados (${totalOcupados.toInt()})", Colors.teal),
        _graficoLegenda("Livres (${totalLivres.toInt()})", Colors.orangeAccent),
      ],
    );
  }

  PieChartSectionData _pieSection(String label, double percent, Color color) {
    return PieChartSectionData(
      color: color,
      value: percent,
      title: "${(percent * 100).toStringAsFixed(0)}%",
      radius: 70,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _graficoLegenda(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
