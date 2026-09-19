import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/presentation/modules/auth/widgets/auth_festa_brand.dart';

void main() {
  testWidgets('mostra prova social e destaque do mock de entrada',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthFestaShell(
            title: 'Como você quer participar?',
            titleHighlight: 'participar?',
            subtitle: 'Escolha como deseja participar do evento',
            footerLink: AuthFestaFooterLink(
              prefixo: 'Já tem uma conta? ',
              acao: 'Entrar aqui',
              onTap: () {},
            ),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.textContaining('participar?'), findsWidgets);
    expect(find.text('+12.000 eventos realizados'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.byType(AuthFestaFooterLink), findsOneWidget);
    expect(find.textContaining('Entrar aqui'), findsOneWidget);
    expect(find.text('ou'), findsOneWidget);
  });
}
