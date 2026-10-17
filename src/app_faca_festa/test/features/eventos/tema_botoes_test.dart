import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final primary in [Colors.green.shade800, Colors.yellow.shade200]) {
    testWidgets('ícones seguem o texto dos botões no tema $primary',
        (tester) async {
      final theme = EventThemeController.montarThemeData(primary, Colors.white);
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
            body: Column(children: [
          ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Criar')),
          FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save),
              label: const Text('Salvar')),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text('Editar')),
          TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.close),
              label: const Text('Cancelar')),
        ])),
      ));
      expect(IconTheme.of(tester.element(find.byIcon(Icons.add))).color,
          theme.colorScheme.onPrimary);
      expect(IconTheme.of(tester.element(find.byIcon(Icons.save))).color,
          theme.colorScheme.onPrimary);
      expect(
          IconTheme.of(tester.element(find.byIcon(Icons.edit))).color, primary);
      expect(IconTheme.of(tester.element(find.byIcon(Icons.close))).color,
          primary);
    });
  }
}
