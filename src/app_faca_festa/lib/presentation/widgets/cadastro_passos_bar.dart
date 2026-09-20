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
    this.carregando = false,
  });

  final Color cor;
  final String continuarLabel;
  final VoidCallback onContinuar;
  final VoidCallback? onVoltar;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onVoltar != null) ...[
          SizedBox(
            height: 48,
            width: 112,
            child: OutlinedButton(
              onPressed: carregando ? null : onVoltar,
              style: OutlinedButton.styleFrom(
                foregroundColor: cor,
                side: BorderSide(color: cor.withValues(alpha: 0.45)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Voltar',
                maxLines: 1,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: carregando ? null : onContinuar,
              style: ElevatedButton.styleFrom(
                backgroundColor: cor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: carregando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      continuarLabel,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
