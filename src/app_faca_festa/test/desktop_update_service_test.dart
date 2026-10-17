import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app_faca_festa/core/services/desktop_update_service.dart';
import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/core/services/update_preparation.dart';

void main() {
  test('durability order and failure stop every later phase', () async {
    for (var failure = -1; failure < 4; failure++) {
      final phases = <int>[];
      Future<void> step(int index) async {
        phases.add(index);
        if (index == failure) throw StateError('phase $index');
      }

      final preparation = UpdatePreparation(
          stopSynchronization: () => step(0),
          persistSettings: () => step(1),
          flushPendingWrites: () => step(2),
          closeDatabase: () => step(3));
      if (failure == -1) {
        await preparation.run();
        expect(phases, [0, 1, 2, 3]);
      } else {
        await expectLater(preparation.run(), throwsStateError);
        expect(phases, List<int>.generate(failure + 1, (i) => i));
      }
    }
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/faca-festa-update');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> trace;
  late DesktopUpdateService service;
  Future<void> ready(int build) async {
    final done = Completer<void>();
    messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
            MethodCall('ready', {'version': '1.0.6', 'build': build})),
        (_) => done.complete());
    await done.future;
  }

  setUp(() {
    trace = [];
    UpdateOperations.active = 0;
    UpdateOperations.sealed = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      trace.add(call.method);
      return null;
    });
    service = DesktopUpdateService(
        channel: channel,
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'identity': 'faca-festa-windows-x64',
              'platform': 'windows-x64',
              'version': '1.0.6',
              'build': 8
            }),
            200)));
  });
  tearDown(() {
    service.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });
  test('startup downloads but never installs without confirmation', () async {
    await service.initialize(installedBuild: 7);
    expect(trace, ['initialize', 'download']);
    await ready(8);
    expect(service.state.value.status, DesktopUpdateStatus.ready);
    expect(trace.contains('install'), false);
  });
  test('save finishes before native helper starts', () async {
    await service.initialize(installedBuild: 7);
    await ready(8);
    await service.startInstall(prepare: () async {
      trace.add('save');
      await Future<void>.delayed(Duration.zero);
      trace.add('closed-db');
    });
    expect(trace, ['initialize', 'download', 'save', 'closed-db', 'install']);
  });
  test('preparation failure never starts helper and removes loading', () async {
    await service.initialize(installedBuild: 7);
    await ready(8);
    await expectLater(
        service.startInstall(prepare: () async => throw StateError('disk')),
        throwsStateError);
    expect(trace.contains('install'), false);
    expect(service.state.value.status, DesktopUpdateStatus.error);
    await expectLater(service.startInstall(), throwsStateError);
  });
  test('timeout never launches a late helper', () async {
    await service.initialize(installedBuild: 7);
    await ready(8);
    final preparation = Completer<void>();
    await expectLater(
        service.startInstall(
            prepare: () => preparation.future,
            preparationTimeout: const Duration(milliseconds: 10)),
        throwsA(isA<TimeoutException>()));
    preparation.complete();
    await Future<void>.delayed(Duration.zero);
    expect(trace.contains('install'), false);
    expect(service.state.value.status, DesktopUpdateStatus.error);
  });
  test('old/equal callbacks and catalog cannot offer installation', () async {
    await service.initialize(installedBuild: 8);
    await ready(7);
    await ready(8);
    expect(trace.contains('download'), false);
    expect(service.state.value.status, DesktopUpdateStatus.idle);
    await expectLater(service.startInstall(), throwsStateError);
  });
  test('helper failure restores visible error', () async {
    await service.initialize(installedBuild: 7);
    await ready(8);
    messenger.setMockMethodCallHandler(
        channel, (_) async => throw PlatformException(code: 'failed'));
    await expectLater(
        service.startInstall(), throwsA(isA<PlatformException>()));
    expect(service.state.value.status, DesktopUpdateStatus.error);
  });
  test('operation barrier blocks while writing and rejects new work after seal',
      () async {
    final writing = Completer<void>();
    final operation = UpdateOperations.run(() => writing.future);
    expect(UpdateOperations.active, 1);
    expect(UpdateOperations.seal, throwsStateError);
    writing.complete();
    await operation;
    expect(UpdateOperations.active, 0);
    UpdateOperations.seal();
    var executed = false;
    await expectLater(UpdateOperations.run(() async {
      executed = true;
    }), throwsStateError);
    expect(executed, false);
  });
  test('failed/nested operations release their barrier exactly once', () async {
    await expectLater(UpdateOperations.run(() async {
      await UpdateOperations.run(() async {
        expect(UpdateOperations.active, 2);
        throw StateError('failed');
      });
    }), throwsStateError);
    expect(UpdateOperations.active, 0);
  });
  test('feed failure leaves application usable with clear error', () async {
    service.dispose();
    service = DesktopUpdateService(
        channel: channel,
        client: MockClient((_) async => http.Response('failure', 503)));
    await service.initialize(installedBuild: 7);
    expect(service.state.value.status, DesktopUpdateStatus.error);
    expect(trace.contains('install'), false);
  });
}
