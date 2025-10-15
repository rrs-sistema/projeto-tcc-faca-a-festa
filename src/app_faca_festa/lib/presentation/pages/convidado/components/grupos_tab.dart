import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// --- Aba: Grupos ---
class GruposTab extends StatelessWidget {
  const GruposTab({super.key});

  @override
  Widget build(BuildContext context) {
    final grupos = [
      {
        "title": "Casais",
        "icon": Icons.favorite_rounded,
        "color": Colors.pinkAccent,
        "convidados": [
          {"nome": "Rivaldo & Jullia", "confirmado": true},
          {"nome": "Carlos & Marta", "confirmado": true},
        ]
      },
      {
        "title": "Família RRS Sistemas",
        "icon": Icons.family_restroom_rounded,
        "color": Colors.teal,
        "convidados": [
          {"nome": "RRS Pai", "confirmado": true},
          {"nome": "RRS Mãe", "confirmado": false},
          {"nome": "RRS Filho", "confirmado": false},
        ]
      },
      {
        "title": "Amigos RRS Sistemas",
        "icon": Icons.group_rounded,
        "color": Colors.orangeAccent,
        "convidados": [
          {"nome": "Murillo", "confirmado": true},
          {"nome": "Jezreel", "confirmado": true},
          {"nome": "Amanda", "confirmado": false},
        ]
      },
      {
        "title": "Família No Futuro",
        "icon": Icons.favorite_outline,
        "color": Colors.deepPurpleAccent,
        "convidados": [],
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF8F8), Color(0xFFFFFFFF)],
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
              "👨‍👩‍👧‍👦 Grupos de Convidados",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Cards de grupos
          ...grupos.map((g) => _GrupoCard(
                title: g["title"] as String,
                icon: g["icon"] as IconData,
                color: g["color"] as Color,
                convidados: (g["convidados"] as List)
                    .map((c) => _ConvidadoItem(
                          nome: c["nome"] as String,
                          confirmado: c["confirmado"] as bool,
                        ))
                    .toList(),
              )),

          const SizedBox(height: 20),

          // Resumo de grupos
          const _ResumoGrupos(),

          const SizedBox(height: 32),

          // Gráfico visual
          const _GraficoGrupos(),

          const SizedBox(height: 110),
        ],
      ),
    );
  }
}

/// === CARD de Grupo ===
class _GrupoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> convidados;

  const _GrupoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.convidados,
  });

  @override
  Widget build(BuildContext context) {
    final temConvidados = convidados.isNotEmpty;

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
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: color,
          ),
        ),
        subtitle: Text(
          temConvidados ? "${convidados.length} convidados" : "Nenhum convidado adicionado",
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: temConvidados
            ? convidados
            : [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "Nenhum convidado neste grupo.",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
      ),
    );
  }
}

/// === ITEM de convidado ===
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
        confirmado ? Icons.check_circle : Icons.hourglass_empty_rounded,
        color: confirmado ? Colors.teal : Colors.orangeAccent,
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
          ? const Icon(Icons.verified_rounded, color: Colors.teal, size: 18)
          : const Icon(Icons.pending_actions_rounded, color: Colors.orangeAccent, size: 18),
    );
  }
}

/// === RESUMO de GRUPOS ===
class _ResumoGrupos extends StatelessWidget {
  const _ResumoGrupos();

  @override
  Widget build(BuildContext context) {
    final resumo = [
      {"label": "Grupos criados", "value": 4, "color": Colors.teal},
      {"label": "Grupos com convidados", "value": 3, "color": Colors.orange},
      {"label": "Total de convidados", "value": 8, "color": Colors.pinkAccent},
      {"label": "Grupos vazios", "value": 1, "color": Colors.grey},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            "📊 Resumo geral dos grupos",
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

/// === GRÁFICO de GRUPOS ===
class _GraficoGrupos extends StatelessWidget {
  const _GraficoGrupos();

  @override
  Widget build(BuildContext context) {
    final casais = 2.0;
    final familia = 3.0;
    final amigos = 3.0;
    final vazio = 1.0;
    final total = casais + familia + amigos + vazio;

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "📈 Distribuição de Convidados por Grupo",
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
                _pieSection("Casais", casais / total, Colors.pinkAccent),
                _pieSection("Família", familia / total, Colors.teal),
                _pieSection("Amigos", amigos / total, Colors.orangeAccent),
                _pieSection("Vazio", vazio / total, Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _graficoLegenda("Casais", Colors.pinkAccent),
        _graficoLegenda("Família", Colors.teal),
        _graficoLegenda("Amigos", Colors.orangeAccent),
        _graficoLegenda("Vazio", Colors.grey),
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
