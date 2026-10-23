import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Indicador compacto de etapas em cadastros longos.
class CadastroPassosBar extends StatelessWidget {
  const CadastroPassosBar({
    super.key,
    required this.atual,
    required this.titulos,
    required this.cor,
  });

  final int atual;
  final List<String> titulos;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final total = titulos.length;
    final titulo = titulos[atual.clamp(0, total - 1)];

    return Semantics(
      label: 'Passo ${atual + 1} de $total, $titulo',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passo ${atual + 1} de $total · $titulo',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < total; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= atual ? cor : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CadastroPassosAcoes extends StatelessWidget {
  const CadastroPassosAcoes({
    super.key,
    required this.cor,
    required this.continuarLabel,
    required this.onContinuar,
    this.onVoltar,
    this.voltarLabel = 'Voltar',
    this.carregando = false,
    this.habilitado = true,
  });

  final Color cor;
  final String continuarLabel;
  final VoidCallback onContinuar;
  final VoidCallback? onVoltar;
  final String voltarLabel;
  final bool carregando;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final frente = cor.computeLuminance() > .179 ? Colors.black : Colors.white;
    final voltar = OutlinedButton(
        onPressed: carregando ? null : onVoltar,
        style: OutlinedButton.styleFrom(
            foregroundColor: cor,
            iconColor: cor,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(12)),
        child: Text(voltarLabel, textAlign: TextAlign.center));
    final continuar = ElevatedButton(
        onPressed: carregando || !habilitado ? null : onContinuar,
        style: ElevatedButton.styleFrom(
            backgroundColor: cor,
            foregroundColor: frente,
            iconColor: frente,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.all(12)),
        child: carregando
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: frente, strokeWidth: 2))
            : Text(continuarLabel, textAlign: TextAlign.center));
    return LayoutBuilder(builder: (context, limites) {
      if (limites.maxWidth < 360 ||
          MediaQuery.textScalerOf(context).scale(14) > 18) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              continuar,
              if (onVoltar != null) ...[const SizedBox(height: 8), voltar],
            ]);
      }
      return Row(children: [
        if (onVoltar != null) ...[voltar, const SizedBox(width: 10)],
        Expanded(child: continuar)
      ]);
    });
  }
}
