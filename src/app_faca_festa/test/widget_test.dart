import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('test harness renders a basic widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Faca Festa'),
        ),
      ),
    );

    expect(find.text('Faca Festa'), findsOneWidget);
  });
}
