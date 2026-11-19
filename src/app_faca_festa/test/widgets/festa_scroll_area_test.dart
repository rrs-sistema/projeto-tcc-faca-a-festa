import 'package:app_faca_festa/presentation/widgets/festa_scroll_area.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Tabela mantém altura e controles de rolagem independentes',
      (tester) async {
    tester.view.physicalSize = const Size(1366, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final horizontal = ScrollController();
    final vertical = ScrollController();
    addTearDown(horizontal.dispose);
    addTearDown(vertical.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FestaContent(
          child: LayoutBuilder(builder: (context, constraints) {
            return FestaScrollArea(
              controller: horizontal,
              color: Colors.teal,
              scrollDirection: Axis.horizontal,
              contentPadding: EdgeInsets.zero,
              child: SingleChildScrollView(
                controller: horizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 1600,
                  height: constraints.maxHeight,
                  child: Column(children: [
                    const Text('Cabeçalho fixo'),
                    Expanded(
                      child: FestaScrollArea(
                        controller: vertical,
                        color: Colors.teal,
                        contentPadding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          controller: vertical,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Serviço')),
                              DataColumn(label: Text('Situação')),
                            ],
                            rows: List.generate(
                                40,
                                (index) => DataRow(cells: [
                                      DataCell(Text('Serviço $index')),
                                      const DataCell(Text('Ativo')),
                                    ])),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(horizontal.position.maxScrollExtent, greaterThan(0));
    expect(vertical.position.maxScrollExtent, greaterThan(0));
    horizontal.jumpTo(100);
    vertical.jumpTo(200);
    await tester.pumpAndSettle();
    expect(horizontal.offset, 100);
    expect(vertical.offset, 200);
    expect(find.text('Cabeçalho fixo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1920.0]) {
    testWidgets('Barras horizontal e vertical independentes em $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Future<void> render(Color color) => tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                platform: width < 650
                    ? TargetPlatform.android
                    : TargetPlatform.windows),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(bottom: width < 650 ? 64 : 0),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: FestaScrollArea(
                color: color,
                child: SingleChildScrollView(
                  primary: true,
                  child: Column(children: [
                    SizedBox(
                      height: 114,
                      child: FestaScrollArea(
                        color: color,
                        scrollDirection: Axis.horizontal,
                        child: ListView.builder(
                          primary: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: 30,
                          itemExtent: 120,
                          itemBuilder: (_, index) => Text('Fornecedor $index'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1800),
                  ]),
                ),
              ),
            ),
          ));

      await render(Colors.green);
      await tester.pumpAndSettle();
      expect(find.byType(RawScrollbar), findsNWidgets(2));
      final horizontal = find.byWidgetPredicate((widget) =>
          widget is RawScrollbar &&
          widget.scrollbarOrientation == ScrollbarOrientation.bottom);
      final horizontalBar = tester.widget<RawScrollbar>(horizontal);
      final verticalBar =
          tester.widget<RawScrollbar>(find.byType(RawScrollbar).first);
      expect(horizontalBar.thumbVisibility, width >= 650);
      expect(horizontalBar.trackVisibility, width >= 650);
      expect(horizontalBar.interactive, width >= 650);
      expect(horizontalBar.padding, EdgeInsets.zero);
      final bounds = tester.getRect(horizontal);
      if (width >= 650) {
        await tester.dragFrom(
            Offset(bounds.left + 20, bounds.bottom - 6), const Offset(120, 0));
      } else {
        await tester.drag(find.byType(ListView), const Offset(-150, 0));
      }
      await tester.pumpAndSettle();
      expect(horizontalBar.controller!.offset, greaterThan(0));
      expect(verticalBar.controller!.offset, 0);

      await render(Colors.purple);
      await tester.pumpAndSettle();
      expect(tester.widget<RawScrollbar>(horizontal).thumbColor, Colors.purple);
      final horizontalOffset = horizontalBar.controller!.offset;
      await tester.dragFrom(
          Offset(bounds.center.dx, 400), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(verticalBar.controller!.offset, greaterThan(0));
      expect(horizontalBar.controller!.offset, horizontalOffset);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 1920.0]) {
    for (final external in [true, false]) {
      testWidgets('Rolagem em $width px, controller externo: $external',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ScrollController();
        addTearDown(controller.dispose);

        Future<void> render(Color color) => tester.pumpWidget(MaterialApp(
              theme: ThemeData(platform: TargetPlatform.windows),
              home: Scaffold(
                body: FestaScrollArea(
                  controller: external ? controller : null,
                  color: color,
                  child: ListView.builder(
                    controller: external ? controller : null,
                    primary: !external,
                    itemCount: 100,
                    itemExtent: 60,
                    itemBuilder: (_, index) => Text('Item $index'),
                  ),
                ),
              ),
            ));

        await render(Colors.green);
        await tester.pumpAndSettle();
        final scrollbar = find.byType(RawScrollbar);
        expect(scrollbar, findsOneWidget);
        final bounds = tester.getRect(scrollbar);
        expect(bounds.width, width > 1360 ? 1360 : width);
        expect(bounds.center.dx, width / 2);
        expect(tester.widget<RawScrollbar>(scrollbar).thumbColor, Colors.green);
        expect(tester.widget<RawScrollbar>(scrollbar).thumbVisibility,
            width >= 650);

        if (width >= 650) {
          await tester.dragFrom(
              Offset(bounds.right - 6, bounds.top + 30), const Offset(0, 160));
        } else {
          await tester.drag(find.byType(ListView), const Offset(0, -300));
        }
        await tester.pumpAndSettle();
        expect(tester.widget<RawScrollbar>(scrollbar).controller!.offset,
            greaterThan(0));

        await render(Colors.purple);
        await tester.pumpAndSettle();
        expect(
            tester.widget<RawScrollbar>(scrollbar).thumbColor, Colors.purple);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
