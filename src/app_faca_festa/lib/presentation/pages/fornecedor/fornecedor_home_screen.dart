import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class FornecedorHomeScreen extends StatelessWidget {
  const FornecedorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _FornecedorCardData(
        title: "Solicitações Pendentes",
        subtitle: "Orçamentos a responder",
        icon: Icons.pending_actions_outlined,
        color1: const Color(0xFF81C784),
        color2: const Color(0xFF388E3C),
      ),
      _FornecedorCardData(
        title: "Serviços Cadastrados",
        subtitle: "Gerencie seu portfólio",
        icon: Icons.home_repair_service_outlined,
        color1: const Color(0xFFA5D6A7),
        color2: const Color(0xFF43A047),
      ),
      _FornecedorCardData(
        title: "Mensagens / Orçamentos",
        subtitle: "Converse com clientes",
        icon: Icons.chat_bubble_outline,
        color1: const Color(0xFFB2DFDB),
        color2: const Color(0xFF00796B),
      ),
      _FornecedorCardData(
        title: "Avaliações Recebidas",
        subtitle: "Veja seu desempenho",
        icon: Icons.star_border_rounded,
        color1: const Color(0xFFC5E1A5),
        color2: const Color(0xFF558B2F),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Painel do Fornecedor",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "👋 Olá, Fornecedor!",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Gerencie seus serviços e acompanhe seus orçamentos.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _FornecedorCard(
                    data: card,
                    onTap: () {
                      // 🔹 Aqui você redireciona para a tela correspondente
                      Get.snackbar(
                        card.title,
                        "Abrindo ${card.title.toLowerCase()}...",
                        backgroundColor: card.color2.withValues(alpha: 0.8),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "por RRS System Technology",
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FornecedorCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color1;
  final Color color2;

  _FornecedorCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color1,
    required this.color2,
  });
}

class _FornecedorCard extends StatefulWidget {
  final _FornecedorCardData data;
  final VoidCallback onTap;

  const _FornecedorCard({required this.data, required this.onTap});

  @override
  State<_FornecedorCard> createState() => _FornecedorCardState();
}

class _FornecedorCardState extends State<_FornecedorCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return GestureDetector(
      onTapDown: (_) => setState(() => hovered = true),
      onTapUp: (_) => setState(() => hovered = false),
      onTapCancel: () => setState(() => hovered = false),
      onTap: widget.onTap,
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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(d.icon, color: Colors.white, size: 48),
                const SizedBox(height: 10),
                Text(
                  d.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  d.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 14,
              top: 14,
              child: AnimatedOpacity(
                opacity: hovered ? 1 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
