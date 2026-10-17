import 'package:flutter/material.dart';

/// Mesma hierarquia, alvos de toque e área de ações nos formulários da calculadora.
class CalculadoraModal extends StatelessWidget {
  const CalculadoraModal(
      {super.key,
      required this.titulo,
      required this.icone,
      required this.child,
      this.subtitulo,
      this.rodape,
      this.onFechar,
      this.onVoltar,
      this.ocupado = false});
  final String titulo;
  final String? subtitulo;
  final IconData icone;
  final Widget child;
  final Widget? rodape;
  final VoidCallback? onFechar, onVoltar;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cor = tema.colorScheme.primary;
    return Theme(
        data: tema.copyWith(
          textTheme: tema.textTheme.apply(
              bodyColor: const Color(0xFF192E25),
              displayColor: const Color(0xFF192E25)),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  backgroundColor: cor,
                  foregroundColor: tema.colorScheme.onPrimary,
                  minimumSize: const Size(48, 48),
                  textStyle: tema.textTheme.labelLarge
                      ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: cor, minimumSize: const Size(48, 48))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  foregroundColor: cor,
                  minimumSize: const Size(48, 48),
                  side: BorderSide(color: cor.withValues(alpha: .35)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))),
          switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? tema.colorScheme.onPrimary
                      : const Color(0xFF738178)),
              trackColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? cor
                      : const Color(0xFFE4EAE6))),
        ),
        child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 620, maxHeight: 820),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                      child: Row(children: [
                        if (onVoltar != null)
                          IconButton(
                              tooltip: 'Voltar ao estoque',
                              onPressed: ocupado ? null : onVoltar,
                              icon: const Icon(Icons.arrow_back_rounded))
                        else
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: cor.withValues(alpha: .09),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(icone, size: 22, color: cor)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(titulo,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25)),
                              if (subtitulo != null) ...[
                                const SizedBox(height: 3),
                                Text(subtitulo!,
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF5B6B63)))
                              ]
                            ])),
                        if (onFechar != null)
                          IconButton(
                              tooltip: 'Fechar',
                              onPressed: ocupado ? null : onFechar,
                              icon: const Icon(Icons.close_rounded, size: 22)),
                      ])),
                  const Divider(height: 1, color: Color(0xFFEDF1EE)),
                  Flexible(
                      child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(16),
                          child: child)),
                  if (rodape != null)
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                            color: Color(0xFFFAFCFA),
                            border: Border(
                                top: BorderSide(color: Color(0xFFEDF1EE)))),
                        child: rodape),
                ]))));
  }
}
