import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/domain/repositories/admin_territorio_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_admin_territorios.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/components/territorio_atendimento_screen.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/territorio/admin_territorio_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/admin_theme.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

void main() {
  late _AdminTerritorioRepositoryFake repository;
  late AdminTerritorioController controller;

  setUp(() {
    Get.testMode = true;
    repository = _AdminTerritorioRepositoryFake();
    controller = AdminTerritorioController(
      territoriosAdmin: GerenciarAdminTerritorios(repository),
    );
  });

  tearDown(Get.reset);

  test('loads territories through the use case', () async {
    repository.territorios = [
      _territorio(id: 'territorio-1', descricao: 'Zona Sul'),
      _territorio(id: 'territorio-2', descricao: 'Centro'),
    ];

    await controller.carregarTerritorios();

    expect(controller.territorios, hasLength(2));
    expect(controller.territorios.first.descricao, 'Zona Sul');
  });

  test('saves territory and reloads the list', () async {
    final territorio = _territorio(id: 'territorio-1', descricao: 'Zona Sul');
    repository.territorios = [territorio];

    await controller.salvarTerritorio(territorio);

    expect(repository.territoriosSalvos, [territorio]);
    expect(controller.territorios.map((t) => t.idTerritorio), ['territorio-1']);
    expect(controller.idTerritorioSelecionado.value, 'territorio-1');
  });

  test('selects territory and clears with verTodos', () {
    final territorio = _territorio(id: 'territorio-1', descricao: 'Zona Sul');
    controller.territorios.assignAll([territorio]);

    controller.selecionarTerritorio(territorio);
    expect(controller.idTerritorioSelecionado.value, 'territorio-1');

    controller.verTodos();
    expect(controller.idTerritorioSelecionado.value, isNull);
  });

  testWidgets(
      'mostra só pontos na visão geral e revela a área ao selecionar',
      (tester) => http.runWithClient(() async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(1600, 900);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            Get.testMode = false;
            final runtimeFetching = GoogleFonts.config.allowRuntimeFetching;
            GoogleFonts.config.allowRuntimeFetching = false;
            addTearDown(() =>
                GoogleFonts.config.allowRuntimeFetching = runtimeFetching);

            repository.territorios = [
              _territorio(id: 'sao-paulo', descricao: 'São Paulo'),
              _territorio(id: 'curitiba', descricao: 'Curitiba').copyWith(
                latitude: -25.43,
                longitude: -49.27,
              ),
              const Territorio(
                idTerritorio: 'regiao',
                idFornecedor: 'fornecedor-1',
                descricao: 'Região Curitiba',
                tipoCobertura: 'regiao',
                regioes: ['-25.42,-49.28', '-25.44,-49.26', '-25.45,-49.30'],
              ),
              _territorio(
                  id: 'inativo', descricao: 'Território inativo', ativo: false),
            ];

            await tester.pumpWidget(MaterialApp(
              home: AdminTerritorioScreen(
                controller: controller,
                fornecedorController: _FornecedorControllerFake(),
                themeController: EventThemeController(),
              ),
            ));
            await tester.pumpAndSettle();

            final mapa = controller.mapController;
            final zoomGeral = mapa.camera.zoom;
            final circulos =
                find.byWidgetPredicate((widget) => widget is CircleLayer);
            final poligonos = find.byType(PolygonLayer);
            final marcadores = find.byType(MarkerLayer);
            expect(tester.widget<CircleLayer>(circulos).circles, isEmpty);
            expect(tester.widget<PolygonLayer>(poligonos).polygons, isEmpty);
            expect(
                tester.widget<MarkerLayer>(marcadores).markers, hasLength(3));
            expect(find.text('3 territórios ativos'), findsOneWidget);

            await tester.tap(find.text('Território inativo'));
            await tester.pumpAndSettle();
            final cameraFocada = mapa.camera;
            expect(cameraFocada.center.latitude, closeTo(-23.5, 0.01));
            expect(cameraFocada.center.longitude, closeTo(-46.6, 0.01));
            expect(cameraFocada.zoom, greaterThan(zoomGeral));
            expect(
              tester
                  .widget<CircleLayer>(circulos)
                  .circles
                  .map((c) => c.borderColor),
              [AdminPalette.primary],
            );
            expect(tester.widget<PolygonLayer>(poligonos).polygons, isEmpty);
            final pontosEmFoco = tester.widget<MarkerLayer>(marcadores).markers;
            expect(pontosEmFoco, hasLength(4));
            final iconeContexto =
                ((pontosEmFoco.first.child as Tooltip).child as GestureDetector)
                    .child as Icon;
            expect(iconeContexto.color,
                AdminPalette.danger.withValues(alpha: 0.85));

            await tester.tap(find.byTooltip('Aproximar mapa'));
            await tester.pumpAndSettle();
            expect(mapa.camera.zoom, closeTo(cameraFocada.zoom + 1, 0.001));
            expect(mapa.camera.center, cameraFocada.center);
            expect(tester.widget<CircleLayer>(circulos).circles, hasLength(1));
            expect(tester.widget<PolygonLayer>(poligonos).polygons, isEmpty);
            expect(
                tester.widget<MarkerLayer>(marcadores).markers, hasLength(4));

            await tester.tap(find.byTooltip('Afastar mapa'));
            await tester.pumpAndSettle();
            expect(mapa.camera.zoom, closeTo(cameraFocada.zoom, 0.001));

            await tester.tap(find.text('Ver todos'));
            await tester.pumpAndSettle();
            expect(mapa.camera.zoom, closeTo(zoomGeral, 0.001));
            expect(tester.widget<CircleLayer>(circulos).circles, isEmpty);
            expect(tester.widget<PolygonLayer>(poligonos).polygons, isEmpty);
            expect(
                tester.widget<MarkerLayer>(marcadores).markers, hasLength(3));

            await tester.tap(find.text('Região Curitiba'));
            await tester.pumpAndSettle();
            expect(tester.widget<CircleLayer>(circulos).circles, isEmpty);
            final pontosComRegiao =
                tester.widget<MarkerLayer>(marcadores).markers;
            expect(pontosComRegiao, hasLength(3));
            expect(
                pontosComRegiao.last.point.latitude, closeTo(-25.435, 0.001));
            expect(
                pontosComRegiao.last.point.longitude, closeTo(-49.28, 0.001));
            expect(
              tester
                  .widget<PolygonLayer>(poligonos)
                  .polygons
                  .single
                  .borderColor,
              AdminPalette.primary,
            );
          }, _criarClienteDeTiles));

  testWidgets(
      'editor atualiza o círculo do raio e enquadra a cobertura antes de salvar',
      (tester) => http.runWithClient(() async {
            final existente =
                _territorio(id: 't', descricao: 'Centro').copyWith(raioKm: 70);
            repository.territorios = [existente];
            await controller.carregarTerritorios();
            await _abrirEditor(tester, controller, existente);

            final mapa = tester.widget<FlutterMap>(find.byType(FlutterMap));
            final camera = mapa.mapController!;
            expect(camera, isNot(same(controller.mapController)));
            const raioEmEdicao = ValueKey('raioEmEdicao');
            final circulo = find.byKey(raioEmEdicao);
            expect(tester.widget<CircleLayer>(circulo).circles.single.radius,
                70000);
            expect(
              tester.widgetList<CircleLayer>(find.byType(CircleLayer)).expand(
                    (layer) => layer.circles,
                  ),
              hasLength(1),
            );
            final zoomInicial = camera.camera.zoom;
            _verificarCirculoVisivel(camera.camera, existente, 70000);

            tester.widget<Slider>(find.byType(Slider)).onChanged!(20);
            await tester.pump();
            expect(tester.widget<CircleLayer>(circulo).circles.single.radius,
                20000);
            tester.widget<Slider>(find.byType(Slider)).onChangeEnd!(20);
            await tester.pumpAndSettle();
            expect(camera.camera.zoom, greaterThan(zoomInicial));
            _verificarCirculoVisivel(camera.camera, existente, 20000);

            final enquadrado = camera.camera;
            final aproximar = find.byTooltip('Aproximar mapa');
            final afastar = find.byTooltip('Afastar mapa');
            await tester.tap(aproximar);
            await tester.pumpAndSettle();
            expect(camera.camera.zoom, closeTo(enquadrado.zoom + 1, 0.001));
            expect(camera.camera.center, enquadrado.center);
            await tester.tap(afastar);
            await tester.pumpAndSettle();
            expect(camera.camera.zoom, closeTo(enquadrado.zoom, 0.001));

            camera.move(enquadrado.center, 18.5);
            await tester.pumpAndSettle();
            await tester.tap(aproximar);
            await tester.pumpAndSettle();
            expect(camera.camera.zoom, 19);
            expect(
              tester
                  .widget<IconButton>(
                      find.widgetWithIcon(IconButton, Icons.add_rounded))
                  .onPressed,
              isNull,
            );
            expect(tester.widget<CircleLayer>(circulo).circles.single.radius,
                20000);
            expect(repository.territoriosSalvos, isEmpty);

            await tester.tap(find.text('Atualizar'));
            await tester.pumpAndSettle();
            expect(repository.territoriosSalvos.single.raioKm, 20);
            expect(find.byType(FlutterMap), findsNothing);
            expect(find.text('Abrir editor'), findsOneWidget);
          }, _criarClienteDeTiles));

  testWidgets(
      'editor desenha os vértices e restaura a região ao alternar o modo',
      (tester) => http.runWithClient(() async {
            final existente = _territorio(id: 't', descricao: 'Centro');
            await _abrirEditor(tester, controller, existente);

            await tester.tap(find.byTooltip('Editar por região'));
            await tester.pumpAndSettle();
            expect(find.byTooltip('Finalizar desenho'), findsOneWidget);
            expect(find.byKey(const ValueKey('raioEmEdicao')), findsNothing);
            expect(
                tester
                    .widget<FilledButton>(find
                        .byWidgetPredicate((widget) => widget is FilledButton))
                    .onPressed,
                isNull);

            final mapa = find.byType(FlutterMap);
            final centro = tester.getCenter(mapa);
            await tester.tapAt(centro + const Offset(-100, -50));
            await tester.pump(const Duration(milliseconds: 350));
            await tester.pumpAndSettle();
            expect(tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
                hasLength(1));

            await tester.tapAt(centro + const Offset(80, -40));
            await tester.pump(const Duration(milliseconds: 350));
            await tester.pumpAndSettle();
            expect(find.byType(PolylineLayer), findsOneWidget);
            expect(find.byType(PolygonLayer), findsNothing);

            await tester.tapAt(centro + const Offset(-60, 80));
            await tester.pump(const Duration(milliseconds: 350));
            await tester.pumpAndSettle();
            expect(find.byType(PolylineLayer), findsNothing);
            final vertices = tester
                .widget<PolygonLayer>(find.byType(PolygonLayer))
                .polygons
                .single
                .points;
            expect(vertices, hasLength(3));
            final camera = tester.widget<FlutterMap>(mapa).mapController!;
            final zoom = camera.camera.zoom;
            await tester.tap(find.byTooltip('Afastar mapa'));
            await tester.pumpAndSettle(const Duration(milliseconds: 350));
            expect(camera.camera.zoom, closeTo(zoom - 1, 0.001));

            await tester.tap(find.byTooltip('Editar por raio'));
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('raioEmEdicao')), findsOneWidget);
            await tester.tap(find.byTooltip('Editar por região'));
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<PolygonLayer>(find.byType(PolygonLayer))
                  .polygons
                  .single
                  .points,
              vertices,
            );

            await tester.tap(find.text('Atualizar'));
            await tester.pumpAndSettle();
            final salvo = repository.territoriosSalvos.single;
            expect(salvo.tipoCobertura, 'regiao');
            expect(salvo.regioes, hasLength(3));
            expect(salvo.raioKm, isNull);

            await _abrirEditor(tester, controller, salvo);
            expect(find.byType(PolygonLayer), findsOneWidget);
            await tester.tap(find.byTooltip('Limpar pontos'));
            await tester.pumpAndSettle();
            expect(find.byType(PolygonLayer), findsNothing);
            expect(tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
                isEmpty);
          }, _criarClienteDeTiles));

  testWidgets(
      'edição mostra o fornecedor fixo e valida o raio antes de salvar',
      (tester) => http.runWithClient(() async {
            repository.territorios = [
              _territorio(id: 't', descricao: 'Centro'),
            ];
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(760, 500);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await _abrirGerenciarTerritorios(tester, controller);
            await tester.tap(find.byTooltip('Editar'));
            await tester.pumpAndSettle();

            expect(find.text('Fornecedor vinculado'), findsOneWidget);
            expect(find.text('Fornecedor A'), findsWidgets);
            expect(find.byType(DropdownButtonFormField<String>), findsNothing);

            final raio = find.byType(TextFormField).first;
            await tester.enterText(raio, '0');
            await tester.tap(find.text('Salvar alterações'));
            await tester.pumpAndSettle();
            expect(
                find.text('Informe um raio maior que zero.'), findsOneWidget);
            expect(repository.territoriosSalvos, isEmpty);

            await tester.enterText(raio, '85,5');
            await tester.pumpAndSettle(const Duration(milliseconds: 250));
            final previa = find.byKey(const ValueKey('mapaPreviaCobertura'));
            final circuloPrevia = find.descendant(
              of: previa,
              matching: find.byType(CircleLayer),
            );
            expect(
              tester.widget<CircleLayer>(circuloPrevia).circles.single.radius,
              85500,
            );
            expect(repository.territoriosSalvos, isEmpty);
            await tester.tap(find.text('Salvar alterações'));
            await tester.pumpAndSettle();
            final salvo = repository.territoriosSalvos.single;
            expect(salvo.idFornecedor, 'fornecedor-1');
            expect(salvo.idTerritorio, 't');
            expect(salvo.raioKm, 85.5);
            expect(find.text('Editar território'), findsNothing);
            expect(
              tester
                  .widget<CircleLayer>(find.byType(CircleLayer))
                  .circles
                  .single
                  .radius,
              85500,
            );
          }, _criarClienteDeTiles));

  testWidgets(
      'edição lateral atualiza a prévia, bloqueia o fundo e permite cancelar',
      (tester) => http.runWithClient(() async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(1600, 900);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            Get.testMode = false;
            final territorio =
                _territorio(id: 't', descricao: 'Centro').copyWith(raioKm: 85);
            repository.territorios = [territorio];
            await _abrirGerenciarTerritorios(tester, controller);
            final mapa = find.byType(FlutterMap);
            final circulo = find.byType(CircleLayer);
            final cameraAnterior = controller.mapController.camera;
            final aproximar =
                tester.getCenter(find.byTooltip('Aproximar mapa'));
            final novoTerritorio =
                tester.getCenter(find.byType(FloatingActionButton));

            await tester.tap(find.byTooltip('Editar'));
            await tester.pumpAndSettle(const Duration(milliseconds: 250));
            final raio = find.byType(TextFormField).first;
            expect(tester.getTopRight(raio).dx,
                lessThan(tester.getTopLeft(mapa).dx));
            final zoomInicial = controller.mapController.camera.zoom;
            expect(find.text('Prévia da cobertura'), findsOneWidget);

            await tester.enterText(raio, '45');
            await tester.pumpAndSettle(const Duration(milliseconds: 250));
            expect(tester.widget<CircleLayer>(circulo).circles.single.radius,
                45000);
            expect(
                controller.mapController.camera.zoom, greaterThan(zoomInicial));
            final zoomPrevia = controller.mapController.camera.zoom;

            await tester.tapAt(aproximar);
            await tester.pumpAndSettle();
            await tester.tapAt(novoTerritorio);
            await tester.pumpAndSettle();
            expect(find.text('Editar território'), findsOneWidget);
            expect(find.text('Novo território'), findsNothing);
            expect(controller.mapController.camera.zoom, zoomPrevia);
            expect(controller.previaCobertura?.raioKm, 45);

            await tester.enterText(raio, '');
            await tester.pumpAndSettle(const Duration(milliseconds: 250));
            expect(tester.widget<CircleLayer>(circulo).circles.single.radius,
                45000);
            expect(controller.territorios.single.raioKm, 85);

            await tester.tap(find.text('Cancelar'));
            await tester.pumpAndSettle();
            expect(repository.territoriosSalvos, isEmpty);
            expect(controller.previaCobertura, isNull);
            expect(tester.widget<CircleLayer>(circulo).circles, isEmpty);
            expect(tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
                hasLength(1));
            expect(
                controller.mapController.camera.center, cameraAnterior.center);
            expect(controller.mapController.camera.zoom, cameraAnterior.zoom);
          }, _criarClienteDeTiles));

  testWidgets(
      'criação seleciona o fornecedor e usa a cobertura desenhada antes de gravar',
      (tester) => http.runWithClient(() async {
            await _abrirGerenciarTerritorios(tester, controller);
            await tester.tap(find.byType(FloatingActionButton));
            await tester.pumpAndSettle();

            await tester.tap(find.byType(DropdownButtonFormField<String>));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Fornecedor B').last);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Criar território'));
            await tester.pumpAndSettle();
            expect(repository.territoriosSalvos, isEmpty);
            expect(
              find.text('Defina a cobertura no mapa para criar o território.'),
              findsOneWidget,
            );

            await tester.tap(find.text('Definir no mapa'));
            await tester.pumpAndSettle();
            final mapa = find.byType(FlutterMap).last;
            await tester.tapAt(tester.getCenter(mapa) + const Offset(-90, 12));
            await tester.pumpAndSettle(const Duration(milliseconds: 350));
            await tester.tap(find.text('Usar cobertura'));
            await tester.pumpAndSettle();
            expect(repository.territoriosSalvos, isEmpty);
            expect(find.text('Editar no mapa'), findsOneWidget);
            expect(controller.previaCobertura?.latitude, isNotNull);
            expect(controller.previaCobertura?.longitude, isNotNull);

            await tester.tap(find.text('Criar território'));
            await tester.pumpAndSettle();
            final salvo = repository.territoriosSalvos.single;
            expect(salvo.idFornecedor, 'fornecedor-2');
            expect(salvo.latitude, isNotNull);
            expect(salvo.longitude, isNotNull);
          }, _criarClienteDeTiles));

  test('filters by status and search text', () {
    controller.territorios.assignAll([
      _territorio(id: 'a', descricao: 'Curitiba', ativo: true),
      _territorio(id: 'b', descricao: 'Maringá', ativo: false),
    ]);

    controller.definirFiltroStatus(FiltroStatusTerritorio.ativos);
    expect(controller.territoriosFiltrados.map((t) => t.idTerritorio), ['a']);

    controller.definirFiltroStatus(FiltroStatusTerritorio.todos);
    controller.atualizarBusca('maring');
    expect(
      controller
          .filtrarComNomes((_) => 'Fornecedor X')
          .map((t) => t.idTerritorio),
      ['b'],
    );
  });

  test('toggles active state and reloads territories', () async {
    final territorio = _territorio(id: 'territorio-1', descricao: 'Zona Sul');

    await controller.toggleAtivo(territorio, false);

    expect(repository.alteracoesAtivo, {'territorio-1': false});
    expect(repository.listarChamadas, 1);
  });

  test('keeps current empty behavior when loading fails', () async {
    repository.error = StateError('failure');

    await controller.carregarTerritorios();

    expect(controller.territorios, isEmpty);
  });
}

