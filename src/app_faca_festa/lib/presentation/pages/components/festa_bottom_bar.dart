import 'package:flutter/material.dart';
import 'dart:ui';

class FestaBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FestaBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<FestaBottomBar> createState() => _FestaBottomBarState();
}

class _FestaBottomBarState extends State<FestaBottomBar> {
  final items = const [
    _NavItem(icon: Icons.home_outlined, label: 'Organizador'),
    _NavItem(icon: Icons.storefront_outlined, label: 'Fornecedores'),
    _NavItem(icon: Icons.lightbulb_outline, label: 'Inspiração'),
    _NavItem(icon: Icons.people_outline, label: 'Comunidade'),
    _NavItem(icon: Icons.more_horiz_outlined, label: 'Mais'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFCE4EC), // fundo branco rosado
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                final selected = widget.currentIndex == index;
                final item = items[index];

                // 🔹 Cores com contraste real em fundo claro
                final inactiveIconColor = const Color(0xFF9C6B87); // rosé escuro visível
                final inactiveTextColor = const Color(0xFF8E607A);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutQuad,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: selected
                            ? const LinearGradient(
                                colors: [Color(0xFFFF80AB), Color(0xFFFF4081)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                    colors: selected
                                        ? [
                                            Colors.white.withValues(alpha: 0.3),
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.3)
                                          ]
                                        : [Colors.transparent, Colors.transparent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                              blendMode: BlendMode.srcOver,
                              child: Icon(
                                item.icon,
                                color: selected ? Colors.white : inactiveIconColor,
                                size: selected ? 28 : 24,
                              )),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              item.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? Colors.white : inactiveTextColor,
                                fontSize: 11.5,
                                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
