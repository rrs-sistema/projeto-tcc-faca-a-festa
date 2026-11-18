import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'preferencias_leitura.dart';

/// Compõe largura da janela, acessibilidade do sistema e escolha de leitura.
class EscalaTextoFesta extends TextScaler {
  const EscalaTextoFesta({
    required this.sistema,
    required this.largura,
    this.leitura = 1,
  });

  final TextScaler sistema;
  final double largura;
  final double leitura;

  @override
  double scale(double fontSize) {
    if (fontSize <= 0) return sistema.scale(fontSize);
    final adaptacao = ((largura - 600) / 600).clamp(0.0, 1.0);
    final base = fontSize < 16 ? math.max(10.0, fontSize + 1) : fontSize;
    final acrescimo = fontSize <= 16 ? 2.0 : 4.0;
    return sistema.scale(base + acrescimo * adaptacao) * leitura;
  }

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is EscalaTextoFesta &&
      other.sistema == sistema &&
      other.largura == largura &&
      other.leitura == leitura;

  @override
  int get hashCode => Object.hash(sistema, largura, leitura);
}

class FestaLeituraScope extends InheritedNotifier<PreferenciasLeitura> {
  const FestaLeituraScope({
    super.key,
    required PreferenciasLeitura preferencias,
    required super.child,
  }) : super(notifier: preferencias);

  static PreferenciasLeitura? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FestaLeituraScope>()?.notifier;
}

class FestaTipografia extends StatelessWidget {
  const FestaTipografia({
    super.key,
    required this.preferencias,
    required this.child,
  });

  final PreferenciasLeitura preferencias;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return FestaLeituraScope(
      preferencias: preferencias,
      child: AnimatedBuilder(
        animation: preferencias,
        child: child,
        builder: (context, child) => MediaQuery(
          data: media.copyWith(
            textScaler: EscalaTextoFesta(
              sistema: media.textScaler,
              largura: media.size.width,
              leitura: preferencias.escala,
            ),
          ),
          child: child!,
        ),
      ),
    );
  }
}

/// A navegação acompanha a janela e o sistema, mantendo a pinça no conteúdo.
class FestaTextoNavegacao extends StatelessWidget {
  const FestaTextoNavegacao({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final escala = media.textScaler;
    if (escala is! EscalaTextoFesta) return child;
    return MediaQuery(
      data: media.copyWith(
        textScaler: EscalaTextoFesta(
          sistema: escala.sistema,
          largura: escala.largura,
        ),
      ),
      child: child,
    );
  }
}
