import 'package:flutter/material.dart';

/// Abaixo disso o rótulo ficaria pequeno demais para o zoom escolhido
/// e a grade precisa de mais largura.
const double fatorRotuloMinimo = 0.74;

/// Nome curto que permanece inteiro. Se não couber, encolhe só o bastante
/// para a última letra não cair sozinha na linha de baixo.
class RotuloInteiro extends StatelessWidget {
  const RotuloInteiro(
    this.texto, {
    super.key,
    required this.style,
    this.alinhamento = TextAlign.start,
    this.tamanhoVisual,
  });

  final String texto;
  final TextStyle style;
  final TextAlign alinhamento;

  /// Pixels de pintura já resolvidos. Nulo segue o [TextScaler] do contexto.
  final double? tamanhoVisual;

  static double largura(
    BuildContext context,
    String texto,
    TextStyle style, {
    double? tamanhoVisual,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: _estilo(style, tamanhoVisual),
      ),
      textDirection: Directionality.of(context),
      textScaler: tamanhoVisual == null
          ? MediaQuery.textScalerOf(context)
          : TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final medida = painter.width;
    painter.dispose();
    return medida;
  }

  /// O zoom já passou do que a coluna aguenta sem esmagar o nome.
  static bool pedeMaisLargura({
    required double natural,
    required double disponivel,
  }) {
    if (disponivel <= 0) return true;
    return natural > disponivel / fatorRotuloMinimo;
  }

  /// Tamanho único do grupo, para o nome longo e os curtos continuarem iguais.
  /// Nulo quando o texto já cabe, ou quando [pedeMaisLargura] é verdadeiro.
  static double? tamanhoCompartilhado({
    required double larguraNatural,
    required double disponivel,
    required double tamanhoVisual,
  }) {
    if (disponivel <= 0 || larguraNatural <= disponivel) return null;
    final fator = disponivel / larguraNatural;
    if (fator < fatorRotuloMinimo) return null;
    // Folga de 2% para o último glifo não encostar na borda e ser cortado.
    return tamanhoVisual * fator * 0.98;
  }

  static TextStyle _estilo(TextStyle style, double? tamanhoVisual) {
    if (tamanhoVisual == null) return style;
    return style.copyWith(fontSize: tamanhoVisual);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final limite = constraints.maxWidth;
        final natural = largura(
          context,
          texto,
          style,
          tamanhoVisual: tamanhoVisual,
        );
        final cabe = !limite.isFinite || limite <= 0 || natural <= limite + 0.5;
        final visual = tamanhoVisual ??
            MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14);
        final tamanho = cabe ? visual : visual * (limite / natural) * 0.98;
        final herdaEscala = tamanhoVisual == null && cabe;
        return Text(
          texto,
          style:
              style.copyWith(fontSize: herdaEscala ? style.fontSize : tamanho),
          textAlign: alinhamento,
          textScaler: herdaEscala ? null : TextScaler.noScaling,
          maxLines: 1,
          softWrap: false,
        );
      },
    );
  }
}
