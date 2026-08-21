import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/convidado/convidado_controller.dart';
import '../../../controllers/tema/event_theme_controller.dart';
import './../../../controllers/orcamento_controller.dart';
import '../fornecedor/painel_cotacao_page.dart';
import './../../pages/orcamento/orcamento_screen.dart';
import './../../../controllers/tarefa_controller.dart';
import './../../../controllers/evento_controller.dart';
import './../../pages/tarefa/tarefas_screen.dart';
import './../../../core/utils/biblioteca.dart';
import './../convidado/convidado_page.dart';

class FestaCardsWidget extends StatelessWidget {
  const FestaCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final eventoController = Get.find<EventoController>();
    final orcamentoController = Get.find<OrcamentoController>();
    final tarefaController = Get.find<TarefaController>();
    final convidadoController = Get.find<ConvidadoController>();

    return Obx(() {
      final corBase = themeController.primaryColor.value;
      final secundaria = themeController.secondaryColor.value;
      final fundo = themeController.surfaceColor.value;
      final paleta = _paletaDoTema(corBase, secundaria, fundo);

      return SizedBox(
      height: 165,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          switch (index) {
            // === 1️⃣ Meus Fornecedores ===
            case 0:
              return Obx(() => _FestaInfoCard(
                    card: _CardData(
                      title: "Meus Fornecedores",
                      subtitle:
                          "${orcamentoController.contratadosCount.value} de: ${orcamentoController.fornecedorContatadoCount.value}",
                      style: paleta[0],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PainelCotacaoPage()),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: (index * 100).ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut));

            // === 2️⃣ Orçamentos ===
            case 1:
              return _FestaInfoCard(
                card: _CardData(
                    title: "Orçamentos", subtitle: "", style: paleta[1]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrcamentoScreen()),
                ),
                reactiveSubtitle: Obx(() {
                  final custo =
                      eventoController.eventoAtualEntidade?.custoEstimado ?? 0;
                  return Text(
                    Biblioteca.formatarValorDecimal(custo),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: paleta[1].text.withValues(alpha: 0.75),
                      fontSize: 12.5,
                    ),
                  );
                }),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (index * 100).ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);

            // === 3️⃣ Convidados ===
            case 2:
              return _FestaInfoCard(
                card: _CardData(
                    title: "Convidados", subtitle: "", style: paleta[2]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConvidadosPage()),
                ),
                reactiveSubtitle: Obx(() {
                  final total = convidadoController.totalConvidados;
                  final conf = convidadoController.totalConfirmados;
                  final pend = convidadoController.totalPendentes;
                  return Text(
                    "$conf confirmados de $total ($pend pendentes)",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: paleta[2].text.withValues(alpha: 0.75),
                      fontSize: 12.5,
                    ),
                  );
                }),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (index * 100).ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);

            // === 4️⃣ Tarefas ===
            case 3:
              return _FestaInfoCard(
                card:
                    _CardData(title: "Tarefas", subtitle: "", style: paleta[3]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TarefasScreen()),
                ),
                reactiveSubtitle: Obx(() {
                  final concluidas = tarefaController.concluidas;
                  final total = tarefaController.tarefas.length;
                  return Text(
                    "$concluidas de $total concluídas",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: paleta[3].text.withValues(alpha: 0.75),
                      fontSize: 12.5,
                    ),
                  );
                }),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: (index * 100).ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);

            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
    });
  }

  List<_CardStyle> _paletaDoTema(Color primaria, Color secundaria, Color fundo) {
    return [
      _CardStyle(
        bg: Colors.white,
        text: primaria,
        icon: Icons.storefront_rounded,
      ),
      _CardStyle(
        bg: fundo,
        text: primaria,
        icon: Icons.attach_money_rounded,
      ),
      _CardStyle(
        bg: Colors.white,
        text: secundaria.computeLuminance() < 0.18 ? primaria : secundaria,
        icon: Icons.people_alt_rounded,
      ),
      _CardStyle(
        bg: fundo,
        text: primaria,
        icon: Icons.check_circle_outline_rounded,
      ),
    ];
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
  final Widget? reactiveSubtitle;

  const _FestaInfoCard({
    required this.card,
    required this.onTap,
    this.reactiveSubtitle,
  });

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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(card.style.icon, color: card.style.text, size: 26),
              const SizedBox(height: 10),
              Text(
                card.title,
                style: GoogleFonts.poppins(
                  color: card.style.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 6),
              // 🔹 Aqui usamos o texto reativo, se existir
              reactiveSubtitle != null
                  ? reactiveSubtitle!
                  : Text(
                      card.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: card.style.text.withValues(alpha: 0.75),
                        fontSize: 12.5,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
