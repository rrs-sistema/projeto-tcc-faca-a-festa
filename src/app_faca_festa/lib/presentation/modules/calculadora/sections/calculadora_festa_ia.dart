part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaIa on _CalculadoraFestaScreenState {
  Widget _buildAssistenteIACard(Color primary) {
    final analisando = calculadoraController.analisandoIA.value;
    final analise = calculadoraController.analiseIA.value;

    return _SectionCard(
      title: 'Assistente IA',
      icon: Icons.auto_awesome_rounded,
      primary: primary,
      trailing: analisando
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            )
          : _MiniBadge(
              label: (calculadoraController.estimativaIncompleta ||
                      calculadoraController.coberturaFinanceiraIncompleta)
                  ? 'Estimativa parcial'
                  : analise?.statusOrcamento ?? 'Pronta',
              color:
                  analise?.acimaDoOrcamento == true ? Colors.orange : primary,
            ),
      child: calculadoraController.erroAnaliseIA.value.isNotEmpty
          ? Column(children: [
              Text(calculadoraController.erroAnaliseIA.value),
              TextButton(
                  onPressed: calculadoraController.tentarAnaliseIA,
                  child: const Text('Tentar análise novamente')),
            ])
          : analisando && analise == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analisando sua simulação...',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: primary,
                        backgroundColor: primary.withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (analise != null) Text(analise.fonteLabel),
                  _AnaliseIACompacta(
                    analise: analise,
                    primary: primary,
                    onDetalhes: analise == null
                        ? null
                        : () => _abrirDetalhesIA(analise),
                  ),
                  if (analise != null)
                    for (final sugestao in analise.sugestoes)
                      for (final item in calculadoraController.itensCalculados
                          .where((item) =>
                              sugestao.itemRelacionado != null &&
                              RevisaoCardapioService.normalizar(item.nome) ==
                                  RevisaoCardapioService.normalizar(
                                      sugestao.itemRelacionado!)))
                        TextButton.icon(
                            onPressed: () => _abrirDetalhesItem(item),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                                'Revisar ${item.nome}: ${sugestao.titulo}')),
                ]),
    );
  }

  Future<void> _abrirDetalhesIA(AnaliseCalculadoraIA analise) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnaliseIADetalhesSheet(
        analise: analise,
        primary: themeController.primaryColor.value,
      ),
    );
  }
}
