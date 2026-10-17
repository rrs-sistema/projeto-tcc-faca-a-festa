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
  Widget build(BuildContext context) => Obx(
        () => SplashPresentation(status: _status()),
      );
}

/// Visual da entrada separado do ciclo de sessão para validar responsividade.
class SplashPresentation extends StatelessWidget {
  const SplashPresentation({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF342B3E);
    const muted = Color(0xFF746B7B);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoClaro,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9F6),
        body: SizedBox.expand(
            child: DecoratedBox(
          key: const ValueKey('splash-background'),
          decoration: const BoxDecoration(
              gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFCF9F6), Color(0xFFFFF0F5), Color(0xFFF4F1FA)],
          )),
          child: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
                child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          height:
                              (constraints.maxHeight * .05).clamp(16.0, 40.0)),
                      Text('PLANEJAR · CELEBRAR · RECORDAR',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: muted)),
                      const SizedBox(height: 32),
                      Container(
                        key: const ValueKey('splash-logo'),
                        width: 160,
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .85),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFFC44ED8)
                                    .withValues(alpha: .09),
                                blurRadius: 48,
                                offset: const Offset(0, 16))
                          ],
                        ),
                        child: const AuthFestaLogo(size: 132),
                      ),
                      const SizedBox(height: 32),
                      Text('Sua festa\ncomeça aqui.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 28,
                              height: 1.2,
                              letterSpacing: -.8,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                      const SizedBox(height: 12),
                      Text('Cuide dos detalhes.\nAproveite cada momento.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 14, height: 1.65, color: muted)),
                      const SizedBox(height: 32),
                      Semantics(
                          liveRegion: true,
                          child: Text(status,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: muted))),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const LinearProgressIndicator(
                                minHeight: 3,
                                color: Color(0xFFC44ED8),
                                backgroundColor: Color(0xFFE9DFEC)),
                          )),
                      SizedBox(
                          height:
                              (constraints.maxHeight * .07).clamp(24.0, 56.0)),
                      Text('Jullia A. · Nicolas B. · Rivaldo R.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: muted)),
                      const SizedBox(height: 6),
                      Text('© ${DateTime.now().year} Faça a Festa',
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.poppins(fontSize: 10, color: muted)),
                    ]),
              ),
            ));
          })),
        )),
      ),
    );
  }
}
