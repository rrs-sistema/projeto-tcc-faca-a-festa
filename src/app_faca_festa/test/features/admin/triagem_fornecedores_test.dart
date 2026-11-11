import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/presentation/modules/admin/controllers/admin_territorio_controller.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_foto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/components/fornecedor_list_tile.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/fornecedores_admin_list_screen.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_localizacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class _Fornecedores extends Fake implements FornecedorController {
  @override
  final fornecedores = [
    Fornecedor(
        idFornecedor: 'a',
        idUsuario: 'a',
        razaoSocial: '',
        telefone: '',
        email: '',
        dataCadastro: DateTime(2026, 1, 1),
        aptoParaOperar: true),
    Fornecedor(
        idFornecedor: 'b',
        idUsuario: 'b',
        razaoSocial: 'Buffet Horizonte',
        telefone: '41999999999',
        email: 'buffet@example.com',
        dataCadastro: DateTime(2026, 1, 1),
        aptoParaOperar: true,
        mediaAvaliacoes: 4.6,
        totalAvaliacoes: 12),
  ].obs;

  @override
  final carregando = false.obs;
  @override
  final erro = ''.obs;
  @override
  final filtroNome = ''.obs;
  @override
  final filtroAtivo = RxnBool();
  @override
  final filtroAprovado = RxnBool();
  @override
  final ordenacaoSelecionada = 'status'.obs;

  @override
  int get totalAptos => fornecedores.length;
  @override
  int get totalPendentes => 0;
  @override
  int get totalInativos => 0;
  @override
  bool get podeEditarDadosFornecedor => !carregando.value;
  @override
  List<Fornecedor> get fornecedoresFiltrados => fornecedores.toList();
  @override
  Future<void> carregarTodosFornecedores() async {}
  @override
  void ordenarFornecedores() {}
  @override
  String cidadeDoFornecedor(Fornecedor f) => 'Curitiba';
  @override
  int servicosDoFornecedor(Fornecedor f) => f.idFornecedor == 'a' ? 0 : 4;
  @override
  List<String> nomesCategoriasDoFornecedor(Fornecedor f) =>
      ['Buffet e gastronomia'];
}

class _App extends Fake implements AppController {}

class _Localizacao extends Fake implements FornecedorLocalizacaoController {}

class _Territorio extends Fake implements AdminTerritorioController {}

class _Categoria extends Fake implements CategoriaServicoController {}

class _Subcategoria extends Fake implements SubcategoriaServicoController {}

class _Avaliacao extends Fake implements AvaliacaoServicoController {}

class _Servicos extends Fake implements ServicoProdutoController {}

class _Fotos extends Fake implements ServicoFotoController {}

class _Gateway implements CallableSessaoGateway {
  int chamadas = 0;
  bool falhar = false;
  @override
  String? get usuario => 'admin';
  @override
  Stream<String?> get sessoes => const Stream.empty();

  @override
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados) async {
    chamadas++;
    expect(funcao, 'consultarTriagemFornecedoresAdminFn');
    expect(dados['ids'], ['a', 'b']);
    if (falhar) throw StateError('Indisponível');
    return {
      'fornecedores': [
        {
          'idFornecedor': 'a',
          'casosAbertos': 0,
          'casosCriticos': 0,
          'semResponsavel': 0,
          'cotacoesVencidas': 0
        },
        {
          'idFornecedor': 'b',
          'casosAbertos': 1,
          'casosCriticos': 1,
          'semResponsavel': 0,
          'casoPrioritarioAtribuido': true,
          'responsavel': 'Maria Costa',
          'cotacoesVencidas': 2,
          'eventoProximoEm': '2026-11-11T18:00:00Z',
          'restricao': {
            'acao': 'restringir',
            'servico': 'Buffet infantil',
            'ate': '2026-11-12T18:00:00Z'
          }
        },
      ],
    };
  }
}

void main() {
  setUpAll(() async {
    for (final entrada in {
      'regular': 'Regular',
      '500': 'Medium',
      '600': 'SemiBold',
      '700': 'Bold',
      '800': 'ExtraBold'
    }.entries) {
      await (FontLoader('Poppins_${entrada.key}')
            ..addFont(
                rootBundle.load('assets/fonts/Poppins-${entrada.value}.ttf')))
          .load();
    }
  });
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(Get.reset);

  Future<void> abrir(WidgetTester tester, _Gateway gateway, Size tamanho,
      {double escala = 1}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = tamanho;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      builder: (ctx, child) => MediaQuery(
        data:
            MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      home: FornecedoresAdminListScreen(
        controller: _Fornecedores(),
        localizacaoController: _Localizacao(),
        adminTerritorioController: _Territorio(),
        appController: _App(),
        categoriaController: _Categoria(),
        subcategoriaController: _Subcategoria(),
        avaliacaoController: _Avaliacao(),
        theme: EventThemeController(),
        servicoProdutoController: _Servicos(),
        servicoFotoController: _Fotos(),
        gatewayTriagem: gateway,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('ordena por urgência e filtra os sinais em uma consulta em lote',
      (tester) async {
    final gateway = _Gateway();
    await abrir(tester, gateway, const Size(1440, 1000));
    expect(find.text('Fornecedor sem nome'), findsOneWidget);
    final ordem = find.byType(DropdownButton<String>);
    await tester.tap(ordem);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urgência operacional').last);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FornecedorListTile>(find.byType(FornecedorListTile).first)
            .fornecedor
            .idFornecedor,
        'b');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Com restrição'));
    await tester.pumpAndSettle();
    expect(find.text('Fornecedor sem nome'), findsNothing);
    expect(find.textContaining('Buffet infantil'), findsOneWidget);
    expect(find.textContaining('Maria Costa'), findsOneWidget);
    expect(find.text('4,6/5 · 12 avaliações verificadas'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cadastro incompleto'));
    await tester.pumpAndSettle();
    expect(find.text('Fornecedor sem nome'), findsOneWidget);
    expect(find.text('Buffet Horizonte'), findsNothing);
    expect(gateway.chamadas, 1);
  });

  testWidgets(
      'mantém cadastro acessível se a triagem falhar e permite repetir no celular',
      (tester) async {
    final gateway = _Gateway()..falhar = true;
    await abrir(tester, gateway, const Size(360, 720), escala: 1.4);
    expect(
        find.text('Indicadores operacionais indisponíveis.'), findsOneWidget);
    expect(find.text('Fornecedor sem nome'), findsOneWidget);
    gateway.falhar = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Indicadores operacionais indisponíveis.'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Precisa de atenção'));
    await tester.pumpAndSettle();
    final menu = find.text('Mais ações').first;
    await tester.scrollUntilVisible(menu, 200,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first);
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(find.text('Editar dados'), findsOneWidget);
    expect(find.text('Território'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
