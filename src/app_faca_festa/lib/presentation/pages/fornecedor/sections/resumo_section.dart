import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../controllers/fornecedor_controller.dart';

class ResumoSection extends StatelessWidget {
  const ResumoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FornecedorController>();

    final cards = [
      _ResumoCardData(
        title: "Solicitações",
        icon: Icons.pending_actions_outlined,
        color1: const Color(0xFF81C784),
        color2: const Color(0xFF388E3C),
        value: controller.solicitacoesPendentes,
        description: "pendentes",
      ),
      _ResumoCardData(
        title: "Serviços Ativos",
        icon: Icons.home_repair_service_outlined,
        color1: const Color(0xFFA5D6A7),
        color2: const Color(0xFF43A047),
        value: RxInt(controller.servicosFornecedor.length),
        description: "publicados",
      ),
      _ResumoCardData(
        title: "Mensagens",
        icon: Icons.chat_bubble_outline,
        color1: const Color(0xFFB2DFDB),
        color2: const Color(0xFF00796B),
        value: controller.mensagensNaoLidas,
        description: "não lidas",
      ),
      _ResumoCardData(
        title: "Avaliação Média",
        icon: Icons.star_border_rounded,
        color1: const Color(0xFFC5E1A5),
        color2: const Color(0xFF558B2F),
        value: RxInt(controller.avaliacaoMedia.value.round()),
        description: "estrelas",
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _ResumoCard(data: card);
          },
        );
      },
    );
  }
}

class _ResumoCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color1;
  final Color color2;
  final RxInt value;

  _ResumoCardData({
    required this.title,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.value,
    required this.description,
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
    return Obx(() {
      return MouseRegion(
        onEnter: (_) => setState(() => hovered = true),
        onExit: (_) => setState(() => hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                d.color1,
                d.color2.withValues(alpha: hovered ? 1.0 : 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: d.color2.withValues(alpha: 0.4),
                blurRadius: hovered ? 10 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(d.icon, color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(
                  d.value.value.toString(),
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
      );
    });
  }
}
