import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Posiciona a barra junto ao conteúdo centralizado, sem a barra automática
/// que o Flutter adiciona na borda da janela no desktop.
class FestaScrollArea extends StatefulWidget {
  const FestaScrollArea({
    super.key,
    this.controller,
    required this.color,
    required this.child,
    this.maxWidth = 1360,
    this.scrollDirection = Axis.vertical,
    this.contentPadding,
  });

  static double sideInset(double width, {double maxWidth = 1360}) =>
      width > maxWidth ? (width - maxWidth) / 2 : 0;

  final ScrollController? controller;
  final Color color;
  final Widget child;
  final double maxWidth;
  final Axis scrollDirection;

  /// Permite preservar a geometria de tabelas que já reservam o próprio trilho.
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<FestaScrollArea> createState() => _FestaScrollAreaState();
}

class _FestaScrollAreaState extends State<FestaScrollArea> {
  final _ownedController = ScrollController();

  @override
  void dispose() {
    _ownedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: LayoutBuilder(builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 650;
          final horizontal = widget.scrollDirection == Axis.horizontal;
          final behavior = ScrollConfiguration.of(context);
          return ScrollConfiguration(
            behavior: behavior.copyWith(
              scrollbars: false,
              dragDevices: horizontal
                  ? {...behavior.dragDevices, PointerDeviceKind.mouse}
                  : behavior.dragDevices,
            ),
            child: RawScrollbar(
              controller: widget.controller ?? _ownedController,
              thumbVisibility: desktop,
              trackVisibility: desktop,
              scrollbarOrientation:
                  horizontal ? ScrollbarOrientation.bottom : null,
              interactive: desktop,
              thickness: desktop ? 8 : 3,
              // O Scaffold já trata a área segura do dispositivo. Herdar esse
              // inset aqui desloca a barra horizontal para cima dos cards.
              padding: EdgeInsets.zero,
              radius: const Radius.circular(12),
              trackRadius: const Radius.circular(12),
              thumbColor: widget.color,
              trackColor: widget.color.withValues(alpha: 0.08),
              trackBorderColor: Colors.transparent,
              crossAxisMargin: 2,
              mainAxisMargin: 8,
              notificationPredicate: (notification) =>
                  notification.depth == 0 &&
                  notification.metrics.axis == widget.scrollDirection,
              child: PrimaryScrollController(
                controller: widget.controller ?? _ownedController,
                automaticallyInheritForPlatforms: const <TargetPlatform>{},
                child: Padding(
                  padding: widget.contentPadding ??
                      (horizontal
                          ? const EdgeInsets.only(bottom: 14)
                          : EdgeInsets.only(right: desktop ? 14 : 0)),
                  child: widget.child,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Alinha cabeçalhos e ações fixas à largura da área de rolagem.
class FestaContent extends StatelessWidget {
  const FestaContent({super.key, required this.child, this.maxWidth = 1360});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );
}
