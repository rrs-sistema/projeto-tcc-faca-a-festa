import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/widgets/splash.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390)
  ]) {
    testWidgets('entrada sem overflow em $size com texto ampliado',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(
            size: size, textScaler: const TextScaler.linear(1.3)),
        child: const SplashPresentation(status: 'Abrindo seu convite…'),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Abrindo seu convite…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      final background =
          tester.getRect(find.byKey(const ValueKey('splash-background')));
      expect(background.left, 0);
      expect(background.width, size.width);
      expect(background.height, size.height);
      final logo = tester.getRect(find.byKey(const ValueKey('splash-logo')));
      expect(logo.center.dx, closeTo(size.width / 2, .5));
      expect(tester.getCenter(find.text('Sua festa\ncomeça aqui.')).dx,
          closeTo(size.width / 2, .5));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
