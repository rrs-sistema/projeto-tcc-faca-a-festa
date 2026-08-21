import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/tema/event_theme_controller.dart';

/// Contraste da barra de status (hora, sinal, bateria).
/// Android: [SystemUiOverlayStyle.statusBarIconBrightness]
/// iOS: [SystemUiOverlayStyle.statusBarBrightness] descreve o fundo.
abstract final class FestaSystemUi {
  static const fundoEscuro = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  static const fundoClaro = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  /// Barra de status pintada com a cor do tema do evento.
  static SystemUiOverlayStyle sobreCor(
    Color fundo, {
    required bool iconesClaros,
  }) {
    return SystemUiOverlayStyle(
      statusBarColor: fundo,
      statusBarIconBrightness:
          iconesClaros ? Brightness.light : Brightness.dark,
      statusBarBrightness: iconesClaros ? Brightness.dark : Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }
}

/// ===============================================================
/// 🎀 APP BAR TEMATIZADA - "FAÇA A FESTA"
/// ---------------------------------------------------------------
/// - Integra com o tema atual (gradiente, cores, ícone)
/// - Suporte a blur de fundo e título com fonte Poppins estilizada
/// - Reutilizável em qualquer tela
/// ===============================================================
class FestaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final bool automaticamenteImplyLeading;
  final List<Widget>? acoes;
  final double altura;
  final Widget? tituloExtra;
  final PreferredSizeWidget? bottom;

  const FestaAppBar({
    super.key,
    required this.titulo,
    this.automaticamenteImplyLeading = true,
    this.acoes,
    this.altura = 65,
    this.tituloExtra,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(altura);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<EventThemeController>();
    final gradiente = themeController.gradient.value;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoEscuro,
      child: ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: Stack(
        children: [
          // 🔹 Fundo com gradiente e blur sutil
          Container(
            decoration: BoxDecoration(
              gradient: gradiente,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.white.withValues(alpha: 0.05)),
          ),

          // 🔹 AppBar principal
          AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: Colors.transparent,
            systemOverlayStyle: FestaSystemUi.fundoEscuro,
            centerTitle: true,
            titleSpacing: 0,
            title: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top / 2), // 👈 dá espaço no topo
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  if (tituloExtra != null) tituloExtra!,
                ],
              ),
            ),
            leading: automaticamenteImplyLeading
                ? Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top / 3),
                    child: IconButton(
                      tooltip: 'Voltar',
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      onPressed: () => Get.back(),
                    ),
                  )
                : null,
            actions: acoes
                ?.map(
                  (a) => Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top / 3),
                    child: a,
                  ),
                )
                .toList(),
            bottom: bottom,
          ),

          // ✨ Detalhe decorativo inferior (brilho sutil)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
