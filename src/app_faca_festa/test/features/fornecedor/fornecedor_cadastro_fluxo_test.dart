import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_faca_festa/data/models/fornecedor/fornecedor_admin_snapshot.dart'
    as dados;
import 'package:app_faca_festa/data/models/fornecedor/fornecedor_model.dart';
import 'package:app_faca_festa/data/models/endereco/endereco_usuario.dart';
import 'package:app_faca_festa/data/models/servico_produto/categoria_servico_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/subcategoria_servico_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/fornecedor_categoria_model.dart';
import 'package:app_faca_festa/data/models/servico_produto/fornecedor_produto_servico_model.dart';
import 'package:app_faca_festa/domain/entities/categoria_servico.dart';
import 'package:app_faca_festa/domain/entities/subcategoria_servico.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_cadastro_edicao.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/usuario.dart';
import 'package:app_faca_festa/domain/entities/endereco_usuario.dart';
import 'package:app_faca_festa/domain/repositories/fornecedor_repository.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_servico_repository.dart';
import 'package:app_faca_festa/domain/repositories/servico_produto_repository.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';
import 'package:app_faca_festa/domain/repositories/perfil_usuario_repository.dart';
import 'package:app_faca_festa/domain/repositories/uf_cidade_repository.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_catalogo_servico.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_ufs_cidades.dart';
import 'package:app_faca_festa/presentation/modules/app/controllers/app_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/controllers/register_controller.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/register_fornecedor_form.dart';
import 'package:app_faca_festa/presentation/modules/auth/pages/components/categoria_subcategoria_servico_section.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/pages/fornecedor/components/editar_fornecedor_cadastro_page.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/categoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/subcategoria_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/catalogo/controllers/servico_produto_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_ai_controller.dart';
import 'package:app_faca_festa/presentation/modules/usuario/controllers/uf_cidade_controller.dart';

const categoria = CategoriaServico(id: 'cat', nome: 'Buffet');
const subcategoria =
    SubcategoriaServico(id: 'sub', idCategoria: 'cat', nome: 'Refeições');
const servico = ServicoProduto(
    id: 'serv', nome: 'Churrasco', idSubcategoria: 'sub', ativo: true);

class _Catalogo extends Fake implements CatalogoServicoRepository {
  final categorias = <CategoriaServico>[categoria];
  final subcategorias = <SubcategoriaServico>[subcategoria];
  bool falharSubcategorias = false;
  @override
  Future<List<CategoriaServico>> listarCategorias() async => categorias;
  @override
  Future<List<SubcategoriaServico>> listarSubcategorias(
      {String? idCategoria}) async {
    if (falharSubcategorias) throw StateError('Falha no catálogo');
    return subcategorias;
  }
}

class _Servicos extends Fake implements ServicoProdutoRepository {
  final itens = <ServicoProduto>[servico];
  @override
  Future<List<ServicoProduto>> listarServicos() async => itens;
}

class _Auth extends Fake implements AutenticacaoRepository {
  int criacoes = 0;
  @override
  Future<String> criarUsuario(
      {required String email, required String senha}) async {
    criacoes++;
    throw StateError('Edição tentou criar conta');
  }
}

class _Perfil extends Fake implements PerfilUsuarioRepository {}

class _Ufs extends Fake implements UfCidadeRepository {}

class _Cep extends Fake implements BuscarCepService {}

class _App extends Fake implements AppController {
  @override
  final usuarioLogado = Rx<Usuario?>(const Usuario(
      idUsuario: 'admin',
      nome: 'Admin Teste',
      email: 'admin@teste.com',
      tipo: 'A'));
}

class _Ai extends Fake implements FornecedorAiController {
  @override
  void vincular(
      {required Fornecedor? Function() fornecedorAtual,
      required List<FornecedorServicoDetalhado> Function() servicosDetalhados,
      required Future<List<Cotacao>> Function() solicitacoesPendentes}) {}
}

