import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import './../../cadastro/servico/servico_produto_list_screen.dart';
import './../chat/fornecedor_mensagens_page.dart';

class ResumoSection extends StatelessWidget {
  const ResumoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    return Obx(() {
      final fornecedor = controller.fornecedor.value;
      final servicosAtivosDetalhados = controller.servicosDetalhado.where((s) => s.ativo).length;
      final servicosAtivosBasicos = controller.servicosFornecedor.where((s) => s.ativo).length;
      final totalServicosAtivos =
          servicosAtivosDetalhados > 0 ? servicosAtivosDetalhados : servicosAtivosBasicos;

      final reputacao = controller.resumoReputacao.value;
      final media = reputacao?.mediaGeral ??
          (controller.avaliacaoMedia.value > 0
              ? controller.avaliacaoMedia.value
              : fornecedor?.mediaAvaliacoes ?? 0.0);
      final totalAvaliacoes = reputacao?.totalAvaliacoes ?? fornecedor?.totalAvaliacoes ?? 0;
      final respostaHoras = fornecedor?.tempoMedioRespostaHoras ??
          (controller.tempoMedioResposta.value > 0
              ? controller.tempoMedioResposta.value / 60
              : 0.0);
      final contratacoes = fornecedor?.totalContratacoes ?? 0;
      final perfilCompleto = _calcularPerfilCompleto(controller);
      final oportunidadesQuentes =
          controller.scoresCotacoes.values.where((s) => s.score >= 75).length;

      final cards = [
        _MetricData(
          title: 'Cotações pendentes',
          value: controller.solicitacoesPendentes.value.toString(),
          subtitle: 'aguardando ação',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF6366F1),
        ),
        _MetricData(
          title: 'Mensagens não lidas',
          value: controller.mensagensNaoLidas.value.toString(),
          subtitle: 'abrir comunicações',
          icon: Icons.mark_chat_unread_rounded,
          color: const Color(0xFF0EA5E9),
          onTap: () => Get.to(() => FornecedorMensagensPage()),
        ),
        _MetricData(
          title: 'Serviços ativos',
          value: totalServicosAtivos.toString(),
          subtitle: 'abrir catálogo',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () async {
            final fornecedorAtual = controller.fornecedor.value;

            if (fornecedorAtual == null) {
              Get.snackbar(
                'Catálogo',
                'Não foi possível identificar o fornecedor para abrir o catálogo.',
                backgroundColor: const Color(0xFF111827),
                colorText: Colors.white,
              );
              return;
            }

            try {
              controller.carregando.value = true;
              await controller.escutarServicosFornecedor(
                fornecedorAtual.idFornecedor,
              );
            } finally {
              controller.carregando.value = false;
            }

            Get.to(
              () => ServicoProdutoListScreen(
                fornecedorId: fornecedorAtual.idFornecedor,
              ),
            );
          },
        ),
        _MetricData(
          title: 'Reputação',
          value: media > 0 ? media.toStringAsFixed(1) : '--',
          subtitle: '$totalAvaliacoes avaliação${totalAvaliacoes == 1 ? '' : 'ões'}',
          icon: Icons.star_rate_rounded,
          color: const Color(0xFFF59E0B),
        ),
        _MetricData(
          title: 'Resposta média',
          value: respostaHoras > 0 ? '${respostaHoras.toStringAsFixed(1)}h' : '--',
          subtitle: 'tempo estimado',
          icon: Icons.timer_rounded,
          color: const Color(0xFF14B8A6),
        ),
        _MetricData(
          title: 'Contratações',
          value: contratacoes.toString(),
          subtitle: 'histórico',
          icon: Icons.handshake_rounded,
          color: const Color(0xFF10B981),
        ),
        _MetricData(
          title: 'Perfil completo',
          value: '$perfilCompleto%',
          subtitle: _perfilLabel(perfilCompleto),
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF2563EB),
        ),
        _MetricData(
          title: 'Oportunidades quentes',
          value: oportunidadesQuentes.toString(),
          subtitle: 'score acima de 75%',
          icon: Icons.local_fire_department_rounded,
          color: const Color(0xFFEF4444),
        ),
      ];

      return _SectionShell(
        title: 'Visão operacional',
        subtitle: 'Indicadores essenciais sem repetir dados do cabeçalho.',
        action: controller.isLoadingAi.value
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: () => controller.recalcularAiFornecedor(),
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: Text(
                  'Atualizar IA',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1040
                ? 4
                : width >= 720
                    ? 3
                    : width >= 460
                        ? 2
                        : 1;

            return GridView.builder(
              itemCount: cards.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 118,
              ),
              itemBuilder: (_, index) => _MetricCard(data: cards[index]),
            );
          },
        ),
      );
    });
  }

  static int _calcularPerfilCompleto(FornecedorController controller) {
    final f = controller.fornecedor.value;
    if (f == null) return 0;

    final servicosAtivos = controller.servicosDetalhado.any((s) => s.ativo) ||
        controller.servicosFornecedor.any((s) => s.ativo);

    final checks = [
      f.razaoSocial.trim().isNotEmpty,
      (f.email ?? '').trim().isNotEmpty || (f.telefone ?? '').trim().isNotEmpty,
      (f.descricao ?? '').trim().isNotEmpty,
      (f.bannerUrl ?? '').trim().isNotEmpty,
      f.categorias.isNotEmpty,
      f.tipoEventoIds.isNotEmpty || f.tipoEventoSlugs.isNotEmpty || f.tipoEventoNomes.isNotEmpty,
      f.precoMinimo != null || f.precoMaximo != null || f.precoMedio != null,
      servicosAtivos,
    ];

    final done = checks.where((item) => item).length;
    return ((done / checks.length) * 100).round();
  }

  static String _perfilLabel(int value) {
    if (value >= 90) return 'excelente';
    if (value >= 70) return 'bom';
    if (value >= 45) return 'em evolução';
    return 'incompleto';
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
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
              final compact = constraints.maxWidth < 520;
              final header = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.dashboard_customize_rounded,
                        size: 19, color: Color(0xFF111827)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (compact || action == null) return header;

              return Row(
                children: [Expanded(child: header), const SizedBox(width: 12), action!],
              );
            },
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricData data;

  const _MetricCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final clickable = data.onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: clickable ? data.color.withValues(alpha: 0.04) : Colors.transparent,
        splashColor: clickable ? data.color.withValues(alpha: 0.08) : Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: clickable
                  ? data.color.withValues(alpha: 0.22)
                  : data.color.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(data.icon, color: data.color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (clickable) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: data.color,
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111827),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
