import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_scaffold.dart';

void main() {
  for (final brilho in Brightness.values) {
    for (final largura in [360.0, 1366.0]) {
      testWidgets('voltar tem contraste e retorna em $brilho / $largura',
          (t) async {
        await t.binding.setSurfaceSize(Size(largura, 800));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final scheme =
            ColorScheme.fromSeed(seedColor: Colors.teal, brightness: brilho);
        await t.pumpWidget(MaterialApp(
            theme: ThemeData(
                colorScheme: scheme,
                appBarTheme: const AppBarTheme(
                    iconTheme: IconThemeData(color: Colors.white),
                    actionsIconTheme: IconThemeData(color: Colors.white))),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const OperacaoScaffold(
                                    title: 'Agenda e capacidade',
                                    body: SizedBox()))),
                        child: const Text('Abrir'))))));
        await t.tap(find.text('Abrir'));
        await t.pumpAndSettle();
        final voltar = find.byType(BackButton);
        expect(voltar, findsOneWidget);
        final iconContext = t.element(
            find.descendant(of: voltar, matching: find.byType(Icon)).first);
        expect(IconTheme.of(iconContext).color, scheme.onSurface);
        final fundo = t.widget<AppBar>(find.byType(AppBar));
        final appBarTheme =
            Theme.of(t.element(find.byType(AppBar))).appBarTheme;
        final corFundo = fundo.backgroundColor ?? appBarTheme.backgroundColor!;
        final l1 = scheme.onSurface.computeLuminance(),
            l2 = corFundo.computeLuminance();
        final contraste =
            ((l1 > l2 ? l1 : l2) + .05) / ((l1 < l2 ? l1 : l2) + .05);
        expect(contraste, greaterThanOrEqualTo(4.5));
        expect(appBarTheme.actionsIconTheme!.color, scheme.onSurface);
        await t.tap(voltar);
        await t.pumpAndSettle();
        expect(find.text('Abrir'), findsOneWidget);
        expect(find.text('Agenda e capacidade'), findsNothing);
        expect(t.takeException(), isNull);
      });
    }
  }
}