class _Repositorio extends Fake implements FornecedorRepository {
  bool falhar = false;
  int escritas = 0;
  Completer<void>? aguardar;
  FornecedorCadastroAlteracao? salvo;
  late final snapshot = dados.FornecedorAdminSnapshot(
    fornecedores: <FornecedorModel>[
      FornecedorModel.fromEntity(origem.fornecedor)
    ],
    enderecos: <EnderecoUsuarioModel>[
      EnderecoUsuarioModel.fromEntity(origem.endereco!)
    ],
    categoriasFornecedor:
        origem.categorias.map(FornecedorCategoriaModel.fromEntity).toList(),
    categorias: <CategoriaServicoModel>[
      CategoriaServicoModel.fromEntity(categoria)
    ],
    subcategorias: <SubcategoriaServicoModel>[
      SubcategoriaServicoModel.fromEntity(subcategoria)
    ],
    servicosFornecedor:
        origem.vinculos.map(FornecedorProdutoServicoModel.fromEntity).toList(),
  );
  @override
  Future<dados.FornecedorAdminSnapshot> carregarSnapshotAdmin(
          {required bool incluirEnderecos}) async =>
      snapshot;
  final origem = FornecedorCadastroEdicao(
    fornecedor: Fornecedor(
        idFornecedor: 'forn',
        idUsuario: 'dono',
        razaoSocial: 'Buffet Teste',
        email: 'comercial@teste.com',
        telefone: '44987654321',
        cnpj: '11222333000181',
        descricao: 'Buffet completo para festas',
        dataCadastro: DateTime(2026),
        ativo: true,
        aptoParaOperar: true,
        tipoEventoIds: const [
          '302191a2-dbf3-4ac6-ba53-08273b384cab',
          'tipo-legado'
        ],
        tipoEventoSlugs: const [
          'casamento',
          'legado'
        ],
        tipoEventoNomes: const [
          'Casamento',
          'Legado'
        ]),
    usuario: const Usuario(
        idUsuario: 'dono',
        nome: 'Responsável Teste',
        email: 'login@teste.com',
        tipo: 'F'),
    endereco: const EnderecoUsuario(
        id: 'end-existente',
        idUsuario: 'dono',
        idCidade: 123,
        cep: '87010000',
        logradouro: 'Rua das Flores',
        numero: '123',
        bairro: 'Centro',
        nomeCidade: 'Maringá',
        uf: 'PR'),
    categorias: const [
      FornecedorCategoria(
          idFornecedor: 'forn',
          idCategoria: 'cat',
          nomeCategoria: 'Buffet',
          subcategorias: [
            FornecedorSubcategoriaResumo(
                idSubcategoria: 'sub', nomeSubcategoria: 'Refeições')
          ])
    ],
    vinculos: [
      FornecedorProdutoServico(
          id: 'vinculo-antigo',
          idFornecedor: 'forn',
          idProdutoServico: 'serv',
          idSubcategoria: 'sub',
          preco: 120)
    ],
    revisao: 3,
  );
  @override
  Future<FornecedorCadastroEdicao> carregarCadastroEdicao(
          String idFornecedor) async =>
      origem;
  @override
  Future<void> salvarCadastroEdicao(
      FornecedorCadastroAlteracao alteracao) async {
    escritas++;
    if (aguardar != null) await aguardar!.future;
    if (falhar) throw StateError('Falha na gravação de teste');
    salvo = alteracao;
  }
}

class _Contexto {
  final repo = _Repositorio();
  final auth = _Auth();
  final app = _App();
  late final fornecedores = GerenciarFornecedores(repo);
  final catalogoFonte = _Catalogo();
  final servicosFonte = _Servicos();
  late final catalogo = GerenciarCatalogoServico(catalogoFonte);
  late final servicos = GerenciarServicosProduto(servicosFonte);
  late final controller = FornecedorController(
      ai: _Ai(), gerenciarFornecedores: fornecedores, appController: app)
    ..fornecedores.add(repo.origem.fornecedor);
  RegisterController criar() => RegisterController(
      autenticacaoRepository: auth,
      perfilUsuarioRepository: _Perfil(),
      fornecedores: fornecedores,
      servicosProduto: servicos,
      catalogoServico: catalogo,
      appController: app,
      buscarCepService: _Cep(),
      ufCidadeController:
          UFCidadeController(ufsCidades: GerenciarUfsCidades(_Ufs())));
  Widget pagina() => EditarFornecedorCadastroPage(
      idFornecedor: 'forn',
      controller: controller,
      categorias: CategoriaServicoController(catalogo: catalogo),
      subcategorias: SubcategoriaServicoController(catalogo: catalogo),
      servicos: ServicoProdutoController(servicos: servicos),
      criarFormulario: criar);
}

