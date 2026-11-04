import 'package:flutter/material.dart';

/// Superfície compartilhada da operação, respeitando o tema do aplicativo.
class OperacaoSurface extends StatelessWidget {
  const OperacaoSurface({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: .12)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .025),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ]),
      child: child);
}

class OperacaoHeading extends StatelessWidget {
  const OperacaoHeading(
      {super.key,
      required this.title,
      required this.icon,
      this.subtitle,
      this.trailing});
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), cor = theme.colorScheme.primary;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
              color: cor.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: cor, size: 22)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -.4)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5))
        ]
      ])),
      if (trailing != null) ...[const SizedBox(width: 8), trailing!]
    ]);
  }
}

class OperacaoAviso extends StatelessWidget {
  const OperacaoAviso(
      {super.key,
      required this.texto,
      this.titulo,
      this.acao,
      this.label = 'Tentar novamente'});
  final String texto, label;
  final String? titulo;
  final VoidCallback? acao;
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: true,
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: .025),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: .12))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.cloud_off_outlined,
                  size: 22, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (titulo != null) ...[
                      Text(titulo!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4)
                    ],
                    Text(texto,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.5,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant))
                  ]))
            ]),
            if (acao != null)
              Padding(
                  padding: const EdgeInsets.only(left: 26, top: 4),
                  child: TextButton(onPressed: acao, child: Text(label)))
          ])));
}
