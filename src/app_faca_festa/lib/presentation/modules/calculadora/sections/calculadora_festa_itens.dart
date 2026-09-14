part of '../pages/calculadora_festa_screen.dart';

extension _CalculadoraFestaItens on _CalculadoraFestaScreenState {
  Widget _buildResultadoCard(Color primary) {
    final itens = calculadoraController.itensCalculados;

    return _SectionCard(
      title: 'Sugestões',
      icon: Icons.insights_rounded,
      primary: primary,
      child: itens.isEmpty
          ? _EmptyMessage(
              icon: Icons.calculate_outlined,
              text: 'Informe convidados para calcular.',
              iconColor: primary,
            )
          : Column(
              children: itens
                  .map((item) =>
                      _ResultadoItemTile(item: item, primary: primary))
                  .toList(),
            ),
    );
  }
}
