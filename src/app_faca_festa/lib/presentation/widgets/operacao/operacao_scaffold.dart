import 'package:flutter/material.dart';

/// Moldura comum das páginas operacionais, sem alterar o tema global.
class OperacaoScaffold extends StatelessWidget {
  const OperacaoScaffold(
      {super.key, required this.title, required this.body, this.appBar});
  final String title;
  final Widget body;
  final PreferredSizeWidget? appBar;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        claro = Theme.of(context).brightness == Brightness.light;
    final fundo = claro ? const Color(0xFFF6F7FB) : t.colorScheme.surface;
    final superficie = claro ? Colors.white : t.colorScheme.surface;
    final borda = t.dividerColor.withValues(alpha: .14);
    return Theme(
        data: t.copyWith(
          scaffoldBackgroundColor: fundo,
          appBarTheme: t.appBarTheme.copyWith(
              backgroundColor: superficie,
              foregroundColor: t.colorScheme.onSurface,
              iconTheme: t.appBarTheme.iconTheme
                      ?.copyWith(color: t.colorScheme.onSurface) ??
                  IconThemeData(color: t.colorScheme.onSurface),
              actionsIconTheme: t.appBarTheme.actionsIconTheme
                      ?.copyWith(color: t.colorScheme.onSurface) ??
                  IconThemeData(color: t.colorScheme.onSurface),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0),
          cardTheme: CardTheme(
              color: superficie,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: borda))),
          inputDecorationTheme: t.inputDecorationTheme.copyWith(
              filled: true,
              fillColor: t.colorScheme.onSurface.withValues(alpha: .025),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borda))),
        ),
        child: Scaffold(
            appBar: appBar ??
                AppBar(
                    title: Text(title,
                        style: t.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700))),
            body: SafeArea(
                child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: body)))));
  }
}

/// Falha inicial de leitura, distinta de vazio ou ausência de registros.
class OperacaoFalha extends StatelessWidget {
  const OperacaoFalha(
      {super.key,
      required this.titulo,
      required this.mensagem,
      required this.onRetry});
  final String titulo, mensagem;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Semantics(
        liveRegion: true,
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: t.colorScheme.onSurface.withValues(alpha: .025),
                borderRadius: BorderRadius.circular(18),
                border:
                    Border.all(color: t.dividerColor.withValues(alpha: .12))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: t.colorScheme.primary.withValues(alpha: .08),
                          shape: BoxShape.circle),
                      child: Icon(Icons.cloud_off_outlined,
                          size: 30, color: t.colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text(titulo,
                      textAlign: TextAlign.center,
                      style: t.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Text(mensagem,
                          textAlign: TextAlign.center,
                          style: t.textTheme.bodyMedium?.copyWith(
                              color: t.colorScheme.onSurfaceVariant,
                              height: 1.5))),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'))
                ])));
  }
}
