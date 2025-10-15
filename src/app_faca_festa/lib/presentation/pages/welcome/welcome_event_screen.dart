import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../fornecedor/fornecedor_home_screen.dart';
import '../usuario/show_fornecedor_cadastro_bottom_sheet.dart';
import '../usuario/show_user_info_bottom_sheet.dart';
import './../home_event_screen.dart';

class WelcomeEventScreen extends StatelessWidget {
  const WelcomeEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_EventType> eventTypes = [
      _EventType("Casamento", "💍", Colors.pinkAccent),
      _EventType("Festa Infantil", "🎈", Colors.orangeAccent),
      _EventType("Chá de Bebê", "🍼", Colors.lightBlueAccent),
      _EventType("Aniversário", "🎂", Colors.purpleAccent),
      _EventType("Sou Fornecedor", "🧑‍🔧", Colors.greenAccent),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // 🌸 Fundo alegre e colorido
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_event_001.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🎨 Overlay festivo com gradiente vibrante
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF9C4), // amarelo pastel
                  Color(0xFFFFC1E3), // rosa suave
                  Color(0xFFB3E5FC), // azul bebê
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🪄 Leve camada branca translúcida para suavizar
          Container(color: Colors.white.withValues(alpha: 0.3)),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  "🎊 Faça a Festa",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.pink.shade800,
                    letterSpacing: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.6),
                        offset: const Offset(1, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Escolha o tipo de evento",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // 🧩 Grid de opções coloridas
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1,
                    ),
                    itemCount: eventTypes.length,
                    itemBuilder: (context, index) {
                      final item = eventTypes[index];
                      return _EventTypeCard(
                          data: item,
                          onTap: () async {
                            if (item.title == "Sou Fornecedor") {
                              final confirmado = await showFornecedorCadastroBottomSheet(context);
                              if (confirmado) {
                                Get.to(
                                  () => const FornecedorHomeScreen(),
                                  transition: Transition.fadeIn,
                                  duration: const Duration(milliseconds: 700),
                                );
                              }
                            } else {
                              final userInfo = await showUserInfoBottomSheet(
                                context,
                                tipoEvento: item.title,
                              );

                              if (userInfo != null) {
                                Get.to(
                                  () => HomeEventScreen(
                                    tipoEvento: item.title,
                                    userInfo: userInfo,
                                  ),
                                  transition: Transition.fadeIn,
                                  duration: const Duration(milliseconds: 700),
                                );
                              }
                            }
                          });
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "por RRS System Technology",
                    style: GoogleFonts.poppins(
                      color: Colors.pink.shade800.withValues(alpha: 0.7),
                      fontSize: 13,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventType {
  final String title;
  final String emoji;
  final Color color;

  _EventType(this.title, this.emoji, this.color);
}

class _EventTypeCard extends StatefulWidget {
  final _EventType data;
  final VoidCallback onTap;

  const _EventTypeCard({required this.data, required this.onTap});

  @override
  State<_EventTypeCard> createState() => _EventTypeCardState();
}

class _EventTypeCardState extends State<_EventTypeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapCancel: () => setState(() => _hovered = false),
      onTapUp: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              data.color.withValues(alpha: 0.9),
              data.color.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: data.color.withValues(alpha: _hovered ? 0.6 : 0.4),
              blurRadius: _hovered ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _hovered ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  data.emoji,
                  style: const TextStyle(fontSize: 56),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      offset: const Offset(1, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
