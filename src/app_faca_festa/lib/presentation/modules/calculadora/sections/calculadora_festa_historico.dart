part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaHistorico on _CalculadoraFestaScreenState {
  Widget _buildSimulacoesCard(Color primary) {
    return _SectionCard(
      title: 'Simulações salvas',
      icon: Icons.history_rounded,
      primary: primary,
      trailing: Obx(() {
        final total = calculadoraController.simulacoesSalvas.length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            total.toString(),
            style: GoogleFonts.poppins(
              color: primary,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        );
      }),
      child: SizedBox(
        width: double.infinity,
        height: 38, // Botão mais compacto
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary.withValues(alpha: 0.45)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.zero,
          ),
          onPressed: _abrirMinhasSimulacoes,
          icon: Icon(Icons.auto_awesome_motion_rounded,
              size: 18, color: primary),
          label: Text(
            'Abrir minhas simulações',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
