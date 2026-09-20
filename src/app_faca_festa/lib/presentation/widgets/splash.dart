import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';
import './festa_app_bar.dart';

class Splash extends StatefulWidget {
  const Splash({
    super.key,
    required this.appController,
  });

  final AppController appController;

  static const Duration duracaoMinima = Duration(milliseconds: 4500);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  Timer? _saida;

  @override
  void initState() {
    super.initState();
    widget.appController.reterNaSplash(minimo: Splash.duracaoMinima);
    _saida = Timer(Splash.duracaoMinima, _seguir);
  }

  void _seguir() {
    if (!mounted) return;
    widget.appController.iniciarSessao();
  }

  @override
  void dispose() {
    _saida?.cancel();
    super.dispose();
  }

  String _status() {
    final token = widget.appController.conviteToken.value;
    if (token.isNotEmpty) return 'Abrindo seu convite…';
    if (widget.appController.carregando.value) return 'Entrando…';
    return 'Preparando…';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF3F8),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AuthFestaBrand.fundo),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  const Spacer(),
                  const AuthFestaLogo(size: 140),
                  const SizedBox(height: 28),
                  Obx(
                    () => Text(
                      _status(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AuthFestaBrand.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AuthFestaBrand.rosa,
                    ),
                  ),
                  const Spacer(),
                  const AuthFestaCredits(mostrarPrivacidade: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
