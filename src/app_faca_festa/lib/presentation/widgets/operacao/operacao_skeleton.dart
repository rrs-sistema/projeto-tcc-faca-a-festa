import 'package:flutter/material.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';

/// Cartão de carregamento com a mesma pulsação e paleta do Financeiro.
/// Os títulos permanecem visíveis; os blocos representam dados ainda em consulta.
class OperacaoSkeleton extends StatefulWidget {
  const OperacaoSkeleton({
    super.key,
    required this.titulo,
    required this.icon,
    this.linhas = 3,
  });

  final String titulo;
  final IconData icon;
  final int linhas;

  @override
  State<OperacaoSkeleton> createState() => _OperacaoSkeletonState();
}

class _OperacaoSkeletonState extends State<OperacaoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = .5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      container: true,
      label: 'Carregando ${widget.titulo}',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: dark
                  ? Theme.of(context).dividerColor
                  : FornecedorPremiumPalette.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        FornecedorPremiumPalette.primary.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon,
                      size: 20, color: FornecedorPremiumPalette.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.titulo,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Text('Carregando...',
                        style: TextStyle(
                            fontSize: 12,
                            color: FornecedorPremiumPalette.muted)),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  Widget bloco(double width, double height) => Container(
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          color: FornecedorPremiumPalette.primary
                              .withValues(alpha: .08 + _pulse.value * .10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                  return LayoutBuilder(
                      builder: (context, constraints) => Column(
                            children: [
                              for (var i = 0; i < widget.linhas; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                      bottom: i == widget.linhas - 1 ? 0 : 18),
                                  child: Row(children: [
                                    Expanded(
                                        child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        bloco(constraints.maxWidth * .46, 14),
                                        const SizedBox(height: 6),
                                        bloco(constraints.maxWidth * .32, 11),
                                      ],
                                    )),
                                    bloco(constraints.maxWidth * .18, 16),
                                  ]),
                                ),
                            ],
                          ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
