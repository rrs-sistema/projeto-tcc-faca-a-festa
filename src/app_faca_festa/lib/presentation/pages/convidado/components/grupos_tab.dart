import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../../data/models/convidado/grupo_convidado_model.dart';
import './../../../../data/models/model.dart';

class GruposTab extends StatelessWidget {
  const GruposTab({super.key});

  @override
  Widget build(BuildContext context) {
    final grupoController = Get.find<GrupoConvidadoController>();

    return Obx(() {
      if (grupoController.carregando.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final grupos = grupoController.grupos;

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

            // 🔥 GRUPOS REAIS DO FIREBASE
            ...grupos.map((g) => _GrupoCard(
                  title: g.nome,
                  icon: _iconFromKey(g.icone), // (vou te mostrar isso também)
                  color: fromHex(g.corHex ?? '#FF7BAC'),
                  convidados: g.convidados.map((c) {
                    return _ConvidadoItem(
                      nome: c.nome,
                      confirmado: c.status == StatusConvidado.confirmado,
                    );
                  }).toList(),
                )),

            const SizedBox(height: 20),

            // 🔥 RESUMO DINÂMICO
            _ResumoGrupos(
              totalGrupos: grupoController.totalGrupos,
              gruposComConvidados: grupoController.gruposComConvidados,
              totalConvidados: grupoController.totalConvidados,
              gruposVazios: grupoController.gruposVazios,
            ),

            const SizedBox(height: 32),

            // 🔥 GRÁFICO DINÂMICO
            _GraficoGrupos(grupos: grupos),

            const SizedBox(height: 110),
          ],
        ),
      );
    });
  }
}

class _ResumoGrupos extends StatelessWidget {
  final int totalGrupos;
  final int gruposComConvidados;
  final int totalConvidados;
  final int gruposVazios;

  const _ResumoGrupos({
    required this.totalGrupos,
    required this.gruposComConvidados,
    required this.totalConvidados,
    required this.gruposVazios,
  });

  @override
  Widget build(BuildContext context) {
    final resumo = [
      {"label": "Grupos criados", "value": totalGrupos, "color": Colors.teal},
      {"label": "Grupos com convidados", "value": gruposComConvidados, "color": Colors.orange},
      {"label": "Total de convidados", "value": totalConvidados, "color": Colors.pinkAccent},
      {"label": "Grupos vazios", "value": gruposVazios, "color": Colors.grey},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth / 2) - 28;

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
          children: resumo.map((r) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: cardWidth,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: (r["color"] as Color).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    r["value"].toString(),
                    style: TextStyle(
                      color: r["color"] as Color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r["label"] as String,
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
          }).toList(),
        ),
      ],
    );
  }
}

class _GraficoGrupos extends StatelessWidget {
  final List<GrupoConvidadoModel> grupos;

  const _GraficoGrupos({required this.grupos});

  @override
  Widget build(BuildContext context) {
    final total = grupos.fold<int>(0, (s, g) => s + g.convidados.length);

    if (total == 0) {
      return const SizedBox.shrink();
    }

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
              sections: grupos.map((g) {
                final percent = g.convidados.isEmpty ? 0 : g.convidados.length / total;

                final color = Colors.primaries[grupos.indexOf(g) % Colors.primaries.length];

                return PieChartSectionData(
                  color: color,
                  value: percent.toDouble(),
                  title: "${(percent * 100).toStringAsFixed(0)}%",
                  radius: 70,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...grupos.map((g) {
          final color = Colors.primaries[grupos.indexOf(g) % Colors.primaries.length];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: color, size: 12),
                const SizedBox(width: 6),
                Text(g.nome),
              ],
            ),
          );
        }),
        const SizedBox(height: 65),
      ],
    );
  }
}

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

Color fromHex(String hex) {
  hex = hex.replaceAll('#', '');
  return Color(int.parse('0xff$hex'));
}

IconData _iconFromKey(String? key) {
  return mapaIcones[key] ?? Icons.group_rounded;
}

final mapaIcones = {
  'group': Icons.group_rounded,
  'family': Icons.family_restroom_rounded,
  'star': Icons.star_rounded,
  'favorite': Icons.favorite_rounded,
  'chair': Icons.chair_rounded,
  'cake': Icons.cake_rounded,
  'music': Icons.music_note_rounded,
  'work': Icons.work_rounded,
  'pets': Icons.pets_rounded,
  'sports': Icons.sports_soccer_rounded,
  'emoji': Icons.emoji_people_rounded,
  'school': Icons.school_rounded,
  'travel': Icons.flight_takeoff_rounded,
};
