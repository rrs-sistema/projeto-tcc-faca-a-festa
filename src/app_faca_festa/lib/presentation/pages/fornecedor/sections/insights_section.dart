import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import '../../../../data/models/fornecedor_intelligence/insight_fornecedor_model.dart';

class InsightsSection extends StatelessWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final insights = controller.insightsFornecedor
          .where((i) => i.status != 'resolvido' && i.status != 'ignorado')
          .toList();
      final alertas = controller.alertasPerfil.toList();
      final loading = controller.isLoadingAi.value;

      final merged = <InsightFornecedorModel>[
        ...insights,
        ...alertas
            .where((a) => insights.every((i) => i.idInsight != a.idInsight)),
      ]..sort((a, b) {
          final byPriority = b.prioridade.compareTo(a.prioridade);
          if (byPriority != 0) return byPriority;
          return (b.score ?? 0).compareTo(a.score ?? 0);
        });

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final header = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          size: 19, color: Color(0xFF4F46E5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Insights práticos',
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827))),
                          const SizedBox(height: 2),
                          Text(
                              'Recomendações, alertas e oportunidades para vender melhor.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ],
                );

                final action = loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : OutlinedButton.icon(
                        onPressed: () => controller.recalcularAiFornecedor(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text('Recalcular',
                            style: GoogleFonts.poppins(
                                fontSize: 11.5, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          side: const BorderSide(color: Color(0xFFC7D2FE)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );

                if (compact) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [header, const SizedBox(height: 12), action]);
                }

                return Row(children: [
                  Expanded(child: header),
                  const SizedBox(width: 12),
                  action
                ]);
              },
            ),
            const SizedBox(height: 16),
            if (merged.isEmpty)
              const _EmptyInsights()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 980
                      ? 3
                      : constraints.maxWidth >= 650
                          ? 2
                          : 1;

                  const spacing = 10.0;
                  final items = merged.take(6).toList();
                  final cardWidth =
                      (constraints.maxWidth - (spacing * (columns - 1))) /
                          columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final insight in items)
                        SizedBox(
                          width: cardWidth,
                          child: _InsightCard(insight: insight),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      );
    });
  }
}

class _InsightCard extends StatelessWidget {
  final InsightFornecedorModel insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _colorByInsight(insight);
    final icon = _iconByInsight(insight.tipo);
    final motivos = insight.motivos.take(2).toList();
    final acoes = insight.acoesSugeridas.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13.2,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text(_labelTipo(insight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: color)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 11.8,
                  color: const Color(0xFF64748B),
                  height: 1.35)),
          if (motivos.isNotEmpty || acoes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...motivos.map((m) => _MiniPill(text: m, color: color)),
                ...acoes.map(
                    (a) => _MiniPill(text: a, color: const Color(0xFF111827))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Color _colorByInsight(InsightFornecedorModel insight) {
    if (insight.prioridade >= 5 || insight.nivel == 'alto') {
      return const Color(0xFFEF4444);
    }
    if (insight.tipo.contains('catalogo')) return const Color(0xFF7C3AED);
    if (insight.tipo.contains('reputacao')) return const Color(0xFFF59E0B);
    if (insight.tipo.contains('oportunidade')) return const Color(0xFF10B981);
    return const Color(0xFF4F46E5);
  }

  static IconData _iconByInsight(String tipo) {
    if (tipo.contains('catalogo')) return Icons.inventory_2_rounded;
    if (tipo.contains('reputacao')) return Icons.star_rate_rounded;
    if (tipo.contains('perfil')) return Icons.verified_user_rounded;
    if (tipo.contains('oportunidade')) {
      return Icons.local_fire_department_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  static String _labelTipo(InsightFornecedorModel insight) {
    final score =
        insight.score == null ? '' : ' • ${insight.score!.toStringAsFixed(0)}%';
    return '${insight.tipo.replaceAll('_', ' ')}$score';
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
              fontSize: 10.2,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569))),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhum alerta crítico no momento. Continue mantendo catálogo, atendimento e avaliações atualizados.',
              style: GoogleFonts.poppins(
                  fontSize: 12.3, color: const Color(0xFF64748B), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
