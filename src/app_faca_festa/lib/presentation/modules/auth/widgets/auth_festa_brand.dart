import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/presentation/modules/legal/pages/privacidade_screen.dart';

/// Visual compartilhado das telas públicas (papel e login),
/// alinhado ao mock de entrada com prova social.
abstract final class AuthFestaBrand {
  static const Color rosa = Color(0xFFE91E8C);
  static const Color rosaIcone = Color(0xFFFF2D7B);
  static const Color roxoIcone = Color(0xFF8B5CF6);
  static const Color titulo = Color(0xFF111827);
  static const Color tituloDestaque = Color(0xFFC44ED8);
  static const LinearGradient tituloDestaqueDegrade = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFC44ED8),
      Color(0xFF8B5CF6),
      Color(0xFF6B7BFF),
    ],
  );
  static const Color muted = Color(0xFF8B919A);
  static const Color estrela = Color(0xFFF5B942);

  static const LinearGradient fundo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF3F8),
      Color(0xFFF8EEFF),
      Color(0xFFF4F7FF),
    ],
  );

  static const List<Color> avataresProva = [
    Color(0xFFFF8A7A),
    Color(0xFF7EE0C8),
    Color(0xFFC6E85A),
  ];
}

class AuthFestaCard extends StatelessWidget {
  const AuthFestaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111827).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthFestaShell extends StatelessWidget {
  const AuthFestaShell({
    super.key,
    required this.child,
    this.title,
    this.titleHighlight,
    this.subtitle,
    this.footerLink,
    this.scrollable = false,
  });

  final Widget child;
  final String? title;
  final String? titleHighlight;
  final String? subtitle;
  final Widget? footerLink;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AuthFestaBrand.fundo),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
              child: Column(
                children: [
                  if (!scrollable) const Spacer(flex: 2),
                  const AuthFestaLogo(),
                  if (title != null) ...[
                    const SizedBox(height: 10),
                    AuthFestaTitle(
                      text: title!,
                      highlight: titleHighlight,
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.25,
                        color: AuthFestaBrand.muted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  child,
                  if (!scrollable) const Spacer(flex: 2),
                  if (scrollable) const SizedBox(height: 20),
                  const AuthFestaSocialProof(),
                  if (footerLink != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'ou',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFC4C7CC),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    footerLink!,
                    const SizedBox(height: 8),
                    const AuthFestaDots(),
                  ],
                  const SizedBox(height: 10),
                  const AuthFestaCredits(),
                  if (!scrollable) const Spacer(flex: 1),
                ],
              ),
            );

            if (scrollable) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: content,
              );
            }

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: content,
            );
          },
        ),
      ),
    );
  }
}

class AuthFestaLogo extends StatelessWidget {
  const AuthFestaLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/logo/logo-faca-festa.png',
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Text(
          'Faça a Festa',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AuthFestaBrand.rosa,
          ),
        ),
      ),
    );
  }
}

class AuthFestaTitle extends StatelessWidget {
  const AuthFestaTitle({
    super.key,
    required this.text,
    this.highlight,
  });

  final String text;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final highlightText = highlight;
    final base = GoogleFonts.poppins(
      fontSize: 24,
      height: 1.08,
      fontWeight: FontWeight.w800,
      color: AuthFestaBrand.titulo,
    );

    if (highlightText == null || !text.contains(highlightText)) {
      return Text(text, textAlign: TextAlign.center, style: base);
    }

    final index = text.indexOf(highlightText);
    final prefix = text.substring(0, index).trimRight();
    final marked = highlightText + text.substring(index + highlightText.length);

    return Column(
      children: [
        if (prefix.isNotEmpty)
          Text(prefix, textAlign: TextAlign.center, style: base),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              AuthFestaBrand.tituloDestaqueDegrade.createShader(bounds),
          child: Text(
            marked,
            textAlign: TextAlign.center,
            style: base.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class AuthFestaSocialProof extends StatelessWidget {
  const AuthFestaSocialProof({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = GoogleFonts.poppins(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF4B5563),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 52,
          height: 22,
          child: Stack(
            children: [
              for (var i = 0; i < AuthFestaBrand.avataresProva.length; i++)
                Positioned(
                  left: i * 14.0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AuthFestaBrand.avataresProva[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text('+12.000 eventos realizados', style: texto),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 16,
              color: AuthFestaBrand.estrela,
            ),
            const SizedBox(width: 2),
            Text('4.9', style: texto.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class AuthFestaDots extends StatelessWidget {
  const AuthFestaDots({super.key});

  @override
  Widget build(BuildContext context) {
    const cores = [
      Color(0xFFFF80AB),
      Color(0xFFCE93D8),
      Color(0xFF81D4FA),
      Color(0xFFA5D6A7),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final cor in cores) ...[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          if (cor != cores.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class AuthFestaCredits extends StatelessWidget {
  const AuthFestaCredits({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF81D4FA),
              Color(0xFFCE93D8),
              Color(0xFFFF80AB),
            ],
          ).createShader(bounds),
          child: Text(
            'by Jullia A. · Nicolas B. · Rivaldo R.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '© ${DateTime.now().year} Faça a Festa',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFFC4C7CC),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(PrivacidadeScreen.rota());
          },
          child: Text(
            'Política de privacidade',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthFestaBrand.rosa,
              decoration: TextDecoration.underline,
              decorationColor: AuthFestaBrand.rosa,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthFestaFooterLink extends StatelessWidget {
  const AuthFestaFooterLink({
    super.key,
    required this.prefixo,
    required this.acao,
    required this.onTap,
  });

  final String prefixo;
  final String acao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          text: prefixo,
          style: GoogleFonts.poppins(
            color: const Color(0xFF6B7280),
            fontSize: 13.5,
          ),
          children: [
            TextSpan(
              text: acao,
              style: GoogleFonts.poppins(
                color: AuthFestaBrand.rosa,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
