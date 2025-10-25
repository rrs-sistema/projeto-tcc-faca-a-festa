import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../components/show_responder_cotacao_bottom_sheet.dart';
import './../../cadastro/servico/fornecedor_servico_list_screen.dart';
import './../../../../controllers/event_theme_controller.dart';
import './../../../../controllers/fornecedor_controller.dart';

class ResumoSection extends StatelessWidget {
  const ResumoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();
    final themeController = Get.find<EventThemeController>();

    // 🔹 Cores e gradiente principal
    final gradient = themeController.gradient.value;

    return Obx(() {
      // 🔹 Atualiza automaticamente quando algo mudar no controlador
      final stats = [
        _ResumoCardData(
          title: "Solicitações",
          icon: Icons.pending_actions_outlined,
          color1: const Color(0xFF81C784),
          color2: const Color(0xFF388E3C),
          value: controller.solicitacoesPendentes.value,
          description: "pendentes",
          onTap: () async {
            final fornecedorController = Get.find<FornecedorController>();
            final solicitacoes = await fornecedorController.buscarSolicitacoesPendentesDetalhadas();

            if (solicitacoes.isEmpty) {
              Get.snackbar(
                "Sem solicitações",
                "Você não possui solicitações pendentes no momento.",
                backgroundColor: Colors.orange.shade100,
                colorText: Colors.black87,
              );
              return;
            }

            // === Mostra lista de solicitações pendentes ===
            Get.bottomSheet(
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Text(
                        "Solicitações Pendentes",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: solicitacoes.length,
                          itemBuilder: (context, index) {
                            final s = solicitacoes[index];
                            final dataEnvio = s['dataEnvio'] is Timestamp
                                ? DateFormat("dd/MM/yyyy")
                                    .format((s['dataEnvio'] as Timestamp).toDate())
                                : '';

                            return ListTile(
                              leading: const Icon(Icons.assignment_outlined, color: Colors.green),
                              title: Text(
                                s['categoriaNome'],
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                "Enviada em $dataEnvio",
                                style:
                                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                              onTap: () {
                                Get.back(); // fecha a lista
                                showResponderCotacaoBottomSheet(
                                  context: context,
                                  idCotacao: s['idCotacao'],
                                  categoriaNome: s['categoriaNome'],
                                  descricao: s['descricao'],
                                );
                              },
                            );
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
          title: "Serviços Ativos",
          icon: Icons.home_repair_service_outlined,
          color1: const Color(0xFFA5D6A7),
          color2: const Color(0xFF43A047),
          value: controller.servicosFornecedor.length,
          description: "publicados",
          onTap: () async {
            final fornecedor = controller.fornecedor.value;
            if (fornecedor != null) {
              controller.carregando.value = true;
              await controller.listarServicosFornecedor(fornecedor.idFornecedor);

              ever(controller.carregando, (loading) {
                if (loading == false) {
                  Get.to(() => FornecedorServicoListScreen(fornecedor: fornecedor));
                }
              });
            } else {
              Get.snackbar(
                "Atenção",
                "Nenhum fornecedor logado encontrado.",
                backgroundColor: Colors.orange.shade100,
                colorText: Colors.black87,
              );
            }
          },
        ),
        _ResumoCardData(
          title: "Mensagens",
          icon: Icons.chat_bubble_outline,
          color1: const Color(0xFFB2DFDB),
          color2: const Color(0xFF00796B),
          value: controller.mensagensNaoLidas.value,
          description: "não lidas",
        ),
        _ResumoCardData(
          title: "Avaliação Média",
          icon: Icons.star_border_rounded,
          color1: const Color(0xFFC5E1A5),
          color2: const Color(0xFF558B2F),
          value: controller.avaliacaoMedia.value.round(),
          description: "estrelas",
        ),
      ];

      final crossAxisCount = MediaQuery.of(context).size.width > 900
          ? 4
          : MediaQuery.of(context).size.width > 650
              ? 3
              : 2;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (_, i) => _ResumoCard(data: stats[i]),
        ),
      );
    });
  }
}

class _ResumoCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color1;
  final Color color2;
  final int value;
  final VoidCallback? onTap;

  _ResumoCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color1,
    required this.color2,
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              d.color1,
              d.color2.withValues(alpha: hovered ? 1.0 : 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: d.color2.withValues(alpha: 0.4),
              blurRadius: hovered ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: d.onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: hovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(d.icon, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  d.value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  d.description,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  d.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
