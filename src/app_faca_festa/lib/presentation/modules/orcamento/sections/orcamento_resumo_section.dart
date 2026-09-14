part of '../pages/orcamento_screen.dart';

Widget resumoCard(
  LinearGradient gradient, {
  required double custoEstimado,
  required double custoFinal,
}) {
  final percent =
      (custoEstimado > 0) ? (custoFinal / custoEstimado).clamp(0.0, 1.0) : 0.0;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4)),
      ],
    ),
    child: Row(
      children: [
        CircularPercentIndicator(
          radius: 34,
          lineWidth: 5,
          percent: percent,
          animation: true,
          circularStrokeCap: CircularStrokeCap.round,
          linearGradient: LinearGradient(
            colors: [gradient.colors.first, gradient.colors.last],
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumo Financeiro',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const SizedBox(height: 6),
              _infoBoxResumo(
                  'Estimado:',
                  'R\$ ${Biblioteca.formatarValorDecimal(custoEstimado)}',
                  Icons.savings_rounded,
                  Colors.white),
              const SizedBox(height: 4),
              _infoBoxResumo(
                  'Final:',
                  'R\$ ${Biblioteca.formatarValorDecimal(custoFinal)}',
                  Icons.stacked_bar_chart_rounded,
                  Colors.white),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _infoBoxResumo(String label, String value, IconData icon, Color color) {
  return Row(
    children: [
      Icon(icon, color: color.withValues(alpha: 0.8), size: 14),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 11,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500),
      ),
      const Spacer(),
      Text(
        value,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
      ),
    ],
  );
}
