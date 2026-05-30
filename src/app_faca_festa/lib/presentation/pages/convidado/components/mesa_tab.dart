import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../../controllers/convidado/grupo_convidado_controller.dart';
import './../../../../data/models/convidado/grupo_convidado_model.dart';
import './../../../../controllers/convidado/convidado_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import './../../../../data/models/model.dart';

class MesasTab extends StatelessWidget {
  const MesasTab({super.key});

  GrupoConvidadoModel? _buscarGrupoPorNome(Iterable<GrupoConvidadoModel> grupos, String nome) {
    final nomeNormalizado = nome.trim().toLowerCase();
    for (final grupo in grupos) {
      if (grupo.nome.trim().toLowerCase() == nomeNormalizado) return grupo;
    }
    return null;
  }

  int _resolverAssentosMesa(
      {required GrupoConvidadoModel? grupoAtual,
      required int quantidadeConvidados,
      required int ocupados}) {
    const capacidadePadraoMesa = 5;
    final totalGrupo = grupoAtual?.totalConvidados ?? 0;
    var capacidade = totalGrupo > 0 ? totalGrupo : quantidadeConvidados;
    if (capacidade < capacidadePadraoMesa) capacidade = capacidadePadraoMesa;
    if (capacidade < ocupados) capacidade = ocupados;
    return capacidade;
  }

  Map<String, dynamic> _montarEstatisticasMesas(
      {required Map<String, List<ConvidadoModel>> grupos,
      required GrupoConvidadoController grupoController}) {
    var totalAssentos = 0, totalOcupados = 0;
    for (final entry in grupos.entries) {
      final ocupados = entry.value.where((c) => c.status == StatusConvidado.confirmado).length;
      final assentos = _resolverAssentosMesa(
          grupoAtual: _buscarGrupoPorNome(grupoController.grupos, entry.key),
          quantidadeConvidados: entry.value.length,
          ocupados: ocupados);
      totalAssentos += assentos;
      totalOcupados += ocupados;
    }
    return {
      'totalMesas': grupos.length,
      'assentos': totalAssentos,
      'ocupados': totalOcupados,
      'livres': totalAssentos - totalOcupados
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final controller = Get.find<ConvidadoController>();
    final grupoController = Get.find<GrupoConvidadoController>();
    final primary = theme.primaryColor.value;

    return Obx(() {
      final grupos = controller.convidadosPorMesa;
      final estat = _montarEstatisticasMesas(grupos: grupos, grupoController: grupoController);

      if (controller.carregando.value) return const Center(child: CircularProgressIndicator());
      if (grupos.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_seat_rounded, color: primary.withValues(alpha: 0.6), size: 36),
              const SizedBox(height: 10),
              Text("Nenhuma mesa",
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary.withValues(alpha: 0.85))),
              Text('Adicione mesas.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 11)),
            ],
          ),
        );
      }

      return Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFFFF9F9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const Center(
                child: Text("🍷 Mesas",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
            const SizedBox(height: 12),
            ...grupos.entries.map((entry) {
              final nome = entry.key;
              final convidados = entry.value;
              final ocupados =
                  convidados.where((c) => c.status == StatusConvidado.confirmado).length;
              final assentos = _resolverAssentosMesa(
                  grupoAtual: _buscarGrupoPorNome(grupoController.grupos, nome),
                  quantidadeConvidados: convidados.length,
                  ocupados: ocupados);
              final color = Biblioteca.gerarCorPorChaves([nome]);
              return _MesaCard(
                  nome: nome,
                  assentos: assentos,
                  ocupados: ocupados,
                  color: color,
                  icon: Icons.chair,
                  convidados: convidados
                      .map((c) => _ConvidadoItem(
                          nome: c.nome, confirmado: c.status == StatusConvidado.confirmado))
                      .toList());
            }),
            const SizedBox(height: 16),
            _ResumoMesas(estat: estat),
            const SizedBox(height: 20),
            _GraficoMesas(estat: estat),
            const SizedBox(height: 80),
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
      {"label": "Mesas", "value": estat['totalMesas'], "color": Colors.teal},
      {"label": "Assentos", "value": estat['assentos'], "color": Colors.orange},
      {"label": "Ocupados", "value": estat['ocupados'], "color": Colors.pinkAccent},
      {"label": "Livres", "value": estat['livres'], "color": Colors.blueAccent}
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text("📊 Resumo",
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87))),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resumo
                .map((r) => _metricCard(
                    context, r["label"] as String, r["value"].toString(), r["color"] as Color))
                .toList()),
      ],
    );
  }

  Widget _metricCard(BuildContext context, String label, String value, Color color) {
    final cardWidth = (MediaQuery.of(context).size.width / 2) - 16;
    return Container(
      width: cardWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 6, offset: const Offset(0, 2))
      ]),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            textAlign: TextAlign.center,
            style:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.black87))
      ]),
    );
  }
}

class _MesaCard extends StatelessWidget {
  final String nome;
  final int assentos;
  final int ocupados;
  final IconData icon;
  final Color color;
  final List<Widget> convidados;
  const _MesaCard(
      {required this.nome,
      required this.assentos,
      required this.ocupados,
      required this.icon,
      required this.color,
      required this.convidados});
  @override
  Widget build(BuildContext context) {
    final livres = (assentos - ocupados).clamp(0, assentos).toInt();
    final ocupacao = assentos <= 0 ? 0.0 : (ocupados / assentos).clamp(0.0, 1.0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))
      ]),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 16)),
        title:
            Text(nome, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
        subtitle: Row(children: [
          Text("$livres livres", style: const TextStyle(color: Colors.black54, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
              child: LinearProgressIndicator(
                  value: ocupacao.toDouble(),
                  color: color,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(4)))
        ]),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: convidados,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(confirmado ? Icons.event_available : Icons.event_busy,
          color: confirmado ? Colors.teal : Colors.redAccent, size: 18),
      title: Text(nome,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: confirmado ? Colors.black87 : Colors.black54)),
      trailing: confirmado
          ? const Icon(Icons.check_circle, color: Colors.teal, size: 14)
          : const Icon(Icons.hourglass_empty, color: Colors.redAccent, size: 14),
    );
  }
}

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
          padding: EdgeInsets.all(16),
          child: Center(
              child: Text('Sem dados suficientes.',
                  style: TextStyle(color: Colors.black54, fontSize: 12))));
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        const Text("🪑 Assentos",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
        const SizedBox(height: 12),
        SizedBox(
            height: 180,
            child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: [
              _pieSection("Ocupados", totalOcupados / totalAssentos, Colors.teal),
              _pieSection("Livres", totalLivres / totalAssentos, Colors.orangeAccent)
            ]))),
        const SizedBox(height: 12),
        _graficoLegenda("Ocupados (${totalOcupados.toInt()})", Colors.teal),
        _graficoLegenda("Livres (${totalLivres.toInt()})", Colors.orangeAccent),
        const SizedBox(height: 35),
      ],
    );
  }

  PieChartSectionData _pieSection(String label, double percent, Color color) => PieChartSectionData(
      color: color,
      value: percent,
      title: "${(percent * 100).toStringAsFixed(0)}%",
      radius: 50,
      titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
  Widget _graficoLegenda(String label, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87))
      ]));
}
