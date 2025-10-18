import 'package:app_faca_festa/core/utils/biblioteca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../controllers/app_controller.dart';
import '../../../controllers/event_theme_controller.dart';
import '../../pages/orcamento/orcamento_screen.dart';
import '../../pages/fornecedor/fornecedores_page.dart';
import '../../pages/tarefa/tarefas_screen.dart';
import '../convidado/convidado_page.dart';

class FestaCardsWidget extends StatelessWidget {
  const FestaCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appController = Get.find<AppController>();
    final themeController = Get.find<EventThemeController>();
    final corBase = themeController.primaryColor.value;
    final eventoModel = appController.eventoModel.value;

    // === Paletas harmônicas e contrastantes ===
    final Map<String, List<_CardStyle>> paletaPorTema = {
      'casamento': [
        _CardStyle(bg: Colors.white, text: Colors.pink.shade700, icon: Icons.storefront_rounded),
        _CardStyle(
            bg: const Color(0xFFFFF3F7),
            text: Colors.red.shade400,
            icon: Icons.attach_money_rounded),
        _CardStyle(
            bg: const Color(0xFFFCE4EC),
            text: Colors.pink.shade600,
            icon: Icons.people_alt_rounded),
        _CardStyle(
            bg: const Color(0xFFFFEBEE),
            text: Colors.red.shade300,
            icon: Icons.check_circle_outline_rounded),
      ],
      'festa infantil': [
        _CardStyle(bg: Colors.white, text: Colors.orange.shade700, icon: Icons.storefront_rounded),
        _CardStyle(
            bg: const Color(0xFFFFF8E1),
            text: Colors.orange.shade800,
            icon: Icons.attach_money_rounded),
        _CardStyle(
            bg: const Color(0xFFFFECB3),
            text: Colors.deepOrange.shade700,
            icon: Icons.people_alt_rounded),
        _CardStyle(
            bg: const Color(0xFFFFF3E0),
            text: Colors.amber.shade800,
            icon: Icons.check_circle_outline_rounded),
      ],
      'chá de bebê': [
        _CardStyle(bg: Colors.white, text: Colors.blue.shade600, icon: Icons.storefront_rounded),
        _CardStyle(
            bg: const Color(0xFFE1F5FE),
            text: Colors.blue.shade700,
            icon: Icons.attach_money_rounded),
        _CardStyle(
            bg: const Color(0xFFB3E5FC),
            text: Colors.blue.shade800,
            icon: Icons.people_alt_rounded),
        _CardStyle(
            bg: const Color(0xFFE3F2FD),
            text: Colors.lightBlue.shade700,
            icon: Icons.check_circle_outline_rounded),
      ],
      'aniversário': [
        _CardStyle(
            bg: Colors.white, text: Colors.deepPurple.shade600, icon: Icons.storefront_rounded),
        _CardStyle(
            bg: const Color(0xFFF3E5F5),
            text: Colors.purple.shade700,
            icon: Icons.attach_money_rounded),
        _CardStyle(
            bg: const Color(0xFFEDE7F6),
            text: Colors.deepPurple.shade700,
            icon: Icons.people_alt_rounded),
        _CardStyle(
            bg: const Color(0xFFE1BEE7),
            text: Colors.purple.shade800,
            icon: Icons.check_circle_outline_rounded),
      ],
      'padrão': [
        _CardStyle(bg: Colors.white, text: corBase, icon: Icons.storefront_rounded),
        _CardStyle(bg: const Color(0xFFF1F8E9), text: corBase, icon: Icons.attach_money_rounded),
        _CardStyle(bg: const Color(0xFFE0F2F1), text: corBase, icon: Icons.people_alt_rounded),
        _CardStyle(
            bg: const Color(0xFFB2DFDB), text: corBase, icon: Icons.check_circle_outline_rounded),
      ],
    };

    // Detecta tema ativo
    final temaAtivo = themeController.tituloCabecalho.value.toLowerCase();
    final paleta = temaAtivo.contains('casamento')
        ? paletaPorTema['casamento']!
        : temaAtivo.contains('infantil')
            ? paletaPorTema['festa infantil']!
            : temaAtivo.contains('bebê')
                ? paletaPorTema['chá de bebê']!
                : temaAtivo.contains('aniversário')
                    ? paletaPorTema['aniversário']!
                    : paletaPorTema['padrão']!;

    final cards = [
      _CardData(title: "Fornecedores", subtitle: "3 contratado", style: paleta[0]),
      _CardData(
          title: "Orçamentos",
          subtitle: Biblioteca.formatarValorDecimal(eventoModel!.custoEstimado ?? 0),
          style: paleta[1]),
      _CardData(title: "Convidados", subtitle: "150 confirmados", style: paleta[2]),
      _CardData(title: "Tarefas", subtitle: "12 concluídas", style: paleta[3]),
    ];

    return SizedBox(
      height: 165,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final card = cards[index];
          return _FestaInfoCard(
            card: card,
            onTap: () {
              switch (card.title) {
                case "Orçamentos":
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const OrcamentoScreen()));
                  break;
                case "Fornecedores":
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const FornecedoresPage()));
                  break;
                case "Convidados":
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const ConvidadosPage()));
                  break;
                case "Tarefas":
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TarefasScreen()));
                  break;
              }
            },
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: (index * 100).ms)
              .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
        },
      ),
    );
  }
}

class _CardData {
  final String title;
  final String subtitle;
  final _CardStyle style;

  _CardData({required this.title, required this.subtitle, required this.style});
}

class _CardStyle {
  final Color bg;
  final Color text;
  final IconData icon;

  _CardStyle({required this.bg, required this.text, required this.icon});
}

class _FestaInfoCard extends StatelessWidget {
  final _CardData card;
  final VoidCallback onTap;

  const _FestaInfoCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: card.style.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card.style.text.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(card.style.icon, color: card.style.text, size: 28),
              const SizedBox(height: 14),
              Text(
                card.title,
                style: GoogleFonts.poppins(
                  color: card.style.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.subtitle,
                style: GoogleFonts.poppins(
                  color: card.style.text.withValues(alpha: 0.7),
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
