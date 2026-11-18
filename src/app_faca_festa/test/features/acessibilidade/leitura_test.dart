import 'dart:async';
import 'dart:io';

import 'package:app_faca_festa/core/accessibility/preferencias_leitura.dart';
import 'package:app_faca_festa/core/accessibility/tipografia_festa.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/repositories/convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/grupo_convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/presente_reservation_repository.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/grupo_convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/pages/area/lista_convidados_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/widgets/convidados_layout.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/festa_app_bar.dart';
import 'package:app_faca_festa/presentation/widgets/festa_leitura.dart';
import 'package:app_faca_festa/presentation/widgets/festa_bottom_bar.dart';
import 'package:app_faca_festa/presentation/modules/gifts/controllers/gift_controller.dart';
import 'package:app_faca_festa/presentation/modules/gifts/gerenciar_presentes_page.dart';
import 'package:app_faca_festa/domain/usecases/get_gifts/gift_usecases.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/pages/orcamento_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class _Convidados extends Fake implements ConvidadoRepository {}

class _Grupos extends Fake implements GrupoConvidadoRepository {}

class _Reservas extends Fake implements PresenteReservationRepository {}

class _Presentes extends Fake implements GiftUseCases {}

class _Evento extends Fake implements EventoController {
  @override
  Evento? get eventoAtualEntidade => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() => Get.reset());

  test('tipografia combina janela, escala nativa e preferência de leitura', () {
    const celular =
        EscalaTextoFesta(sistema: TextScaler.noScaling, largura: 360);
    const desktop =
        EscalaTextoFesta(sistema: TextScaler.noScaling, largura: 1440);
    const ampliada = EscalaTextoFesta(
        sistema: TextScaler.linear(1.5), largura: 1440, leitura: 1.4);
    expect(celular.scale(13), 14);
    expect(desktop.scale(13), 16);
    expect(desktop.scale(18), 22);
    expect(ampliada.scale(13), closeTo(16 * 1.5 * 1.4, .001));
    expect(celular.scale(0), 0);
  });

  test('preferência valida valores e serializa gravações concorrentes',
      () async {
    expect(PreferenciasLeitura.normalizar(double.nan), 1);
    expect(PreferenciasLeitura.normalizar(double.infinity), 1);
    final primeira = Completer<void>();
    final valores = <double>[];
    final preferencias = PreferenciasLeitura(salvar: (valor) async {
      valores.add(valor);
      if (valores.length == 1) await primeira.future;
    });
    preferencias.ajustar(1.2);
    final a = preferencias.guardar();
    await Future<void>.delayed(Duration.zero);
    preferencias.ajustar(1.6);
    final b = preferencias.guardar();
    primeira.complete();
    await Future.wait([a, b]);
    expect(valores, [1.2, 1.6]);
    final reaberta = PreferenciasLeitura(escalaInicial: valores.last);
    expect(reaberta.escala, 1.6);
    preferencias.dispose();
    reaberta.dispose();
  });

  test('falha de armazenamento mantém tamanho e permite nova tentativa',
      () async {
    var falhar = true;
    final preferencias = PreferenciasLeitura(salvar: (_) async {
      if (falhar) throw StateError('offline');
    });
    preferencias.ajustar(1.5);
    await preferencias.guardar();
    expect(preferencias.escala, 1.5);
    expect(preferencias.erro, isNotNull);
    falhar = false;
    await preferencias.guardar();
    expect(preferencias.erro, isNull);
    preferencias.dispose();
  });

  test('preferência guardada é restaurada pelo armazenamento do aplicativo',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'), null);
    });
    const recipiente = 'faca_festa_leitura_qa';
    await GetStorage.init(recipiente);
    final storage = GetStorage(recipiente);
    await storage.erase();
    await storage.write(PreferenciasLeitura.chave, 'valor inválido');
    final preferencias = PreferenciasLeitura.persistidas(storage);
    expect(preferencias.escala, 1);
    preferencias.ajustar(1.7);
    await preferencias.guardar();
    preferencias.dispose();
    final reaberta = PreferenciasLeitura.persistidas(storage);
    expect(reaberta.escala, 1.7);
    reaberta.dispose();
    await storage.erase();
    await Future<void>.delayed(Duration.zero);
    await storage.queue.add(() async {});
  });

  for (final largura in [320.0, 420.0, 768.0, 1440.0]) {
    for (final (escala, sistema) in [
      (1.0, 1.0),
      (1.6, 1.0),
      (2.0, 1.0),
      (1.0, 2.0),
      (1.4, 1.5),
    ]) {
      testWidgets(
          'convidados em $largura px, leitura $escala e sistema $sistema',
          (tester) async {
        tester.view.physicalSize = Size(largura, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final preferencias = PreferenciasLeitura(escalaInicial: escala);
        final convidados = ConvidadoController(
            repository: _Convidados(),
            presenteReservationRepository: _Reservas());
        final grupos = GrupoConvidadoController(repository: _Grupos());
        final tema = EventThemeController();
        convidados.convidados.assignAll([
          for (var i = 0; i < 3; i++)
            Convidado(
              idConvidado: '$i',
              idEvento: 'festa',
              nome: i == 0 ? 'Ana Maria de Oliveira e Silva' : 'Convidado $i',
              contato: '(41) 99999-9999',
              email: 'contato.com.nome.completo@exemplo.com.br',
              nomeGrupo: 'Família e amigos',
              status: i == 0
                  ? StatusConvidado.confirmado
                  : StatusConvidado.pendente,
              dataCadastro: DateTime(2026),
              dataAtualizacao: DateTime(2026),
            ),
        ]);
        addTearDown(() {
          preferencias.dispose();
          convidados.onClose();
          grupos.onClose();
          tema.onClose();
        });
        await tester.pumpWidget(GetMaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(sistema)),
            child: FestaTipografia(
              preferencias: preferencias,
              child: FestaLeitura(child: child!),
            ),
          ),
          home: DefaultTabController(
            length: 5,
            child: Builder(
                builder: (context) => Scaffold(
                      appBar: FestaAppBar(
                        titulo: 'Convidados',
                        automaticamenteImplyLeading: false,
                        altura: 52,
                        bottom: ConvidadosTabBar(
                            controller: DefaultTabController.of(context),
                            primary: Colors.green),
                      ),
                      body: FestaLeitura(
                        child: ConvidadosContent(
                          child: ListaConvidadosScreen(
                            themeController: tema,
                            convidadoController: convidados,
                            eventoController: _Evento(),
                            grupoController: grupos,
                            embedded: true,
                          ),
                        ),
                      ),
                      bottomNavigationBar: FestaBottomBar(
                        currentIndex: 1,
                        onTap: (_) {},
                        items: const [
                          FestaNavItem(icon: Icons.celebration, label: 'Festa'),
                          FestaNavItem(icon: Icons.people, label: 'Convidados'),
                          FestaNavItem(icon: Icons.wallet, label: 'Orçamento'),
                          FestaNavItem(icon: Icons.more_horiz, label: 'Mais'),
                        ],
                        theme: tema,
                      ),
                    )),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Ana Maria de Oliveira e Silva'), findsOneWidget);
        expect(
            tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isFalse);
        for (final titulo in [
          'Lista',
          'Grupos',
          'Cardápio',
          'Mesas',
          'Status'
        ]) {
          expect(find.text(titulo).hitTestable(), findsOneWidget);
        }
        final campo = tester.getSize(find.byType(TextField).first);
        expect(campo.height, greaterThanOrEqualTo(48));
      });
    }
  }

  testWidgets('pinça amplia texto, pausa a lista e não dispara atualização',
      (tester) async {
    final preferencias = PreferenciasLeitura();
    final rolagem = ScrollController();
    var atualizacoes = 0;
    addTearDown(preferencias.dispose);
    addTearDown(rolagem.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => FestaTipografia(
          preferencias: preferencias, child: FestaLeitura(child: child!)),
      home: Scaffold(
        body: FestaLeitura(
          child: Builder(
              builder: (context) => RefreshIndicator(
                    onRefresh: () async {
                      atualizacoes++;
                    },
                    child: ListView(
                      controller: rolagem,
                      physics: FestaLeitura.physics(
                          context, const AlwaysScrollableScrollPhysics()),
                      children: [
                        for (var i = 0; i < 50; i++)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Detalhes da festa $i',
                                style: const TextStyle(fontSize: 14)),
                          ),
                      ],
                    ),
                  )),
        ),
      ),
    ));
    final primeiro =
        await tester.startGesture(const Offset(150, 250), pointer: 1);
    final segundo =
        await tester.startGesture(const Offset(250, 250), pointer: 2);
    await tester.pump();
    await primeiro.moveTo(const Offset(100, 250));
    await segundo.moveTo(const Offset(300, 250));
    await tester.pump();
    expect(preferencias.escala, closeTo(2, .01));
    expect(tester.widget<ListView>(find.byType(ListView)).physics,
        isA<NeverScrollableScrollPhysics>());
    await primeiro.up();
    await segundo.up();
    await tester.pumpAndSettle();
    expect(atualizacoes, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(rolagem.offset, greaterThan(0));
    final arrastando =
        await tester.startGesture(const Offset(150, 350), pointer: 3);
    await arrastando.moveBy(const Offset(0, -40));
    await tester.pump();
    final apoio = await tester.startGesture(const Offset(250, 310), pointer: 4);
    await tester.pump();
    await arrastando.moveBy(const Offset(-30, 0));
    await apoio.moveBy(const Offset(30, 0));
    await tester.pump();
    await arrastando.cancel();
    await apoio.cancel();
    await tester.pumpAndSettle();
    expect(atualizacoes, 0);
    expect(tester.widget<ListView>(find.byType(ListView)).physics,
        isA<AlwaysScrollableScrollPhysics>());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pinça cobre novas rotas e painéis sem controles de aumento',
      (tester) async {
    final preferencias = PreferenciasLeitura();
    addTearDown(preferencias.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => FestaTipografia(
          preferencias: preferencias, child: FestaLeitura(child: child!)),
      home: Scaffold(
        appBar: const FestaAppBar(
            titulo: 'Convidados', automaticamenteImplyLeading: false),
        body: Builder(
          builder: (context) => ListView(
            key: const Key('pinca_inicio'),
            children: [
              const Text('Conteúdo da festa', style: TextStyle(fontSize: 14)),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        appBar: const FestaAppBar(titulo: 'Detalhes'),
                        body: ListView(
                          key: const Key('pinca_detalhes'),
                          children: [
                            const Text('Detalhes do fornecedor'),
                            TextButton(
                              onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                builder: (_) => const SizedBox(
                                  key: Key('pinca_painel'),
                                  height: 300,
                                  width: double.infinity,
                                  child: Center(child: Text('Painel da festa')),
                                ),
                              ),
                              child: const Text('Abrir painel'),
                            ),
                          ],
                        ),
                      ),
                    )),
                child: const Text('Abrir detalhes'),
              ),
            ],
          ),
        ),
      ),
    ));
    final altura = tester.getSize(find.byType(FestaAppBar)).height;
    expect(find.byTooltip('Tamanho do texto'), findsNothing);
    expect(find.byIcon(Icons.text_fields_rounded), findsNothing);
    expect(find.byType(Slider), findsNothing);
    await pincar(tester, find.byKey(const Key('pinca_inicio')), 1.5);
    expect(preferencias.escala, closeTo(1.5, .001));
    expect(tester.getSize(find.byType(FestaAppBar)).height, altura);
    await tester.tap(find.text('Abrir detalhes'));
    await tester.pumpAndSettle();
    await pincar(tester, find.byKey(const Key('pinca_detalhes')), .8);
    expect(preferencias.escala, closeTo(1.2, .001));
    await tester.tap(find.text('Abrir painel'));
    await tester.pumpAndSettle();
    await pincar(tester, find.byKey(const Key('pinca_painel')), 1.5);
    expect(preferencias.escala, closeTo(1.8, .001));
    expect(find.byType(Slider), findsNothing);
    expect(find.textContaining('Restaurar'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('mapas e fotos mantêm a pinça própria sem alterar o texto',
      (tester) async {
    final preferencias = PreferenciasLeitura();
    addTearDown(preferencias.dispose);
    var escalaImagem = 1.0;
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => FestaTipografia(
          preferencias: preferencias, child: FestaLeitura(child: child!)),
      home: Scaffold(
        body: FestaGestosProprios(
          child: GestureDetector(
            onScaleUpdate: (e) {
              if (e.scale > escalaImagem) escalaImagem = e.scale;
            },
            child: const ColoredBox(
              key: Key('foto'),
              color: Colors.blue,
              child: SizedBox.expand(),
            ),
          ),
        ),
      ),
    ));
    await pincar(tester, find.byKey(const Key('foto')), 1.5);
    expect(preferencias.escala, 1);
    expect(escalaImagem, greaterThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('trackpad distingue rolagem de pinça de texto', (tester) async {
    final preferencias = PreferenciasLeitura();
    addTearDown(preferencias.dispose);
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => FestaTipografia(
          preferencias: preferencias, child: FestaLeitura(child: child!)),
      home: Scaffold(
        body: ListView(
          children: [
            for (var i = 0; i < 60; i++)
              Padding(
                  padding: const EdgeInsets.all(12), child: Text('Item $i')),
          ],
        ),
      ),
    ));
    final gesto = await tester.createGesture(kind: PointerDeviceKind.trackpad);
    await gesto.panZoomStart(const Offset(200, 300));
    await gesto.panZoomUpdate(const Offset(200, 300),
        pan: const Offset(0, -50));
    await gesto.panZoomEnd();
    await tester.pumpAndSettle();
    expect(preferencias.escala, 1);
    await gesto.panZoomStart(const Offset(200, 300));
    await gesto.panZoomUpdate(const Offset(200, 300), scale: 1.5);
    await gesto.panZoomEnd();
    await tester.pumpAndSettle();
    expect(preferencias.escala, closeTo(1.5, .001));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('listas comuns não rolam nem atualizam ao pinçar',
      (tester) async {
    final preferencias = PreferenciasLeitura();
    final rolagem = ScrollController();
    addTearDown(preferencias.dispose);
    addTearDown(rolagem.dispose);
    var atualizacoes = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (_, child) => FestaTipografia(
          preferencias: preferencias, child: FestaLeitura(child: child!)),
      home: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            atualizacoes++;
          },
          child: ListView(
            key: const Key('lista_comum'),
            controller: rolagem,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 50; i++)
                Padding(
                    padding: const EdgeInsets.all(12), child: Text('Item $i')),
            ],
          ),
        ),
      ),
    ));
    await pincar(tester, find.byKey(const Key('lista_comum')), 1.5);
    expect(preferencias.escala, closeTo(1.5, .001));
    expect(rolagem.offset, 0);
    expect(atualizacoes, 0);
    await tester.drag(
        find.byKey(const Key('lista_comum')), const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(rolagem.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
    rolagem.jumpTo(0);
    await tester.pumpAndSettle();
    final puxando =
        await tester.startGesture(const Offset(150, 120), pointer: 41);
    await puxando.moveBy(const Offset(0, 250));
    await tester.pump(const Duration(milliseconds: 300));
    final apoio =
        await tester.startGesture(const Offset(250, 370), pointer: 42);
    await tester.pump();
    await puxando.moveBy(const Offset(-30, 0));
    await apoio.moveBy(const Offset(30, 0));
    await puxando.up();
    await apoio.up();
    await tester.pumpAndSettle();
    expect(atualizacoes, 0);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
  for (final largura in [360.0, 1440.0]) {
    for (final escala in [1.0, 2.0]) {
      testWidgets('presentes e orçamento em $largura px com leitura $escala',
          (tester) async {
        tester.view.physicalSize = Size(largura, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final preferencias = PreferenciasLeitura(escalaInicial: escala);
        final tema = EventThemeController();
        final presentes =
            GiftController(eventoId: 'festa', usecases: _Presentes());
        addTearDown(() {
          preferencias.dispose();
          tema.onClose();
          presentes.onClose();
        });
        Widget aplicativo(Widget pagina) => GetMaterialApp(
              builder: (_, child) => FestaTipografia(
                  preferencias: preferencias,
                  child: FestaLeitura(child: child!)),
              home: pagina,
            );
        await tester.pumpWidget(aplicativo(GerenciarPresentesPage(
            eventoId: 'festa', controller: presentes, themeController: tema)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(aplicativo(Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              resumoCard(
                const LinearGradient(colors: [Colors.green, Colors.teal]),
                limite: 12450,
                previsto: 9650,
                pago: 4200,
                cotado: 3150,
                contratado: 3150,
                saldoDevido: 3150,
              ),
            ],
          ),
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> pincar(WidgetTester tester, Finder alvo, double fator) async {
  final centro = tester.getCenter(alvo);
  final primeiro =
      await tester.startGesture(centro + const Offset(-40, 0), pointer: 31);
  final segundo =
      await tester.startGesture(centro + const Offset(40, 0), pointer: 32);
  await tester.pump();
  final intermediario = (1 + fator) / 2;
  await primeiro.moveTo(centro + Offset(-40 * intermediario, 8));
  await segundo.moveTo(centro + Offset(40 * intermediario, 8));
  await tester.pump();
  await primeiro.moveTo(centro + Offset(-40 * fator, 15));
  await segundo.moveTo(centro + Offset(40 * fator, 15));
  await tester.pump();
  await primeiro.up();
  await segundo.up();
  await tester.pumpAndSettle();
}
