import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      final servicosAtivos = controller.servicosFornecedor.where((s) => s.ativo).length;
      final servicosDetalhadosAtivos = controller.servicosDetalhado.where((s) => s.ativo).length;
      final totalServicos = servicosAtivos > 0 ? servicosAtivos : servicosDetalhadosAtivos;
      final media = controller.avaliacaoMedia.value > 0
          ? controller.avaliacaoMedia.value
          : (fornecedor?.mediaAvaliacoes ?? 0.0);
      final totalAvaliacoes = fornecedor?.totalAvaliacoes ?? 0;
      final contratacoes = fornecedor?.totalContratacoes ?? 0;
      final respostaMedia = fornecedor?.tempoMedioRespostaHoras ??
          (controller.tempoMedioResposta.value > 0
              ? controller.tempoMedioResposta.value / 60
              : null);

      final stats = [
        _ResumoCardData(
          title: 'Cotações pendentes',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF2D7DFF),
          value: controller.solicitacoesPendentes.value.toString(),
          description: 'Aguardando resposta',
          onTap: null,
        ),
        _ResumoCardData(
          title: 'Mensagens',
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF00A6A6),
          value: controller.mensagensNaoLidas.value.toString(),
          description: 'Não lidas',
          onTap: () => Get.to(() => FornecedorMensagensPage()),
        ),
        _ResumoCardData(
          title: 'Catálogo ativo',
          icon: Icons.home_repair_service_outlined,
          color: const Color(0xFF27AE60),
          value: totalServicos.toString(),
          description: 'Serviços publicados',
          onTap: () async {
            final atual = controller.fornecedor.value;
            if (atual == null) return;
            controller.carregando.value = true;
            await controller.escutarServicosFornecedor(atual.idFornecedor);
            controller.carregando.value = false;
            Get.to(() => ServicoProdutoListScreen(fornecedorId: atual.idFornecedor));
          },
        ),
        _ResumoCardData(
          title: 'Reputação',
          icon: Icons.star_rounded,
          color: const Color(0xFFF59E0B),
          value: media <= 0 ? '-' : media.toStringAsFixed(1),
          description: totalAvaliacoes > 0
              ? '$totalAvaliacoes avaliação${totalAvaliacoes == 1 ? '' : 'ões'}'
              : 'Sem avaliações',
        ),
        _ResumoCardData(
          title: 'Resposta média',
          icon: Icons.speed_rounded,
          color: const Color(0xFF7C3AED),
          value: _formatarTempoResposta(respostaMedia),
          description: 'Tempo comercial',
        ),
        _ResumoCardData(
          title: 'Contratações',
          icon: Icons.handshake_outlined,
          color: const Color(0xFF14B8A6),
          value: contratacoes.toString(),
          description: 'Fechamentos consolidados',
        ),
        _ResumoCardData(
          title: 'Faixa de preço',
          icon: Icons.payments_outlined,
          color: const Color(0xFFEF4444),
          value: _formatarFaixaPreco(
            fornecedor?.precoMinimo,
            fornecedor?.precoMaximo,
            fornecedor?.precoMedio,
          ),
          description: 'Referência ao cliente',
        ),
        _ResumoCardData(
          title: 'Eventos atendidos',
          icon: Icons.celebration_outlined,
          color: const Color(0xFF6366F1),
          value: fornecedor?.tipoEventoNomes.isNotEmpty == true
              ? fornecedor!.tipoEventoNomes.length.toString()
              : '-',
          description: fornecedor?.tipoEventoNomes.isNotEmpty == true
              ? fornecedor!.tipoEventoNomes.take(2).join(' • ')
              : 'Não configurado',
        ),
      ];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.dashboard_customize_rounded,
              title: 'Visão operacional',
              subtitle: 'Indicadores sem repetição para acompanhar vendas, atendimento e reputação.',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 1040
                    ? 4
                    : width >= 680
                        ? 3
                        : 2;
                final mainExtent = width >= 680 ? 132.0 : 128.0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: mainExtent,
                  ),
                  itemBuilder: (_, i) => _PremiumResumoMetricCard(
                    key: ValueKey(stats[i].title),
                    data: stats[i],
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  static String _formatarTempoResposta(double? horas) {
    if (horas == null || horas <= 0) return '-';
    if (horas < 1) return '${(horas * 60).round()}min';
    if (horas < 24) return '${horas.toStringAsFixed(horas < 10 ? 1 : 0)}h';
    return '${(horas / 24).toStringAsFixed(1)}d';
  }

  static String _formatarFaixaPreco(double? minimo, double? maximo, double? medio) {
    final currency = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
    if (minimo != null && maximo != null && minimo > 0 && maximo > 0) {
      return '${currency.format(minimo)} - ${currency.format(maximo)}';
    }
    if (medio != null && medio > 0) return currency.format(medio);
    if (minimo != null && minimo > 0) return 'A partir de ${currency.format(minimo)}';
    return '-';
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 19),
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
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumoCardData {
  final String title;
  final String description;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ResumoCardData({
    required this.title,
    required this.description,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _PremiumResumoMetricCard extends StatelessWidget {
  final _ResumoCardData data;

  const _PremiumResumoMetricCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: data.color.withValues(alpha: 0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(data.icon, color: data.color, size: 19),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.value,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                data.description,
                style: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 10.6),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
