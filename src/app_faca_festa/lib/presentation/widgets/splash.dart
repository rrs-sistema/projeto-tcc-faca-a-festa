import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

import './../../controllers/tema/event_theme_controller.dart';
import './../../controllers/app_controller.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final appController = Get.find<AppController>();
  final themeController = Get.find<EventThemeController>();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.forward();
    final novoEvento = (Get.arguments?['novoEvento'] ?? false) as bool;
    if (novoEvento) {
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAllNamed('/HomeEventScreen');
      });
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (novoEvento) {
          appController.iniciarSessao();
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [
        Colors.pinkAccent.shade100.withValues(alpha: 0.8),
        Colors.deepPurpleAccent.shade100.withValues(alpha: 0.7),
        Colors.blueAccent.shade100.withValues(alpha: 0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) => Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(gradient: gradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/confetti_background.json',
                  width: 180,
                  height: 180,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                Text(
                  "Faça a Festa",
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  return Text(
                    appController.carregando.value
                        ? "Carregando seus dados..."
                        : "Preparando sua experiência...",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
                const SizedBox(height: 28),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  "Carregando o seu evento...",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
