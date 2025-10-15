import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CardapiosTab extends StatelessWidget {
  const CardapiosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cardapios = [
      {
        "title": "Adultos",
        "icon": Icons.local_dining_rounded,
        "color": const Color(0xFF8B0000),
        "items": [
          {"nome": "Prato principal: Risoto de camarão", "confirmado": true},
          {"nome": "Bebida: Vinho tinto seco", "confirmado": true},
        ]
      },
      {
        "title": "Crianças",
        "icon": Icons.icecream_outlined,
        "color": const Color(0xFFFFA000),
        "items": [
          {"nome": "Mini hambúrguer", "confirmado": true},
          {"nome": "Suco natural", "confirmado": true},
        ]
      },
      {
        "title": "Livre",
        "icon": Icons.restaurant_menu_rounded,
        "color": Colors.teal,
        "items": [
          {"nome": "Buffet completo", "confirmado": true},
          {"nome": "Sobremesa à vontade", "confirmado": true},
        ]
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFF9F9), Color(0xFFFFFFFF)],
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
              "🍽️ Cardápios do Evento",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Cards de categorias (Adultos, Crianças, Livre)
          ...cardapios.map((c) => _CardapioCategoriaCard(
                title: c["title"] as String,
                icon: c["icon"] as IconData,
                color: c["color"] as Color,
                items: (c["items"] as List)
                    .map((i) => _ConvidadoItem(
                          nome: i["nome"] as String,
                          confirmado: i["confirmado"] as bool,
                        ))
                    .toList(),
              )),
          const SizedBox(height: 20),

          // Estatísticas rápidas
          const _ResumoCardapioResumo(),

          const SizedBox(height: 32),

          // Gráfico visual
          const _GraficoCardapio(),

          const SizedBox(height: 110),
        ],
      ),
    );
  }
}

/// === CARD de Categoria ===
class _CardapioCategoriaCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> items;

  const _CardapioCategoriaCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 17,
          ),
        ),
        subtitle: Text(
          "${items.length} itens incluídos",
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: items,
      ),
    );
  }
}

/// === ITEM de convidado/prato ===
class _ConvidadoItem extends StatelessWidget {
  final String nome;
  final bool confirmado;

  const _ConvidadoItem({required this.nome, required this.confirmado});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: Icon(
        confirmado ? Icons.check_circle : Icons.radio_button_unchecked,
        color: confirmado ? Colors.teal : Colors.grey,
      ),
      title: Text(
        nome,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// === CARD de Resumo ===
class _ResumoCardapioResumo extends StatelessWidget {
  const _ResumoCardapioResumo();

  @override
  Widget build(BuildContext context) {
    final resumo = [
      {"label": "Cardápios totais", "value": 3, "color": Colors.teal},
      {"label": "Itens servidos", "value": 8, "color": Colors.orange},
      {"label": "Bebidas", "value": 3, "color": Colors.blueAccent},
      {"label": "Sobremesas", "value": 2, "color": Colors.pinkAccent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            "📈 Resumo geral do cardápio",
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

/// === GRÁFICO ===
class _GraficoCardapio extends StatelessWidget {
  const _GraficoCardapio();

  @override
  Widget build(BuildContext context) {
    final comidas = 8.0;
    final bebidas = 3.0;
    final sobremesas = 2.0;
    final total = comidas + bebidas + sobremesas;

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "🍷 Proporção dos Itens do Cardápio",
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
                _pieSection("Comidas", comidas / total, Colors.teal),
                _pieSection("Bebidas", bebidas / total, Colors.blueAccent),
                _pieSection("Sobremesas", sobremesas / total, Colors.pinkAccent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _graficoLegenda("Comidas", Colors.teal),
        _graficoLegenda("Bebidas", Colors.blueAccent),
        _graficoLegenda("Sobremesas", Colors.pinkAccent),
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
