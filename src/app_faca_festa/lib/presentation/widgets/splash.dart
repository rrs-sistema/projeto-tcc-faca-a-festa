import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/fornecedor_controller.dart';
import './../../controllers/app_controller.dart';

/// =============================
/// 🎬 SPLASH SCREEN
/// =============================
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // ⏳ Espera 3 segundos antes de redirecionar
    await Future.delayed(const Duration(seconds: 3));

    final appController = Get.find<AppController>();
    final fornecedorController = Get.find<FornecedorController>();
    if (appController.usuarioLogado.value != null) {
      if (appController.usuarioLogado.value!.tipo == 'F') {
        final fornecedor = await fornecedorController
            .buscarFornecedor(appController.usuarioLogado.value!.idUsuario);
        Get.offAllNamed(
          '/fornecedor',
          arguments: {'fornecedor': fornecedor},
        );
      } else if (appController.usuarioLogado.value!.tipo == '') {
        Get.offAllNamed('/role');
      }
    } else {
      Get.offAllNamed('/role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF9C4), Color(0xFFFFC1E3), Color(0xFFB3E5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, color: Colors.pink, size: 80),
              const SizedBox(height: 20),
              Text(
                "Faça a Festa",
                style: TextStyle(
                  color: Colors.pink.shade800,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const CircularProgressIndicator(color: Colors.pinkAccent),
              const SizedBox(height: 16),
              Text(
                "Carregando o seu evento...",
                style: TextStyle(
                  color: Colors.pink.shade800.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
