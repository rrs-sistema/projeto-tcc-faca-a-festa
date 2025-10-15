import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../convidado/convidado_page.dart';
import '../fornecedor/fornecedores_page.dart';
import '../orcamento/orcamento_screen.dart';
import '../tarefa/tarefas_screen.dart';

class FestaCardsWidget extends StatelessWidget {
  const FestaCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData(
        icon: Icons.storefront_rounded,
        title: "Fornecedores",
        subtitle: "3 ativos",
        gradient: const LinearGradient(
          colors: [Color(0xFFFF80AB), Color(0xFFFF4081)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        icon: Icons.attach_money_rounded,
        title: "Orçamentos",
        subtitle: "R\$ 25.000",
        gradient: const LinearGradient(
          colors: [Color(0xFF81D4FA), Color(0xFF039BE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        icon: Icons.people_alt_rounded,
        title: "Convidados",
        subtitle: "150 confirmados",
        gradient: const LinearGradient(
          colors: [Color(0xFFB39DDB), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        icon: Icons.check_circle_outline_rounded,
        title: "Tarefas",
        subtitle: "12 concluídas",
        gradient: const LinearGradient(
          colors: [Color(0xFF80CBC4), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
              // 👇 ação personalizada para cada card
              switch (card.title) {
                case "Orçamentos":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrcamentoScreen(),
                    ),
                  );
                  break;
                case "Fornecedores":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FornecedoresPage(),
                    ),
                  );
                  break;
                case "Convidados":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConvidadosPage(),
                    ),
                  );
                  break;
                case "Tarefas":
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TarefasScreen(),
                    ),
                  );
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

// ===============================================================

class _CardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;

  _CardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

// ===============================================================

class _FestaInfoCard extends StatelessWidget {
  final _CardData card;
  final VoidCallback? onTap; // 👈 adicionamos o clique

  const _FestaInfoCard({required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // 👈 chama a ação passada
      borderRadius: BorderRadius.circular(20),
      splashColor: Colors.white.withValues(alpha: 0.2),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: card.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: card.gradient.colors.last.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(card.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                card.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              card.subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
