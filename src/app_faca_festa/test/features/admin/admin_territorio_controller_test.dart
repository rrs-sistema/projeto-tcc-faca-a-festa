import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/territorio.dart';
import 'package:app_faca_festa/domain/repositories/admin_territorio_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_admin_territorios.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/territorio/admin_territorio_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
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
      'enquadra o território selecionado e permite ajustar o zoom',
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
            expect(tester.widget<CircleLayer>(circulos).circles, hasLength(2));

            await tester.tap(find.text('Território inativo'));
            await tester.pumpAndSettle();
            final cameraFocada = mapa.camera;
            expect(cameraFocada.center.latitude, closeTo(-23.5, 0.01));
            expect(cameraFocada.center.longitude, closeTo(-46.6, 0.01));
            expect(cameraFocada.zoom, greaterThan(zoomGeral));
            expect(tester.widget<CircleLayer>(circulos).circles, hasLength(1));

            await tester.tap(find.byTooltip('Aproximar mapa'));
            await tester.pumpAndSettle();
            expect(mapa.camera.zoom, closeTo(cameraFocada.zoom + 1, 0.001));
            expect(mapa.camera.center, cameraFocada.center);

            await tester.tap(find.byTooltip('Afastar mapa'));
            await tester.pumpAndSettle();
            expect(mapa.camera.zoom, closeTo(cameraFocada.zoom, 0.001));

            await tester.tap(find.text('Ver todos'));
            await tester.pumpAndSettle();
            expect(mapa.camera.zoom, closeTo(zoomGeral, 0.001));
            expect(tester.widget<CircleLayer>(circulos).circles, hasLength(2));
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
  }

  @override
  Future<void> atualizarAtivo(String idTerritorio, bool ativo) async {
    alteracoesAtivo[idTerritorio] = ativo;
  }
}
