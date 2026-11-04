import 'package:flutter/material.dart';

/// Mantém o cartão navegável sem interceptar suas ações de resposta e IA.
class AcessoAtendimento extends StatelessWidget {
  const AcessoAtendimento({
    super.key,
    required this.onAbrir,
    required this.child,
  });

  final VoidCallback onAbrir;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAbrir,
          borderRadius: BorderRadius.circular(18),
          child: child,
        ),
      );
}
