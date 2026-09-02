import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import './../../../../data/models/convidado/grupo_convidado_model.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import './../../../../core/utils/biblioteca.dart';
import './../../../../data/models/model.dart';

class MesasTab extends StatelessWidget {
  const MesasTab({super.key});

  GrupoConvidado? _buscarGrupoPorNome(
      Iterable<GrupoConvidado> grupos, String nome) {
    final nomeNormalizado = nome.trim().toLowerCase();
    for (final grupo in grupos) {
      if (grupo.nome.trim().toLowerCase() == nomeNormalizado) return grupo;
    }
    return null;
  }

  int _resolverAssentosMesa({
    required GrupoConvidado? grupoAtual,
    required int quantidadeConvidados,
    required int ocupados,
  }) {
    const capacidadePadraoMesa = 5;
    final totalGrupo = grupoAtual?.totalConvidados ?? 0;
    var capacidade = totalGrupo > 0 ? totalGrupo : quantidadeConvidados;
    if (capacidade < capacidadePadraoMesa) capacidade = capacidadePadraoMesa;
    if (capacidade < ocupados) capacidade = ocupados;
    return capacidade;
  }

  Map<String, dynamic> _montarEstatisticasMesas({
    required Map<String, List<Convidado>> grupos,
    required GrupoConvidadoController grupoController,
  }) {
    var totalAssentos = 0, totalOcupados = 0;
    for (final entry in grupos.entries) {
      final ocupados = entry.value
          .where((c) => c.status == StatusConvidado.confirmado)
          .length;
      final assentos = _resolverAssentosMesa(
        grupoAtual: _buscarGrupoPorNome(grupoController.grupos, entry.key),
        quantidadeConvidados: entry.value.length,
        ocupados: ocupados,
      );
      totalAssentos += assentos;
      totalOcupados += ocupados;
    }
    return {
      'totalMesas': grupos.length,
      'assentos': totalAssentos,
      'ocupados': totalOcupados,
      'livres': totalAssentos - totalOcupados,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<EventThemeController>();
    final controller = Get.find<ConvidadoController>();
    final grupoController = Get.find<GrupoConvidadoController>();

    return Obx(() {
      final primary = theme.primaryColor.value;
      final grupos = controller.convidadosPorMesa;
      final estat = _montarEstatisticasMesas(
        grupos: grupos,
        grupoController: grupoController,
      );

      if (controller.carregando.value) {
        return Center(child: CircularProgressIndicator(color: primary));
      }

      if (grupos.isEmpty) {
        return ColoredBox(
          color: const Color(0xFFF8FAFC),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.table_restaurant_rounded,
                        color: primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Nenhuma mesa definida',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'As mesas aparecem a partir dos grupos de convidados.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return ColoredBox(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
          children: [
            _MesasHero(
              primary: primary,
              totalMesas: estat['totalMesas'] as int,
              ocupados: estat['ocupados'] as int,
              assentos: estat['assentos'] as int,
            ),
            const SizedBox(height: 12),
            _ResumoMesas(estat: estat, primary: primary),
            const SizedBox(height: 18),
            _SectionTitle(
              icon: Icons.table_restaurant_rounded,
              title: 'Mesas',
              subtitle: 'Ocupação e convidados por mesa.',
              color: primary,
            ),
            const SizedBox(height: 10),
            ...grupos.entries.map((entry) {
              final nome = entry.key;
              final convidados = entry.value;
              final ocupados = convidados
                  .where((c) => c.status == StatusConvidado.confirmado)
                  .length;
              final assentos = _resolverAssentosMesa(
                grupoAtual: _buscarGrupoPorNome(grupoController.grupos, nome),
                quantidadeConvidados: convidados.length,
                ocupados: ocupados,
              );
              final color = Biblioteca.gerarCorPorChaves([nome]);
              return _MesaCard(
                nome: nome,
                assentos: assentos,
                ocupados: ocupados,
                color: color,
                icon: Icons.chair_rounded,
                convidados: convidados,
              );
            }),
            const SizedBox(height: 8),
            _GraficoMesas(estat: estat, primary: primary),
          ],
        ),
      );
    });
  }
}

class _MesasHero extends StatelessWidget {
  final Color primary;
  final int totalMesas;
  final int ocupados;
  final int assentos;

  const _MesasHero({
    required this.primary,
    required this.totalMesas,
    required this.ocupados,
    required this.assentos,
  });

  @override
  Widget build(BuildContext context) {
    final progresso =
        assentos <= 0 ? 0.0 : (ocupados / assentos).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.98),
            primary.withValues(alpha: 0.76),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arranjo de mesas',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$totalMesas mesas · $ocupados de $assentos lugares ocupados',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 6,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumoMesas extends StatelessWidget {
  final Map<String, dynamic> estat;
  final Color primary;
  const _ResumoMesas({required this.estat, required this.primary});

  @override
  Widget build(BuildContext context) {
    final resumo = [
      _ResumoItem('Mesas', estat['totalMesas'] as int, Icons.table_bar_rounded,
          primary),
      _ResumoItem(
        'Assentos',
        estat['assentos'] as int,
        Icons.event_seat_rounded,
        const Color(0xFFD97706),
      ),
      _ResumoItem(
        'Ocupados',
        estat['ocupados'] as int,
        Icons.how_to_reg_rounded,
        const Color(0xFFDB2777),
      ),
      _ResumoItem(
        'Livres',
        estat['livres'] as int,
        Icons.event_available_rounded,
        const Color(0xFF2563EB),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 24) / 4;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: resumo
            .map((item) =>
                SizedBox(width: width, child: _ResumoCard(item: item)))
            .toList(),
      );
    });
  }
}

class _ResumoItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _ResumoItem(this.label, this.value, this.icon, this.color);
}

