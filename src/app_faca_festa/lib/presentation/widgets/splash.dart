import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';

import './../../controllers/app_controller.dart';
import './festa_app_bar.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final appController = Get.find<AppController>();

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

    // Após cadastrar um evento o usuário já está logado. Sem este passo o
    // splash fica eterno, porque o Auth não emite de novo só pela navegação.
    // Também cobre unknownRoute (`/notfound`) e o GetPage `/`, que renderizam
    // este widget sem o nome `/splash`.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      appController.iniciarSessao();
    });
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
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
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.celebration_rounded,
                    size: 88,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Faça a Festa",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final token = appController.conviteToken.value;
                  return Text(
                    token.isNotEmpty
                        ? "Carregando seu convite..."
                        : appController.carregando.value
                            ? "Carregando seus dados..."
                            : "Preparando sua experiência...",
                    style: TextStyle(
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
                const Text(
                  "Carregando o seu evento...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
