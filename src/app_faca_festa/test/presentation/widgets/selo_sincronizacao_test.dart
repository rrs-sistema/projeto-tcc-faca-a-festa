import 'dart:async';

import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/presentation/widgets/selo_sincronizacao.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late EstadoSincronizacao estado;

  setUp(() {
    Get.reset();
    estado = Get.put(EstadoSincronizacao());
  });
  tearDown(Get.reset);

  Future<void> montar(WidgetTester tester,
      {double largura = 360, double escala = 1.0}) async {
    tester.view.physicalSize = Size(largura, 720) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: Scaffold(
        body: ListView(children: const [
          ListTile(
            leading: Icon(Icons.check_box_outline_blank),
            title: Text('Comprar carvão para o churrasco do sábado'),
            subtitle: SeloSincronizacao(chave: 'tarefa-1'),
            trailing: Icon(Icons.more_vert),
          ),
          ListTile(
            title: Text('Outra tarefa já enviada'),
            subtitle: SeloSincronizacao(chave: 'tarefa-2'),
          ),
        ]),
      ),
    ));
  }

  testWidgets('aparece só no item pendente e some quando o servidor confirma',
      (tester) async {
    await montar(tester);
    expect(find.byKey(const Key('selo_pendente_tarefa-1')), findsNothing);

    final servidor = Completer<void>();
    estado.registrar(servidor.future, chave: 'tarefa-1');
    await tester.pump();
    expect(find.byKey(const Key('selo_pendente_tarefa-1')), findsOneWidget);
    expect(find.byKey(const Key('selo_pendente_tarefa-2')), findsNothing);
    expect(find.text(SeloSincronizacao.texto), findsOneWidget);

    servidor.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('selo_pendente_tarefa-1')), findsNothing);
  });

  testWidgets('duas escritas no mesmo item: o selo fica até a última',
      (tester) async {
    await montar(tester);
    final primeira = Completer<void>(), segunda = Completer<void>();
    estado.registrar(primeira.future, chave: 'tarefa-1');
    estado.registrar(segunda.future, chave: 'tarefa-1');
    await tester.pump();

    primeira.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('selo_pendente_tarefa-1')), findsOneWidget);

    segunda.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('selo_pendente_tarefa-1')), findsNothing);
  });

  for (final largura in [320.0, 360.0, 800.0]) {
    testWidgets('sem estouro em ${largura.toInt()}px com fonte 130%',
        (tester) async {
      await montar(tester, largura: largura, escala: 1.3);
      estado.registrar(Completer<void>().future, chave: 'tarefa-1');
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('selo_pendente_tarefa-1')), findsOneWidget);
    });
  }

  testWidgets('sem estado de sincronização registrado não ocupa espaço',
      (tester) async {
    Get.reset();
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SeloSincronizacao(chave: 'x'))));
    expect(find.byType(Container), findsNothing);
  });
}