Future<void> _abrirGerenciarTerritorios(
    WidgetTester tester, AdminTerritorioController controller) async {
  final runtimeFetching = GoogleFonts.config.allowRuntimeFetching;
  GoogleFonts.config.allowRuntimeFetching = false;
  addTearDown(() => GoogleFonts.config.allowRuntimeFetching = runtimeFetching);
  final fornecedores = _FornecedorControllerFake();
  for (final (id, nome) in [
    ('fornecedor-1', 'Fornecedor A'),
    ('fornecedor-2', 'Fornecedor B'),
  ]) {
    fornecedores.fornecedores.add(Fornecedor(
      idFornecedor: id,
      idUsuario: id,
      razaoSocial: nome,
      telefone: '',
      email: '',
      dataCadastro: DateTime(2026, 1, 1),
    ));
  }
  await tester.pumpWidget(MaterialApp(
    home: AdminTerritorioScreen(
      controller: controller,
      fornecedorController: fornecedores,
      themeController: EventThemeController(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _abrirEditor(WidgetTester tester,
    AdminTerritorioController controller, Territorio existente) async {
  final runtimeFetching = GoogleFonts.config.allowRuntimeFetching;
  GoogleFonts.config.allowRuntimeFetching = false;
  addTearDown(() => GoogleFonts.config.allowRuntimeFetching = runtimeFetching);
  final tema = EventThemeController();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showAddTerritorioBottomSheet(
            context,
            existente.idFornecedor,
            theme: tema,
            controller: controller,
            existente: existente,
          ),
          child: const Text('Abrir editor'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Abrir editor'));
  await tester.pumpAndSettle();
}

void _verificarCirculoVisivel(
    MapCamera camera, Territorio territorio, double raio) {
  final centro = LatLng(territorio.latitude!, territorio.longitude!);
  final ponto = camera.getOffsetFromOrigin(centro);
  final sul = const Distance().offset(centro, raio, 180);
  final raioNaTela = (camera.getOffsetFromOrigin(sul) - ponto).distance;
  expect(ponto.dx - raioNaTela, greaterThan(0));
  expect(ponto.dx + raioNaTela, lessThan(camera.nonRotatedSize.x));
  expect(ponto.dy - raioNaTela, greaterThan(0));
  expect(ponto.dy + raioNaTela, lessThan(camera.nonRotatedSize.y));
}

http.Client _criarClienteDeTiles() {
  // Imagem transparente de 1×1 para testar o mapa sem acesso à rede.
  final imagem =
      base64Decode('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7');
  return MockClient((_) async => http.Response.bytes(imagem, 200));
}

class _FornecedorControllerFake extends Fake implements FornecedorController {
  @override
  final fornecedores = <Fornecedor>[].obs;
}

Territorio _territorio({
  required String id,
  required String descricao,
  bool ativo = true,
}) {
  return Territorio(
    idTerritorio: id,
    idFornecedor: 'fornecedor-1',
    descricao: descricao,
    ativo: ativo,
    tipoCobertura: 'raio',
    latitude: -23.5,
    longitude: -46.6,
    raioKm: 10,
  );
}

class _AdminTerritorioRepositoryFake implements AdminTerritorioRepository {
  List<Territorio> territorios = [];
  final territoriosSalvos = <Territorio>[];
  final alteracoesAtivo = <String, bool>{};
  Object? error;
  int listarChamadas = 0;

  @override
  Future<List<Territorio>> listarTerritorios() async {
    listarChamadas++;
    final currentError = error;
    if (currentError != null) throw currentError;
    return territorios;
  }

  @override
  Future<void> salvarTerritorio(Territorio territorio) async {
    territoriosSalvos.add(territorio);
    final indice = territorios
        .indexWhere((t) => t.idTerritorio == territorio.idTerritorio);
    if (indice < 0) {
      territorios.add(territorio);
    } else {
      territorios[indice] = territorio;
    }
  }

  @override
  Future<void> atualizarAtivo(String idTerritorio, bool ativo) async {
    alteracoesAtivo[idTerritorio] = ativo;
  }
}
