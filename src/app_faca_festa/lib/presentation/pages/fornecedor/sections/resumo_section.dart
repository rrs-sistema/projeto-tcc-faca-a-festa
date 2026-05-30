import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import './../../../../controllers/avaliacao/avaliacao_servico_controller.dart';
import './../../../../controllers/tema/event_theme_controller.dart';
import '../../../../controllers/servico/servico_produto_controller.dart';
import './../../cadastro/servico/servico_produto_list_screen.dart';
import '../../../../controllers/fornecedor/fornecedor_controller.dart';
import './../chat/fornecedor_mensagens_page.dart';
import './components/build_cotacao_card.dart';

class ResumoSection extends StatelessWidget {
  const ResumoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();
    final avaliacaoController = Get.find<AvaliacaoServicoController>();
    final servicoController = Get.find<ServicoProdutoController>();

    return Obx(() {
      final stats = [
        _ResumoCardData(
          title: "Cotações Ativas",
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF1E88E5),
          value: controller.solicitacoesPendentes.value,
          description: "Pendentes de resposta",
          onTap: () async {
            final fornecedorController = Get.find<FornecedorController>();
            final solicitacoes = await fornecedorController.buscarSolicitacoesPendentesDetalhadas();

            if (solicitacoes.isEmpty) {
              Get.snackbar(
                "Métricas",
                "Você não possui solicitações pendentes no momento.",
                backgroundColor: Colors.grey.shade900,
                colorText: Colors.white,
              );
              return;
            }

            Get.bottomSheet(
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.all(24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Text(
                        "Cotações Pendentes",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: solicitacoes.length,
                          itemBuilder: (context, index) {
                            final servicoMap = solicitacoes[index];
                            final dataEnvio = servicoMap['dataEnvio'] is Timestamp
                                ? DateFormat("dd/MM/yyyy")
                                    .format((servicoMap['dataEnvio'] as Timestamp).toDate())
                                : '';
                            final dataLimite = servicoMap['dataLimite'] is Timestamp
                                ? DateFormat("dd/MM/yyyy")
                                    .format((servicoMap['dataLimite'] as Timestamp).toDate())
                                : '';

                            return buildCotacaoCard(context, servicoMap, dataEnvio, dataLimite);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              isScrollControlled: true,
            );
          },
        ),
        _ResumoCardData(
          title: "Catálogo",
          icon: Icons.home_repair_service_outlined,
          color: const Color(0xFF43A047),
          value: servicoController.servicosFornecedor.length,
          description: "Serviços publicados",
          onTap: () async {
            final fornecedor = controller.fornecedor.value;
            if (fornecedor != null) {
              controller.carregando.value = true;
              await controller.escutarServicosFornecedor(fornecedor.idFornecedor);
              controller.carregando.value = false;
              Get.to(() => ServicoProdutoListScreen(fornecedorId: fornecedor.idFornecedor));
            }
          },
        ),
        _ResumoCardData(
          title: "Comunicações",
          icon: Icons.chat_bubble_outline_rounded,
          color: const Color(0xFF00796B),
          value: controller.mensagensNaoLidas.value,
          description: "Mensagens não lidas",
          onTap: () => Get.to(() => FornecedorMensagensPage()),
        ),
        _ResumoCardData(
          title: "Reputação",
          icon: Icons.star_border_rounded,
          color: const Color(0xFFF8A800),
          value: avaliacaoController.mediaFornecedor.value.isNaN
              ? 0
              : avaliacaoController.mediaFornecedor.value.toInt(),
          description: "Estrelas consolidadas",
        ),
      ];

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Breakpoints exatos: Desktop > Tablet > Mobile
          final crossAxisCount = width >= 1024 ? 4 : (width >= 600 ? 3 : 2);
          final aspectRatio = width >= 1024 ? 1.4 : (width >= 600 ? 1.2 : 1.1);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (_, i) => _ResumoCard(data: stats[i]),
          );
        },
      );
    });
  }
}

class _ResumoCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int value;
  final VoidCallback? onTap;

  _ResumoCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.value,
    this.onTap,
  });
}

class _ResumoCard extends StatefulWidget {
  final _ResumoCardData data;
  const _ResumoCard({required this.data});

  @override
  State<_ResumoCard> createState() => _ResumoCardState();
}

class _ResumoCardState extends State<_ResumoCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: hovered ? d.color.withValues(alpha: 0.4) : Colors.grey.shade200),
          boxShadow: [
            if (hovered)
              BoxShadow(
                color: d.color.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: InkWell(
          onTap: d.onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.transparent,
          splashColor: d.color.withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: d.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(d.icon, color: d.color, size: 20),
                    ),
                    Flexible(
                      child: Text(
                        d.value.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.title,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.description,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
