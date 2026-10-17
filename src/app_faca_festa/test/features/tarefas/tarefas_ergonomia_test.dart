import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/tarefa.dart';
import 'package:app_faca_festa/presentation/modules/checklist/pages/tarefa_dialog.dart';
import 'package:app_faca_festa/presentation/modules/checklist/pages/responsavel_picker.dart';
import 'package:app_faca_festa/presentation/modules/checklist/pages/tarefas_screen.dart';
import 'package:app_faca_festa/presentation/modules/checklist/controllers/tarefa_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';

Convidado pessoa(String id, String nome, {String? grupo}) => Convidado(
    idConvidado: id,
    idEvento: 'evento',
    nome: nome,
    nomeGrupo: grupo,
    contato: '',
    dataCadastro: DateTime(2026),
    dataAtualizacao: DateTime(2026));

final pessoas = [
  pessoa('kk', 'Kamilly Ketully'),
  pessoa('junior', 'Júnior', grupo: 'Equipe cozinha'),
  for (var i = 0; i < 300; i++) pessoa('p$i', 'Convidado $i'),
];
final captura = GlobalKey();

Future<void> screenshot(WidgetTester tester, String nome) async {
  if (Platform.environment['TAREFAS_PREVIEW'] != '1') return;
  await tester.runAsync(() async {
    final boundary =
        captura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.codex_tmp/tarefas/$nome.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> preparar(WidgetTester tester, Widget home,
    {Size size = const Size(420, 900), double scale = 1}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(RepaintBoundary(
      key: captura,
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'PreviewFont',
              colorScheme:
                  ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32))),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!),
          home: home)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
    // Use the bundled font for readable optional previews, without network access.
    final bytes = await File('assets/fonts/NotoSans-Regular.ttf').readAsBytes();
    final fontAssets = {
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'preview/Poppins-$weight.ttf': [
          {'asset': 'preview/Poppins-$weight.ttf'}
        ],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final asset = const StringCodec().decodeMessage(message);
      if (asset == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage(fontAssets);
      }
      if (asset?.startsWith('preview/') ?? false) {
        return ByteData.sublistView(bytes);
      }
      return null;
    });
    for (final weight in [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700
    ]) {
      GoogleFonts.poppins(fontWeight: weight);
    }
    await GoogleFonts.pendingFonts();
    for (final family in [
      'PreviewFont',
      'Poppins_regular',
      'Poppins_medium',
      'Poppins_semiBold',
      'Poppins_bold'
    ]) {
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });

  testWidgets('search scales to hundreds of guests and ignores accents',
      (tester) async {
    await preparar(
        tester,
        Scaffold(
            body: ResponsavelPicker(
                pessoas: pessoas,
                primary: const Color(0xFF2E7D32),
                selecionadoId: 'kk')));
    expect(find.byType(ListTile).evaluate().length, lessThan(30));
    await tester.enterText(find.byType(TextField), 'junior');
    await tester.pumpAndSettle();
    expect(find.text('Júnior'), findsOneWidget);
    expect(find.text('1 pessoa'), findsOneWidget);
    await screenshot(tester, 'responsaveis');
    await tester.enterText(find.byType(TextField), 'cozinha');
    await tester.pumpAndSettle();
    expect(find.text('Júnior'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'nao existe');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nenhuma pessoa encontrada'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pumpAndSettle();
    expect(find.text('302 pessoas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'form keeps save visible, selects a guest and preserves choice on cancel',
      (tester) async {
    final theme = EventThemeController()
      ..primaryColor.value = const Color(0xFF2E7D32);
    Convidado? salvo;
    await preparar(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: Center(
                    child: TextButton(
                        onPressed: () => showTarefaDialog(
                            context: context,
                            themeController: theme,
                            idUsuarioLogado: 'kk',
                            idEvento: 'evento',
                            usuarios: pessoas,
                            tituloInicial: 'Equipe cozinha',
                            descricaoInicial: 'Montar a equipe da cozinha',
                            onSave:
                                (titulo, descricao, data, responsavel) async {
                              salvo = responsavel;
                              return null;
                            }),
                        child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Kamilly Ketully'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(tester.getRect(find.text('Salvar tarefa')).bottom, lessThan(900));
    await screenshot(tester, 'formulario');
    await tester.tap(find.text('Toque para trocar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'junior');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Júnior'));
    await tester.pumpAndSettle();
    expect(find.text('Júnior'), findsOneWidget);
    await tester.tap(find.text('Toque para trocar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fechar seleção'));
    await tester.pumpAndSettle();
    expect(find.text('Júnior'), findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Salvar tarefa')).bottom, lessThan(600));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Salvar tarefa'));
    await tester.pumpAndSettle();
    expect(salvo?.idConvidado, 'junior');
    tester.view.resetViewInsets();
  });

  testWidgets('small display and enlarged text keep the form usable',
      (tester) async {
    await preparar(
        tester,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showTarefaDialog(
                        context: context,
                        themeController: EventThemeController(),
                        idUsuarioLogado: null,
                        idEvento: 'evento',
                        usuarios: pessoas,
                        onSave: (_, __, ___, ____) async => 'erro'),
                    child: const Text('Abrir')))),
        size: const Size(320, 640),
        scale: 1.5);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Salvar tarefa'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o responsável pela tarefa.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'task cards show responsible and date separately without overflow',
      (tester) async {
    final controller = _TarefasFake();
    controller.tarefas.addAll([
      Tarefa(
          idTarefa: '1',
          idEvento: 'evento',
          titulo: 'Equipe cozinha',
          descricao: 'Montar a equipe da cozinha',
          idResponsavel: 'kk',
          dataPrevista: DateTime.now().add(const Duration(days: 3))),
      Tarefa(
          idTarefa: '2',
          idEvento: 'evento',
          titulo: 'Disponibilidade do estacionamento',
          descricao: 'Verificar disponibilidade da chácara',
          idResponsavel: 'junior',
          status: StatusTarefa.emAndamento),
    ]);
    final theme = EventThemeController()
      ..primaryColor.value = const Color(0xFF2E7D32)
      ..gradient.value =
          const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF81952B)]);
    final screen = TarefasScreen(
        themeController: theme,
        tarefaController: controller,
        eventoController: _EventoFake(),
        convidadoController: _ConvidadosFake(),
        appController: _AppFake());
    await preparar(tester, screen);
    expect(find.text('Kamilly Ketully'), findsOneWidget);
    expect(find.text('Júnior'), findsOneWidget);
    expect(find.text('Em andamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await screenshot(tester, 'listagem');
    await preparar(tester, screen, size: const Size(320, 640), scale: 1.5);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _TarefasFake extends Fake implements TarefaController {
  @override
  final tarefas = <Tarefa>[].obs;
  @override
  final usuarios = pessoas.obs;
  @override
  final carregando = false.obs;
  @override
  List<Tarefa> get tarefasPendentesOrdenadas =>
      tarefas.where((t) => t.status != StatusTarefa.concluida).toList();
  @override
  int get total => tarefas.length;
  @override
  double get progresso => 0;
  @override
  Future<void> carregarUsuarios({String? idEvento}) async {}
}

class _ConvidadosFake extends Fake implements ConvidadoController {
  @override
  final convidados = pessoas.obs;
}

class _EventoFake extends Fake implements EventoController {}

class _AppFake extends Fake implements AppController {}