Future<void> _abrir(WidgetTester tester, _Contexto c,
    {Size tamanho = const Size(1100, 1000), double escala = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = tamanho;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(RepaintBoundary(
      key: const ValueKey('captura-fornecedor-atuacao'),
      child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Poppins',
              colorSchemeSeed: Colors.teal),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                        child: const Text('Editar dados'),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => c.pagina())),
                      ))))));
  await tester.tap(find.text('Editar dados'));
  await tester.pumpAndSettle();
}

Future<void> _continuar(WidgetTester tester) async {
  final botao = find.text('Continuar');
  await tester.ensureVisible(botao);
  await tester.pumpAndSettle();
  await tester.tap(botao);
  await tester.pumpAndSettle();
}

Future<void> _tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capturarAtuacao(WidgetTester tester, String nome) async {
  if (!const bool.fromEnvironment('CAPTURAS_ATUACAO')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('captura-fornecedor-atuacao')));
  await tester.runAsync(() async {
    final imagem = await boundary.toImage();
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    final arquivo = File('.dart_tool/capturas-fornecedor-atuacao/$nome.png');
    await arquivo.parent.create(recursive: true);
    await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
    imagem.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final variant in {
      'regular': 'Regular',
      '500': 'Medium',
      '600': 'SemiBold',
      '700': 'Bold'
    }.entries) {
      await (FontLoader('Poppins_${variant.key}')
            ..addFont(
                rootBundle.load('assets/fonts/Poppins-${variant.value}.ttf')))
          .load();
    }
    await (FontLoader('Poppins')
          ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Get.testMode = true;
  });
  tearDown(Get.reset);

  test('lista carregada de models permite ordenar sem alterar o snapshot',
      () async {
    final c = _Contexto();
    c.repo.snapshot.fornecedores.add(FornecedorModel.fromEntity(
        c.repo.origem.fornecedor.copyWith(
            idFornecedor: 'outro',
            idUsuario: 'outro-dono',
            razaoSocial: 'Assessoria Teste',
            ativo: false,
            dataCadastro: DateTime(2027))));
    await c.controller.carregarTodosFornecedores();
    expect(c.controller.erro.value, isEmpty);
    for (final ordem in {
      'nome': ['outro', 'forn'],
      'status': ['forn', 'outro'],
      'recentes': ['outro', 'forn'],
    }.entries) {
      c.controller.ordenacaoSelecionada.value = ordem.key;
      c.controller.ordenarFornecedores();
      expect(c.controller.fornecedores.map((f) => f.idFornecedor), ordem.value);
      expect(c.repo.snapshot.fornecedores.map((f) => f.idFornecedor),
          ['forn', 'outro']);
    }
    c.controller.enderecos.add(c.repo.origem.endereco!.copyWith(id: 'novo'));
    c.controller.categoriasFornecedor.add(const FornecedorCategoria(
        idFornecedor: 'forn', idCategoria: 'nova', nomeCategoria: 'Nova'));
    c.controller.categorias
        .add(const CategoriaServico(id: 'nova', nome: 'Nova'));
    c.controller.subCategorias.add(const SubcategoriaServico(
        id: 'nova-sub', idCategoria: 'nova', nome: 'Nova'));
    c.controller.allServicosFornecedor.add(FornecedorProdutoServico(
        id: 'novo-vinculo',
        idFornecedor: 'forn',
        idProdutoServico: 'novo',
        preco: 0));
    expect(c.repo.snapshot.enderecos, hasLength(1));
    expect(c.repo.snapshot.categoriasFornecedor, hasLength(1));
    expect(c.repo.snapshot.categorias, hasLength(1));
    expect(c.repo.snapshot.subcategorias, hasLength(1));
    expect(c.repo.snapshot.servicosFornecedor, hasLength(1));
  });

  testWidgets(
      'edição após carregar models salva, atualiza a lista e fecha o formulário',
      (tester) async {
    final c = _Contexto();
    await c.controller.carregarTodosFornecedores();
    expect(c.controller.erro.value, isEmpty);
    await _abrir(tester, c);
    expect(find.byType(RegisterFornecedorForm), findsOneWidget);
    expect(
        tester
            .widget<RegisterFornecedorForm>(find.byType(RegisterFornecedorForm))
            .modoEdicao,
        true);
    expect(find.text('Responsável Teste'), findsOneWidget);
    expect(find.textContaining('login@teste.com'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is TextField && w.obscureText),
        findsNothing);
    expect(find.text('Continuar com Google'), findsNothing);
    await _continuar(tester);
    expect(find.text('Buffet Teste'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Buffet Teste'), 'Buffet revisado');
    await _continuar(tester);
    expect(find.text('Rua das Flores'), findsOneWidget);
    await _continuar(tester);
    expect(find.text('Áreas de atuação *'), findsOneWidget);
    expect(find.text('Churrasco'), findsOneWidget);
    await tester.ensureVisible(find.text('Churrasco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Churrasco'));
    await tester.pumpAndSettle();
    final formulario = tester
        .widget<RegisterFornecedorForm>(find.byType(RegisterFornecedorForm));
    expect(formulario.controller.servicosSelecionados, isEmpty);
    expect(find.text('Churrasco'), findsOneWidget);
    await tester.tap(find.text('Churrasco'));
    await tester.pumpAndSettle();
    expect(formulario.controller.servicosSelecionados.single.id, 'serv');
    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.pumpAndSettle();
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(c.repo.escritas, 1);
    expect(c.auth.criacoes, 0);
    expect(c.repo.salvo!.origem.fornecedor.idFornecedor, 'forn');
    expect(c.repo.salvo!.origem.usuario.email, 'login@teste.com');
    expect(c.repo.salvo!.dados.razaoSocial, 'Buffet revisado');
    expect(c.repo.salvo!.endereco.id, 'end-existente');
    expect(c.repo.salvo!.tipoEventoIds, contains('tipo-legado'));
    expect(c.repo.salvo!.servicos.single.id, 'serv');
    expect(c.controller.fornecedores.single.aptoParaOperar, true);
    expect(c.controller.fornecedores.single.razaoSocial, 'Buffet revisado');
    expect(c.controller.enderecos.single.id, 'end-existente');
    expect(c.controller.categoriasFornecedor.single.idCategoria, 'cat');
    expect(c.controller.allServicosFornecedor.single.preco, 120);
    // As alterações locais não modificam as coleções carregadas pelo repositório.
    expect(c.repo.snapshot.fornecedores.single.razaoSocial, 'Buffet Teste');
    expect(c.repo.snapshot.enderecos, hasLength(1));
    expect(c.repo.snapshot.categoriasFornecedor, hasLength(1));
    expect(c.app.usuarioLogado.value!.idUsuario, 'admin');
    expect(find.byType(EditarFornecedorCadastroPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voltar e cancelar preserva rascunho local sem salvar',
      (tester) async {
    final c = _Contexto();
    await _abrir(tester, c);
    await _continuar(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Buffet Teste'),
        'Alteração cancelada');
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    await _continuar(tester);
    expect(find.text('Alteração cancelada'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(c.repo.escritas, 0);
    expect(c.repo.salvo, isNull);
  });

  testWidgets('falha conserva etapa e dados para nova tentativa',
      (tester) async {
    final c = _Contexto();
    c.repo.falhar = true;
    await _abrir(tester, c);
    for (var i = 0; i < 3; i++) {
      await _continuar(tester);
    }
    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.pumpAndSettle();
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(find.text('Falha na gravação de teste'), findsOneWidget);
    expect(tester.takeException(), isA<StateError>());
    expect(find.byType(EditarFornecedorCadastroPage), findsOneWidget);
    c.repo.falhar = false;
    await tester.ensureVisible(salvar);
    await tester.pumpAndSettle();
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(c.repo.salvo, isNotNull);
    expect(c.auth.criacoes, 0);
  });

  testWidgets('cadastro novo mantém senha e Google no mesmo componente',
      (tester) async {
    final c = _Contexto();
    final form = c.criar();
    await tester.pumpWidget(GetMaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: RegisterFornecedorForm(
      controller: form,
      fornecedorController: c.controller,
      picker: ImagePicker(),
      bannerBytes: null,
      onBannerSelected: (_, __) async {},
      primary: Colors.pink,
      categoriaController: CategoriaServicoController(catalogo: c.catalogo),
      subcategoriaController:
          SubcategoriaServicoController(catalogo: c.catalogo),
      servicoController: ServicoProdutoController(servicos: c.servicos),
    )))));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is TextField && w.obscureText),
        findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(
        tester
            .widget<RegisterFornecedorForm>(find.byType(RegisterFornecedorForm))
            .modoEdicao,
        false);
    await tester.pumpWidget(const SizedBox());
    form.enderecoController.value.dispose();
  });

  testWidgets(
      'celular com teclado e fonte ampliada permite percorrer as quatro etapas',
      (tester) async {
    final c = _Contexto();
    await _abrir(tester, c, tamanho: const Size(360, 800), escala: 1.6);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await _continuar(tester);
    }
    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.pumpAndSettle();
    expect(tester.getRect(salvar).bottom, lessThan(520));
    await tester.tap(salvar);
    await tester.pumpAndSettle();
    expect(c.repo.salvo, isNotNull);
    expect(c.auth.criacoes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('salvamento bloqueia cliques repetidos até confirmar',
      (tester) async {
    final c = _Contexto();
    c.repo.aguardar = Completer<void>();
    await _abrir(tester, c);
    for (var i = 0; i < 3; i++) {
      await _continuar(tester);
    }
    final salvar = find.text('Salvar alterações');
    await tester.ensureVisible(salvar);
    await tester.pumpAndSettle();
    await tester.tap(salvar);
    await tester.pump();
    expect(c.repo.escritas, 1);
    expect(c.repo.salvo, isNull);
    expect(find.byType(EditarFornecedorCadastroPage), findsOneWidget);
    c.repo.aguardar!.complete();
    await tester.pumpAndSettle();
    expect(c.repo.escritas, 1);
    expect(find.byType(EditarFornecedorCadastroPage), findsNothing);
  });

  for (final celular in [false, true]) {
    testWidgets(
        'atuação ${celular ? 'celular ampliado' : 'desktop'}: opções completas, agrupadas e sem rolagem horizontal',
        (tester) async {
      final c = _Contexto();
      final nomes = [
        'Música e Iluminação',
        'Beleza e Estética',
        'Espaço e Estrutura',
        'Transporte',
        'Segurança e Apoio',
        'Assessoria e Produção de Eventos'
      ];
      c.catalogoFonte.categorias.addAll([
        for (var i = 0; i < nomes.length; i++)
          CategoriaServico(id: 'cat-$i', nome: nomes[i])
      ]);
      c.catalogoFonte.subcategorias.add(const SubcategoriaServico(
          id: 'sub-transporte',
          idCategoria: 'cat-3',
          nome: 'Transporte executivo para convidados e equipe'));
      c.servicosFonte.itens.addAll([
        for (var i = 0; i < 8; i++)
          ServicoProduto(
              id: 'transporte-$i',
              nome: i == 0
                  ? 'Motorista particular / executivo para eventos e viagens'
                  : 'Traslado executivo para convidados em vans e micro-ônibus $i',
              idSubcategoria: 'sub-transporte',
              ativo: true)
      ]);
      await _abrir(tester, c,
          tamanho: celular ? const Size(390, 900) : const Size(1440, 2200),
          escala: celular ? 1.6 : 1);
      for (var i = 0; i < 3; i++) {
        await _continuar(tester);
      }
      final form = tester
          .widget<RegisterFornecedorForm>(find.byType(RegisterFornecedorForm))
          .controller;
      expect(find.text('Assessoria e Produção de Eventos'), findsOneWidget);
      expect(
          find.byWidgetPredicate((w) =>
              (w is SingleChildScrollView &&
                  w.scrollDirection == Axis.horizontal) ||
              (w is ListView && w.scrollDirection == Axis.horizontal)),
          findsNothing);
      await _tocar(tester, find.byKey(const ValueKey('categoria-cat-3')));
      await _tocar(
          tester, find.byKey(const ValueKey('especialidade-sub-transporte')));
      expect(form.servicosSelecionados.map((s) => s.id), ['serv']);
      expect(
          find.text('Motorista particular / executivo para eventos e viagens'),
          findsOneWidget);
      await _tocar(tester, find.byKey(const ValueKey('servico-transporte-0')));
      expect(
          form.servicosSelecionados.map((s) => s.id), contains('transporte-0'));
      expect(
          form.categoriasSelecionadas
              .firstWhere((cat) => cat.idCategoria == 'cat-3')
              .subcategorias
              .single
              .idSubcategoria,
          'sub-transporte');
      expect(
          form.categoriasSelecionadas
              .firstWhere((cat) => cat.idCategoria == 'cat')
              .subcategorias
              .single
              .idSubcategoria,
          'sub');
      final busca = find.widgetWithText(TextField, 'Buscar serviço');
      await tester.ensureVisible(busca);
      await tester.pumpAndSettle();
      await tester.enterText(busca, 'Motorista');
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Traslado executivo para convidados em vans e micro-ônibus 7'),
          findsNothing);
      expect(form.servicosSelecionados, hasLength(2));
      await _tocar(tester, find.byTooltip('Limpar busca'));
      expect(
          find.text(
              'Traslado executivo para convidados em vans e micro-ônibus 7'),
          findsOneWidget);
      if (!celular) {
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, 3000));
        await tester.pumpAndSettle();
        await _capturarAtuacao(tester, 'desktop');
      } else {
        await tester
            .ensureVisible(find.byKey(const ValueKey('categoria-cat-3')));
        await tester.pumpAndSettle();
        await _capturarAtuacao(tester, 'celular');
      }
      expect(c.repo.escritas, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'falha nas opções mostra nova tentativa e não confirma serviços automaticamente',
      (tester) async {
    final c = _Contexto();
    c.catalogoFonte.falharSubcategorias = true;
    final formulario = c.criar();
    final categorias = CategoriaServicoController(catalogo: c.catalogo)
      ..categorias.assignAll([categoria]);
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Form(
      key: formKey,
      child: CategoriaSubcategoriaServicoSection(
          controller: formulario,
          primary: Colors.teal,
          categoriaController: categorias,
          subcategoriaController:
              SubcategoriaServicoController(catalogo: c.catalogo),
          servicoController: ServicoProdutoController(servicos: c.servicos)),
    )))));
    await _tocar(tester, find.byKey(const ValueKey('categoria-cat')));
    expect(find.textContaining('Não foi possível carregar as opções'),
        findsOneWidget);
    expect(formulario.carregandoAtuacao.value, false);
    expect(formKey.currentState!.validate(), false);
    await tester.pumpAndSettle();
    c.catalogoFonte.falharSubcategorias = false;
    await _tocar(tester, find.text('Tentar novamente'));
    await _tocar(tester, find.byKey(const ValueKey('especialidade-sub')));
    expect(formulario.servicosSelecionados, isEmpty);
    await _tocar(tester, find.byKey(const ValueKey('servico-serv')));
    expect(formKey.currentState!.validate(), true);
    await tester.pumpWidget(const SizedBox());
    formulario.enderecoController.value.dispose();
    expect(tester.takeException(), isNull);
  });
}