class _ResumoCard extends StatelessWidget {
  final _ResumoItem item;
  const _ResumoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            item.value.toString(),
            style: GoogleFonts.poppins(
              color: const Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MesaCard extends StatelessWidget {
  final String nome;
  final int assentos;
  final int ocupados;
  final IconData icon;
  final Color color;
  final List<Convidado> convidados;

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
    final livres = (assentos - ocupados).clamp(0, assentos).toInt();
    final ocupacao =
        assentos <= 0 ? 0.0 : (ocupados / assentos).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: const Color(0xFF111827),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '$ocupados ocupados · $livres livres',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ocupacao,
                  minHeight: 5,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          children: convidados.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Nenhum convidado nesta mesa.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ]
              : convidados
                  .map(
                    (c) => _ConvidadoItem(
                      nome: c.nome,
                      confirmado: c.status == StatusConvidado.confirmado,
                    ),
                  )
                  .toList(),
        ),
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
    final color =
        confirmado ? const Color(0xFF059669) : const Color(0xFFD97706);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              confirmado
                  ? Icons.event_available_rounded
                  : Icons.schedule_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          Text(
            confirmado ? 'Confirmado' : 'Pendente',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficoMesas extends StatelessWidget {
  final Map<String, dynamic> estat;
  final Color primary;
  const _GraficoMesas({required this.estat, required this.primary});

  @override
  Widget build(BuildContext context) {
    final totalAssentos = (estat['assentos'] ?? 0).toDouble();
    final totalOcupados = (estat['ocupados'] ?? 0).toDouble();
    final totalLivres = (estat['livres'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.pie_chart_rounded,
            title: 'Ocupação',
            subtitle: 'Assentos confirmados versus livres.',
            color: primary,
          ),
          const SizedBox(height: 14),
          if (totalAssentos == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Sem dados suficientes para o gráfico.',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                  sections: [
                    if (totalOcupados > 0)
                      PieChartSectionData(
                        color: const Color(0xFF0F766E),
                        value: totalOcupados,
                        title:
                            '${((totalOcupados / totalAssentos) * 100).toStringAsFixed(0)}%',
                        radius: 52,
                        titleStyle: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (totalLivres > 0)
                      PieChartSectionData(
                        color: const Color(0xFFF59E0B),
                        value: totalLivres,
                        title:
                            '${((totalLivres / totalAssentos) * 100).toStringAsFixed(0)}%',
                        radius: 52,
                        titleStyle: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _legenda('Ocupados (${totalOcupados.toInt()})',
                    const Color(0xFF0F766E)),
                _legenda(
                    'Livres (${totalLivres.toInt()})', const Color(0xFFF59E0B)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legenda(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
