import 'dart:async';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/presentation/widgets/banner_conectividade.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Contador extends StatefulWidget {
  const _Contador();

  @override
  State<_Contador> createState() => _ContadorState();
}

class _ContadorState extends State<_Contador> {
  int valor = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => setState(() => valor++),
            child: Text('toques: $valor'),
          ),
        ),
      );
}

void main() {
  late bool responde;
  late ConectividadeService servico;
  late EstadoSincronizacao estado;

  setUp(() {
    Get.reset();
    responde = true;
    servico = Get.put(ConectividadeService(
      mudancasRede: const Stream<List<ConnectivityResult>>.empty(),
      redeAtual: () async => [ConnectivityResult.wifi],
      sonda: () async => responde,
      intervaloOffline: const Duration(hours: 1),
      intervaloOnline: const Duration(hours: 1),
    ));
    estado = Get.put(EstadoSincronizacao());
  });

  tearDown(() {
    servico.onClose();
    Get.reset();
  });

  Future<void> montar(WidgetTester tester,
      {Size tamanho = const Size(360, 800), double escala = 1.0}) async {
    tester.view.physicalSize = tamanho * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    // Timers reais: o relógio falso do teste não deve esperar a sonda periódica.
    await tester.runAsync(servico.iniciar);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: BannerConectividade(child: child!),
      ),
      home: const _Contador(),
    ));
  }

  Future<void> mudarRede(WidgetTester tester, bool online) async {
    responde = online;
    await tester.runAsync(servico.verificarAgora);
    await tester.pump();
  }

  testWidgets('online e sem pendências não mostra faixa', (tester) async {
    await montar(tester);
    expect(find.byKey(const Key('banner_offline')), findsNothing);
    expect(find.text('toques: 0'), findsOneWidget);
  });

  testWidgets('offline mostra a faixa e mantém a tela atual', (tester) async {
    await montar(tester);
    await tester.tap(find.text('toques: 0'));
    await tester.pump();
    expect(find.text('toques: 1'), findsOneWidget);

    await mudarRede(tester, false);
    expect(find.byKey(const Key('banner_offline')), findsOneWidget);
    expect(find.textContaining('fica salvo neste aparelho'), findsOneWidget);
    expect(find.text('toques: 1'), findsOneWidget,
        reason: 'a tela não pode ser recriada quando a internet cai');

    await mudarRede(tester, true);
    expect(find.byKey(const Key('banner_reconectado')), findsOneWidget);
    expect(find.text('toques: 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const Key('banner_reconectado')), findsNothing);
  });

  testWidgets('offline informa quantas alterações aguardam envio',
      (tester) async {
    await montar(tester);
    await mudarRede(tester, false);
    final servidor = Completer<void>();
    estado.registrar(servidor.future);
    estado.registrar(Completer<void>().future);
    await tester.pump();
    expect(find.text('2 a enviar'), findsOneWidget);
    servidor.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('1 a enviar'), findsOneWidget);
  });

  testWidgets('recusa do servidor aparece e pode ser fechada', (tester) async {
    await montar(tester);
    estado.registrar(
      Future<void>.error(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')),
      descricao: 'reserva do presente "Jogo de facas"',
    );
    await tester.pump();
    expect(find.byKey(const Key('banner_recusa')), findsOneWidget);
    expect(find.textContaining('Jogo de facas'), findsOneWidget);
    await tester.tap(find.byKey(const Key('banner_fechar')));
    await tester.pump();
    expect(find.byKey(const Key('banner_recusa')), findsNothing);
  });

  for (final (nome, tamanho) in [
    ('celular pequeno 360x800', const Size(360, 800)),
    ('celular 390x844', const Size(390, 844)),
    ('tablet 800x1280', const Size(800, 1280)),
  ]) {
    testWidgets('faixa sem estouro no $nome com fonte 130%', (tester) async {
      await montar(tester, tamanho: tamanho, escala: 1.3);
      await mudarRede(tester, false);
      estado.registrar(Completer<void>().future);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('banner_offline')), findsOneWidget);
    });
  }
}
