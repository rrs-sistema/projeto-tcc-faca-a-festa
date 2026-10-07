part of '../pages/orcamento_screen.dart';

String _reais(double? valor) =>
    'R\$ ${Biblioteca.formatarValorDecimal(valor)}';

Widget resumoCard(
  LinearGradient gradient, {
  required double limite,
  required double previsto,
  required double pago,
}) {
  final temLimite = limite > 0;
  final estourou = temLimite && previsto > limite;
  final percentual =
      temLimite ? (previsto / limite).clamp(0.0, 1.0) : 0.0;
  final destaque = !temLimite
      ? previsto
      : estourou
          ? previsto - limite
          : limite - previsto;
  final titulo = !temLimite
      ? 'Sem limite'
      : estourou
          ? 'Acima do limite'
          : 'Ainda cabe';
  final apoio = temLimite ? 'Limite ${_reais(limite)}' : 'Defina o limite na festa';

  return Semantics(
    container: true,
    label:
        '$titulo ${_reais(destaque)}. $apoio. Previsto ${_reais(previsto)}. Pago ${_reais(pago)}.',
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _reais(destaque),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      apoio,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (temLimite) ...[
                const SizedBox(width: 12),
                Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 30,
                      lineWidth: 6,
                      percent: percentual,
                      animation: true,
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.28),
                      center: Text(
                        '${(percentual * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'previsto',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricaResumo('Previsto', _reais(previsto)),
              const SizedBox(width: 8),
              _metricaResumo('Pago', _reais(pago)),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _metricaResumo(String rotulo, String valor) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
