import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'fornecedor_premium_layout.dart';

class AvaliacoesSection extends StatelessWidget {
  const AvaliacoesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final fornecedorController = Get.find<FornecedorController>();
    final avaliacaoController = Get.isRegistered<AvaliacaoServicoController>()
        ? Get.find<AvaliacaoServicoController>()
        : null;

    return Obx(() {
      final reputacao = fornecedorController.resumoReputacao.value;
      final fornecedor = fornecedorController.fornecedor.value;
      final mediaController = avaliacaoController?.mediaFornecedor.value ?? 0.0;
      final totalController =
          avaliacaoController?.avaliacoesFornecedor.length ?? 0;

      final media = reputacao?.mediaGeral ??
          (mediaController > 0
              ? mediaController
              : fornecedor?.mediaAvaliacoes ?? 0.0);
      final total = reputacao?.totalAvaliacoes ??
          (totalController > 0
              ? totalController
              : fornecedor?.totalAvaliacoes ?? 0);
      final pontosFortes = reputacao?.pontosFortes ?? const <String>[];
      final pontosAtencao = reputacao?.pontosAtencao ?? const <String>[];
      final resumo = reputacao?.resumo ??
          (total == 0
              ? 'Ainda não há avaliações suficientes.'
              : 'Acompanhe a média e os comentários para fortalecer sua reputação.');

      return PremiumSectionShell(
        title: 'Avaliações e reputação',
        subtitle: 'Resumo inteligente dos elogios e pontos de melhoria.',
        icon: Icons.star_rate_rounded,
        color: FornecedorPremiumPalette.amber,
        trailing: PremiumPill(
          text: '$total avaliação${total == 1 ? '' : 'ões'}',
          color: FornecedorPremiumPalette.amber,
          icon: Icons.reviews_rounded,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 760;
            final nota =
                _NotaResumo(media: media, total: total, resumo: resumo);
            final insights = _ReputacaoInsights(
              pontosFortes: pontosFortes,
              pontosAtencao: pontosAtencao,
            );

            if (!twoColumns) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [nota, const SizedBox(height: 12), insights],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: nota),
                const SizedBox(width: 12),
                Expanded(flex: 6, child: insights),
              ],
            );
          },
        ),
      );
    });
  }
}

class _NotaResumo extends StatelessWidget {
  final double media;
  final int total;
  final String resumo;

  const _NotaResumo(
      {required this.media, required this.total, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : (media / 5).clamp(0.0, 1.0).toDouble();
    final color = media >= 4.5
        ? FornecedorPremiumPalette.emerald
        : media >= 4
            ? const Color(0xFF2563EB)
            : media >= 3
                ? FornecedorPremiumPalette.amber
                : FornecedorPremiumPalette.rose;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: FornecedorPremiumPalette.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  total == 0 ? '--' : media.toStringAsFixed(1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 33,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/5',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: FornecedorPremiumPalette.softMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: percent,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            resumo,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: FornecedorPremiumPalette.muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReputacaoInsights extends StatelessWidget {
  final List<String> pontosFortes;
  final List<String> pontosAtencao;

  const _ReputacaoInsights(
      {required this.pontosFortes, required this.pontosAtencao});

  @override
  Widget build(BuildContext context) {
    final fortes = pontosFortes.isEmpty
        ? const ['Atenda bem e peça avaliações após eventos concluídos.']
        : pontosFortes;
    final melhorias = pontosAtencao.isEmpty
        ? const ['Nenhum ponto crítico identificado no momento.']
        : pontosAtencao;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final elogios = _InsightBox(
          title: 'Pontos fortes',
          icon: Icons.thumb_up_alt_rounded,
          color: FornecedorPremiumPalette.emerald,
          items: fortes.take(4).toList(),
        );
        final atencao = _InsightBox(
          title: 'Melhorias',
          icon: Icons.tips_and_updates_rounded,
          color: FornecedorPremiumPalette.amber,
          items: melhorias.take(4).toList(),
        );

        if (!twoColumns) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [elogios, const SizedBox(height: 10), atencao],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: elogios),
            const SizedBox(width: 10),
            Expanded(child: atencao)
          ],
        );
      },
    );
  }
}

class _InsightBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _InsightBox({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.3,
                    fontWeight: FontWeight.w800,
                    color: FornecedorPremiumPalette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.4,
                        color: const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
