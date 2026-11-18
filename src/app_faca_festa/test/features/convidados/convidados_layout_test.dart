import 'package:app_faca_festa/presentation/modules/convidado/widgets/convidados_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 360.0, 420.0, 768.0, 1280.0, 1920.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Abas em $width px com escala $scale', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              padding: EdgeInsets.only(top: width < 600 ? 33 : 0),
            ),
            child: child!,
          ),
          home: DefaultTabController(
            length: 5,
            child: Builder(builder: (context) {
              return Scaffold(
                appBar: FestaAppBar(
                  titulo: 'Convidados',
                  altura: 52,
                  automaticamenteImplyLeading: false,
                  bottom: ConvidadosTabBar(
                    controller: DefaultTabController.of(context),
                    primary: Colors.deepPurple,
                  ),
                ),
                body: const ConvidadosContent(
                  child: TabBarView(children: [
                    Text('Conteúdo 0'),
                    Text('Conteúdo 1'),
                    Text('Conteúdo 2'),
                    Text('Conteúdo 3'),
                    Text('Conteúdo 4'),
                  ]),
                ),
              );
            }),
          ),
        ));
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(TabBarView)).width,
            width.clamp(0, ConvidadosContent.maxWidth));
        expect(
            tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isFalse);
        final barra = tester.getRect(find.byType(TabBar));
        for (final titulo in [
          'Lista',
          'Grupos',
          'Cardápio',
          'Mesas',
          'Status'
        ]) {
          final texto = tester.getRect(find.text(titulo));
          expect(texto.left, greaterThanOrEqualTo(barra.left));
          expect(texto.right, lessThanOrEqualTo(barra.right));
          expect(texto.top, greaterThanOrEqualTo(barra.top));
          expect(texto.bottom, lessThanOrEqualTo(barra.bottom));
          expect(find.text(titulo).hitTestable(), findsOneWidget);
        }
        for (final index in [1, 2, 3, 4, 0]) {
          final titulo =
              ['Lista', 'Grupos', 'Cardápio', 'Mesas', 'Status'][index];
          await tester.tap(find.text(titulo));
          await tester.pumpAndSettle();
          expect(find.text('Conteúdo $index'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
