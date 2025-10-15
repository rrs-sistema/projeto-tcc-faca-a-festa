import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// --- Aba: Mesas ---
class MesasTab extends StatelessWidget {
  const MesasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final mesas = [
      {
        "nome": "Principal",
        "assentos": 8,
        "ocupados": 4,
        "color": Colors.teal,
        "icon": Icons.event_seat,
        "convidados": [
          {"nome": "Meu amor", "confirmado": true},
          {"nome": "RRS Sistemas", "confirmado": true},
          {"nome": "Murillo", "confirmado": false},
          {"nome": "Jezreel", "confirmado": false},
        ],
      },
      {
        "nome": "Família",
        "assentos": 6,
        "ocupados": 3,
        "color": Colors.orangeAccent,
        "icon": Icons.chair_alt_rounded,
        "convidados": [
          {"nome": "RRS Pai", "confirmado": true},
          {"nome": "RRS Mãe", "confirmado": false},
          {"nome": "RRS Filho", "confirmado": false},
        ],
      },
      {
        "nome": "Amigos",
        "assentos": 10,
        "ocupados": 6,
        "color": Colors.pinkAccent,
        "icon": Icons.table_bar_rounded,
        "convidados": [
          {"nome": "Amanda", "confirmado": true},
          {"nome": "Lucas", "confirmado": true},
          {"nome": "Jullia", "confirmado": true},
          {"nome": "Carlos", "confirmado": true},
          {"nome": "Marta", "confirmado": false},
          {"nome": "Thiago", "confirmado": false},
        ],
      },
    ];

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

          // Cards das mesas
          ...mesas.map((m) => _MesaCard(
                nome: m["nome"] as String,
                assentos: m["assentos"] as int,
                ocupados: m["ocupados"] as int,
                color: m["color"] as Color,
                icon: m["icon"] as IconData,
                convidados: (m["convidados"] as List)
                    .map((c) => _ConvidadoItem(
                          nome: c["nome"] as String,
                          confirmado: c["confirmado"] as bool,
                        ))
                    .toList(),
              )),

          const SizedBox(height: 24),
          const _ResumoMesas(),
          const SizedBox(height: 32),
          const _GraficoMesas(),
          const SizedBox(height: 110),
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

/// === RESUMO das MESAS ===
class _ResumoMesas extends StatelessWidget {
  const _ResumoMesas();

  @override
  Widget build(BuildContext context) {
    final resumo = [
      {"label": "Mesas totais", "value": 3, "color": Colors.teal},
      {"label": "Assentos totais", "value": 24, "color": Colors.orange},
      {"label": "Ocupados", "value": 13, "color": Colors.pinkAccent},
      {"label": "Livres", "value": 11, "color": Colors.blueAccent},
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

  Widget _metricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
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

/// === GRÁFICO das MESAS ===
class _GraficoMesas extends StatelessWidget {
  const _GraficoMesas();

  @override
  Widget build(BuildContext context) {
    final principal = 8.0;
    final familia = 6.0;
    final amigos = 10.0;
    final total = principal + familia + amigos;

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "🪑 Distribuição dos Assentos por Mesa",
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
                _pieSection("Principal", principal / total, Colors.teal),
                _pieSection("Família", familia / total, Colors.orangeAccent),
                _pieSection("Amigos", amigos / total, Colors.pinkAccent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _graficoLegenda("Principal", Colors.teal),
        _graficoLegenda("Família", Colors.orangeAccent),
        _graficoLegenda("Amigos", Colors.pinkAccent),
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
