import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

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

/// Espaço padrão entre a [FestaAppBar] (com curva) e o título/conteúdo da página.
abstract final class FestaPageInsets {
  static const double belowAppBar = 24;
}

/// App bar tematizada com toolbar própria (Row), sem [AppBar].
/// O Material [NavigationToolbar] no trailing recebia constraints ≈ 1×1 quando
/// a altura preferida do Scaffold era consumida pelo padding da status bar.
///
/// O Scaffold reserva `preferredSize + statusBar`. Este widget precisa consumir
/// o inset superior; senão o título fica colado nos ícones da status bar.
class FestaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final bool automaticamenteImplyLeading;
  final List<Widget>? acoes;
  final double altura;
  final Widget? tituloExtra;
  final PreferredSizeWidget? bottom;
  final EventThemeController? themeController;
  final Gradient? gradient;

  const FestaAppBar({
    super.key,
    required this.titulo,
    this.automaticamenteImplyLeading = true,
    this.acoes,
    this.altura = 56,
    this.tituloExtra,
    this.bottom,
    this.themeController,
    this.gradient,
  });

  @override
  Size get preferredSize {
    final bottomH = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(altura + bottomH);
  }

  @override
  Widget build(BuildContext context) {
    final controller = themeController;
    if (controller != null) {
      return Obx(() => _buildBar(context, controller.gradient.value));
    }

    final fallbackGradient = gradient ??
        LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    return _buildBar(context, fallbackGradient);
  }

  Widget _buildBar(BuildContext context, Gradient gradiente) {
    final acoesList = acoes ?? const <Widget>[];
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FestaSystemUi.fundoEscuro,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: SizedBox(
            // Preenche o slot do Scaffold (preferredSize + padding.top).
            height: preferredSize.height + topInset,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(decoration: BoxDecoration(gradient: gradiente)),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: const ColoredBox(color: Color(0x0DFFFFFF)),
                ),
                Column(
                  children: [
                    SizedBox(height: topInset),
                    SizedBox(
                      height: altura,
                      width: double.infinity,
                      child: IconTheme(
                        data: const IconThemeData(
                          color: Colors.white,
                          size: 24,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 56,
                              child: automaticamenteImplyLeading
                                  ? IconButton(
                                      tooltip: 'Voltar',
                                      icon: Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                      ),
                                      onPressed: () => Get.back(),
                                    )
                                  : null,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                      height: 1.15,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.28),
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
                            if (acoesList.isEmpty)
                              const SizedBox(width: 56)
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: acoesList,
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (bottom != null) bottom!,
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: IgnorePointer(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
