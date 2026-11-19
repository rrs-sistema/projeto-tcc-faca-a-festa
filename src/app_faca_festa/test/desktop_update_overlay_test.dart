import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/core/services/desktop_update_service.dart';
import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/presentation/widgets/desktop_update_overlay.dart';

void main() {
  setUp(() {
    UpdateOperations.active = 0;
    UpdateOperations.sealed = false;
    DesktopUpdateService.instance.installedVersion.value = '1.0.7 • build 9';
    DesktopUpdateService.instance.state.value = const DesktopUpdateState(
        DesktopUpdateStatus.ready,
        version: '1.0.8',
        build: 10);
  });
  tearDown(() {
    UpdateOperations.sealed = false;
    UpdateOperations.active = 0;
  });
  Widget app() => MaterialApp(
      builder: (_, child) => DesktopUpdateOverlay(child: child!),
      home: const Scaffold(
          appBar: null,
          body: Column(
              children: [DesktopUpdateMenuButton(), Text('Página original')])));

  final visibleBarrier = find.byWidgetPredicate(
      (widget) => widget is ModalBarrier && widget.color != null);

  testWidgets('operator must confirm and can cancel without launching helper',
      (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('1.0.7 • build 9'), findsNothing);
    await tester.tap(find.byType(DesktopUpdateMenuButton));
    await tester.pump();
    expect(find.text('1.0.7 • build 9'), findsOneWidget);
    await tester.tap(find.text('Atualizar para 1.0.8 e reiniciar'));
    await tester.pump();
    expect(find.text('Atualizar e reiniciar?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(find.text('Atualizar e reiniciar?'), findsNothing);
    expect(DesktopUpdateService.instance.state.value.status,
        DesktopUpdateStatus.ready);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  testWidgets('active operation blocks confirmation with visible notice',
      (tester) async {
    UpdateOperations.active = 1;
    await tester.pumpWidget(app());
    await tester.tap(find.byType(DesktopUpdateMenuButton));
    await tester.pump();
    await tester.tap(find.text('Atualizar para 1.0.8 e reiniciar'));
    await tester.pump();
    expect(find.text('Atualizar e reiniciar?'), findsNothing);
    expect(find.textContaining('Aguarde as operações'), findsOneWidget);
    expect(find.text('Página original'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  testWidgets('failure remains accessible globally and inside the update panel',
      (tester) async {
    await tester.pumpWidget(app());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    showDialog<void>(
        context: navigator.context,
        builder: (_) => const AlertDialog(title: Text('Menu sobreposto')));
    await tester.pumpAndSettle();
    DesktopUpdateService.instance
        .reportError('Falha de preparação. Feche e reabra o aplicativo.');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Falha de preparação'), findsOneWidget);
    DesktopUpdateMenuButton.requests.value++;
    await tester.pump();
    expect(find.textContaining('Falha de preparação'), findsOneWidget);
    final stack = tester.widget<Stack>(find
        .descendant(
            of: find.byType(DesktopUpdateOverlay), matching: find.byType(Stack))
        .first);
    expect(stack.children.last, isA<Center>());
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  testWidgets('Windows dashboard exposes a contextual available-update control',
      (tester) async {
    await tester.pumpWidget(app());
    expect(find.byIcon(Icons.system_update_alt), findsOneWidget);
    expect(find.text('Verificar atualizações'), findsNothing);
    expect(find.text('1.0.7 • build 9'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('offline error leaves dashboard usable with access to details',
      (tester) async {
    DesktopUpdateService.instance.reportError('Sem acesso às atualizações.');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem acesso'), findsOneWidget);
    expect(visibleBarrier, findsNothing);
    expect(find.text('Página original'), findsOneWidget);
    await tester.tap(find.byType(DesktopUpdateMenuButton));
    await tester.pump();
    expect(find.textContaining('Sem acesso'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.textContaining('Sem acesso'), findsOneWidget);
    expect(visibleBarrier, findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('authentication screen can install without a dashboard menu',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => DesktopUpdateOverlay(child: child!),
      home: const Scaffold(body: Text('Código do autenticador')),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopUpdateMenuButton), findsNothing);
    expect(find.text('Versão 1.0.8 pronta para instalar'), findsOneWidget);
    expect(visibleBarrier, findsNothing);
    await tester.tap(find.text('Revisar e instalar atualização'));
    await tester.pump();
    await tester.tap(find.text('Atualizar para 1.0.8 e reiniciar'));
    await tester.pump();
    expect(find.text('Atualizar e reiniciar?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.text('Versão 1.0.8 pronta para instalar'), findsOneWidget);
    expect(DesktopUpdateService.instance.state.value.status,
        DesktopUpdateStatus.ready);
    expect(find.text('Código do autenticador'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('mobile has no Windows update controls or notices',
      (tester) async {
    await tester.pumpWidget(app());
    expect(find.byIcon(Icons.system_update_alt), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.text('Página original'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
