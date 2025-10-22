import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import './../../../controllers/convidado/convidado_controller.dart';
import './../../../controllers/event_theme_controller.dart';
import './../../../controllers/orcamento_controller.dart';
import './../../pages/fornecedor/fornecedores_page.dart';
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

    // ✅ NÃO envolve tudo em Obx
    final corBase = themeController.primaryColor.value;
    final temaAtivo = themeController.tituloCabecalho.value.toLowerCase();

    final paleta = _obterPaletaPorTema(temaAtivo, corBase);

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
                      MaterialPageRoute(builder: (_) => const FornecedoresPage()),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: (index * 100).ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut));

            // === 2️⃣ Orçamentos ===
            case 1:
              return _FestaInfoCard(
                card: _CardData(title: "Orçamentos", subtitle: "", style: paleta[1]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrcamentoScreen()),
                ),
                reactiveSubtitle: Obx(() {
                  final custo = eventoController.eventoAtual.value?.custoEstimado ?? 0;
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
                card: _CardData(title: "Convidados", subtitle: "", style: paleta[2]),
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
                card: _CardData(title: "Tarefas", subtitle: "", style: paleta[3]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TarefasScreen()),
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
  }

  List<_CardStyle> _obterPaletaPorTema(String temaAtivo, Color corBase) {
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

    return temaAtivo.contains('casamento')
        ? paletaPorTema['casamento']!
        : temaAtivo.contains('infantil')
            ? paletaPorTema['festa infantil']!
            : temaAtivo.contains('bebê')
                ? paletaPorTema['chá de bebê']!
                : temaAtivo.contains('aniversário')
                    ? paletaPorTema['aniversário']!
                    : paletaPorTema['padrão']!;
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
