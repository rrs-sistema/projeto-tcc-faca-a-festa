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

  testWidgets('não estoura em celular baixo com os cards de papel',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthFestaShell(
            title: 'Como você quer participar?',
            titleHighlight: 'participar?',
            subtitle: 'Escolha como deseja participar',
            footerLink: AuthFestaFooterLink(
              prefixo: 'Já tem uma conta? ',
              acao: 'Entrar aqui',
              onTap: () {},
            ),
            child: Column(
              children: List.generate(
                2,
                (_) => Container(
                  height: 108,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthFestaCredits), findsOneWidget);
  });

  testWidgets('esconde prova social e créditos quando a tela pede',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuthFestaShell(
            title: 'Como você quer participar?',
            titleHighlight: 'participar?',
            mostrarProvaSocial: false,
            mostrarCreditos: false,
            child: const Text('escolha'),
          ),
        ),
      ),
    );

    expect(find.text('+12.000 eventos realizados'), findsNothing);
    expect(find.text('4.9'), findsNothing);
    expect(find.byType(AuthFestaCredits), findsNothing);
    expect(find.text('ou'), findsNothing);
    expect(find.text('escolha'), findsOneWidget);
  });

  testWidgets('mostra só a política quando a tela pede privacidade sem créditos',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthFestaShell(
            title: 'Entre e faça a festa',
            mostrarProvaSocial: false,
            mostrarCreditos: false,
            mostrarPrivacidade: true,
            logoSize: 168,
            child: Text('login'),
          ),
        ),
      ),
    );

    expect(find.text('+12.000 eventos realizados'), findsNothing);
    expect(find.byType(AuthFestaCredits), findsNothing);
    expect(find.text('Política de privacidade'), findsOneWidget);
    expect(find.text('login'), findsOneWidget);
  });
}
