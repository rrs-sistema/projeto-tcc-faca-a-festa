// Capturas da experiência offline em celular (360 px) para a matriz de
// evidências. Atualizar com `flutter test --update-goldens` neste arquivo.
import 'dart:async';
import 'dart:io';

import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/estado_sincronizacao.dart';
import 'package:app_faca_festa/presentation/widgets/banner_conectividade.dart';
import 'package:app_faca_festa/presentation/widgets/selo_sincronizacao.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _pasta = '../../../docs/evidencias_validacao/offline-mobile-first/telas';

class _Checklist extends StatelessWidget {
  const _Checklist();

  @override
  Widget build(BuildContext context) {
    Widget tarefa(String id, String titulo, {bool feita = false}) => Card(
          child: ListTile(
            leading: Icon(
                feita ? Icons.check_box : Icons.check_box_outline_blank,
                color: const Color(0xFF880E4F)),
            title: Text(titulo),
            subtitle: SeloSincronizacao(chave: id),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Churrasco de fim de ano'),
        backgroundColor: const Color(0xFF880E4F),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          tarefa('tarefa-offline', 'Comprar carvão (feita sem internet)'),
          tarefa('tarefa-seed', 'Reservar chácara', feita: true),
          tarefa('conv-offline', 'Convidado adicionado offline'),
        ],
      ),
    );
  }
}

void main() {
  late bool responde;
  late ConectividadeService servico;
  late EstadoSincronizacao estado;

  setUpAll(() async {
    final fonte = FontLoader('OfflinePoppins');
    for (final arquivo in [
      'Poppins-Regular.ttf',
      'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf'
    ]) {
      fonte.addFont(Future.value(ByteData.sublistView(
          await File('assets/fonts/$arquivo').readAsBytes())));
    }
    await fonte.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() {
    Get.reset();
    responde = false;
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

  Future<void> montar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.runAsync(servico.verificarAgora);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'OfflinePoppins', useMaterial3: true),
      builder: (context, child) => BannerConectividade(child: child!),
      home: const _Checklist(),
    ));
    await tester.pump();
  }

  Future<void> capturar(WidgetTester tester, String nome) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile('$_pasta/$nome.png'));

  testWidgets('offline com alterações salvas no aparelho', (tester) async {
    final servidor = Completer<void>();
    estado.registrar(servidor.future, chave: 'tarefa-offline');
    estado.registrar(servidor.future, chave: 'conv-offline');
    await montar(tester);
    expect(servico.offline, isTrue);
    await capturar(tester, '01-offline-pendencias');
    servidor.complete();
    await tester.pump();
  });

  testWidgets('app reaberto sem internet com fila da sessão anterior',
      (tester) async {
    estado.pendenciasAnteriores.value = true;
    await montar(tester);
    await capturar(tester, '02-reaberto-fila-anterior');
  });

  testWidgets('internet voltou e a fila foi enviada', (tester) async {
    await montar(tester);
    responde = true;
    await tester.runAsync(servico.verificarAgora);
    await tester.pump();
    await capturar(tester, '03-reconectado');
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('servidor recusou uma reserva feita offline', (tester) async {
    responde = true;
    await montar(tester);
    estado.ultimaRecusa.value =
        'O servidor recusou: reserva do presente "Cooler 48 litros" '
        '(outra pessoa pode ter reservado antes).';
    await tester.pump();
    await capturar(tester, '04-conflito-reserva');
  });
}
