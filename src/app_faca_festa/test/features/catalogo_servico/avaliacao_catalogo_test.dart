import 'package:app_faca_festa/domain/usecases/gerenciar_fornecedores.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_ai_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/perfil_section.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/fornecedor.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_servico_detalhado.dart';
import 'package:app_faca_festa/domain/entities/servico_foto.dart';
import 'package:app_faca_festa/domain/entities/servico_produto.dart';
import 'package:app_faca_festa/domain/repositories/servico_produto_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_servicos_produto.dart';
import 'package:app_faca_festa/domain/services/avaliacao_catalogo_fornecedor_service.dart';
import 'package:app_faca_festa/data/services/fornecedor_ai_service.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/criterios_catalogo_panel.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/fornecedor_catalogo.dart';

Fornecedor fornecedor() => Fornecedor(
    idFornecedor: 'f',
    idUsuario: 'f',
    razaoSocial: 'Festas',
    telefone: '',
    email: 'teste@example.com',
    dataCadastro: DateTime(2026),
    bannerUrl: 'banner',
    descricao: 'a' * 80,
    categorias: const [FornecedorCategoriaResumo(idCategoria: 'decoracao')],
    tipoEventoNomes: const ['Casamento'],
    precoMinimo: 100);
FornecedorServicoDetalhado oferta(String id) => FornecedorServicoDetalhado(
    id: id,
    idFornecedor: 'f',
    idProdutoServico: id,
    nomeServico: 'Oferta $id',
    preco: 100,
    quantidade: 1,
    ativo: true,
    imagemUrl: 'foto',
    descricaoServico: 'Descrição',
    tipoMedida: 'U');
List<FornecedorServicoDetalhado> completas() =>
    [oferta('1'), oferta('2'), oferta('3')];
const regra = AvaliacaoCatalogoFornecedorService();

class _Repo extends Fake implements ServicoProdutoRepository {
  Completer<List<FornecedorServicoDetalhado>> resposta = Completer();
  @override
  Future<List<ServicoProduto>> listarServicosAtivos() async => [];
  @override
  Future<List<FornecedorServicoDetalhado>> listarServicosComDetalhes(
          {String? idFornecedor}) =>
      resposta.future;
}

class _Fornecedores extends Fake implements GerenciarFornecedores {
  int escutas = 0;
  final stream = StreamController<List<FornecedorProdutoServico>>.broadcast();
  @override
  Stream<List<FornecedorProdutoServico>> observarServicosFornecedor(
      String idFornecedor) {
    escutas++;
    return stream.stream;
  }
}

FornecedorCatalogo _catalogo(_Repo repo, {_Fornecedores? fornecedores}) =>
    FornecedorCatalogo(
        servicosFornecedor: <FornecedorProdutoServico>[].obs,
        servicosDetalhado: <FornecedorServicoDetalhado>[].obs,
        catalogoServicos: <ServicoProduto>[].obs,
        fotosServico: <ServicoFoto>[].obs,
        isLoadingFotos: false.obs,
        carregando: false.obs,
        erro: ''.obs,
        fornecedores: () => fornecedores ?? (throw UnimplementedError()),
        servicosProduto: () => GerenciarServicosProduto(repo),
        fotos: () => throw UnimplementedError(),
        recarregarAi: () async {});

class _Ai extends Fake implements FornecedorAiController {
  @override
  void vincular(
      {required Fornecedor? Function() fornecedorAtual,
      required List<FornecedorServicoDetalhado> Function() servicosDetalhados,
      required Future<List<Cotacao>> Function() solicitacoesPendentes}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    for (final entry in {
      'regular': 'Regular',
      '500': 'Medium',
      '600': 'SemiBold',
      '700': 'Bold',
      '800': 'ExtraBold'
    }.entries) {
      await (FontLoader('Poppins_${entry.key}')
            ..addFont(
                rootBundle.load('assets/fonts/Poppins-${entry.value}.ttf')))
          .load();
    }
    await (FontLoader('CatalogoPoppins')
          ..addFont(rootBundle.load('assets/fonts/Poppins-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('catálogo vazio não ganha pontos de foto, preço, descrição ou medida',
      () {
    final a = regra.avaliar(fornecedor: fornecedor());
    expect(a.score, closeTo(50 / 110 * 100, .0001));
    expect(a.pendentes.map((c) => c.id),
        containsAll(['ofertas', 'fotos', 'descricoes', 'precos', 'medidas']));
    expect(
        a.criterios
            .where((c) => ['fotos', 'precos'].contains(c.id))
            .every((c) => c.pontos == 0),
        isTrue);
  });
  test('100% somente quando todos os critérios estão atendidos', () {
    final a = regra.avaliar(fornecedor: fornecedor(), servicos: completas());
    expect(a.score, 100);
    expect(a.pendentes, isEmpty);
    expect(a.concluidos, 10);
    final faltando = regra.avaliar(
        fornecedor: fornecedor().copyWith(bannerUrl: ''),
        servicos: completas());
    expect(faltando.score, closeTo(100 / 110 * 100, .0001));
    expect(faltando.score, lessThan(100));
    expect(faltando.pendentes.single.id, 'banner');
  });
  test('descrição de 79 e 80 caracteres usa o mesmo limite nas sugestões', () {
    final f = fornecedor().copyWith(descricao: 'a' * 79);
    final a = regra.avaliar(fornecedor: f, servicos: completas());
    final ia = FornecedorAiService()
        .gerarSugestaoMelhoriaCatalogo(fornecedor: f, servicos: completas());
    expect(ia.scoreCatalogo, a.score);
    expect(ia.melhoriasPrioritarias, ['Completar descrição comercial']);
    expect(ia.pendencias.single, contains('79 de 80'));
    expect(
        regra
            .avaliar(fornecedor: fornecedor(), servicos: completas())
            .pendentes,
        isEmpty);
  });
  test('uma oferta recebe pontuação parcial e explica a meta de três', () {
    final a = regra.avaliar(fornecedor: fornecedor(), servicos: [oferta('1')]);
    expect(a.pendentes.single.id, 'ofertas');
    expect(a.pendentes.single.detalhe, contains('1 de 3'));
    expect(a.score, closeTo(103 / 110 * 100, .0001));
    expect(a.impacto(a.pendentes.single) + a.score, closeTo(100, .0001));
  });
  test(
      'todos os serviços ativos precisam de dados; inativos e alheios são excluídos',
      () {
    final lista = [
      ...completas(),
      oferta('4').copyWith(imagemUrl: ''),
      oferta('5').copyWith(ativo: false, preco: 0),
      oferta('6').copyWith(idFornecedor: 'outro', preco: 0)
    ];
    final a = regra.avaliar(fornecedor: fornecedor(), servicos: lista);
    expect(a.servicos.length, 4);
    expect(a.semFoto, 1);
    expect(a.semPreco, 0);
    expect(a.pendentes.single.id, 'fotos');
    expect(a.pendentes.single.detalhe, contains('Oferta 4'));
  });
  test(
      'preço promocional válido é aceito e zero, negativo ou infinito não pontuam',
      () {
    final a = regra.avaliar(
        fornecedor: fornecedor(),
        servicos: [oferta('1').copyWith(preco: 0, precoPromocao: 50)]);
    expect(a.semPreco, 0);
    for (final valor in [0.0, -1.0, double.infinity, double.nan]) {
      final b = regra.avaliar(
          fornecedor: fornecedor(),
          servicos: [oferta('1').copyWith(preco: valor)]);
      expect(b.semPreco, 1);
    }
    expect(
        regra
            .avaliar(fornecedor: fornecedor().copyWith(precoMinimo: 0))
            .pendentes
            .map((c) => c.id),
        contains('faixa'));
  });
  test('escuta inicial consulta os detalhes em vez de assumir zero ofertas',
      () async {
    final f = _Fornecedores(), repo = _Repo();
    final c = _catalogo(repo, fornecedores: f);
    await Future.wait([c.escutar('f'), c.escutar('f')]);
    expect(f.escutas, 1);
    f.stream.add([]);
    await Future<void>.delayed(Duration.zero);
    expect(c.carregandoDetalhes.value, true);
    expect(c.detalhesCarregados.value, false);
    repo.resposta.complete(completas());
    await Future<void>.delayed(Duration.zero);
    expect(c.detalhesCarregados.value, true);
    expect(c.servicosDetalhado.length, 3);
    await c.cancelarEscuta();
    await f.stream.close();
  });
  test('carga inicial distingue desconhecido de catálogo comprovadamente vazio',
      () async {
    final repo = _Repo();
    final real = _catalogo(repo);
    expect(real.detalhesCarregados.value, false);
    final futuro = real.listarComDetalhes('f');
    expect(real.carregandoDetalhes.value, true);
    repo.resposta.complete([]);
    await futuro;
    expect(real.detalhesCarregados.value, true);
    expect(real.carregandoDetalhes.value, false);
    expect(real.servicosDetalhado, isEmpty);
    await real.cancelarEscuta();
  });
  test('falha ou resposta antiga não vira catálogo vazio avaliado', () async {
    final repo = _Repo();
    final real = _catalogo(repo);
    final futuro = real.listarComDetalhes('f');
    await real.cancelarEscuta();
    repo.resposta.complete(completas());
    await futuro;
    expect(real.detalhesCarregados.value, false);
    expect(real.servicosDetalhado, isEmpty);
    repo.resposta = Completer();
    final falha = real.listarComDetalhes('f');
    repo.resposta.completeError(StateError('Indisponível'));
    await falha;
    expect(real.detalhesCarregados.value, false);
    expect(real.erroDetalhes.value, isNotEmpty);
    await real.cancelarEscuta();
  });
  for (final largura in [360.0, 1200.0]) {
    testWidgets(
        'pendências completas, impactos e critérios legíveis em $largura',
        (t) async {
      await t.binding.setSurfaceSize(Size(largura, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final a =
          regra.avaliar(fornecedor: fornecedor().copyWith(descricao: 'Curta'));
      await t.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: CriteriosCatalogoPanel(avaliacao: a)))));
      expect(find.text('O que falta para chegar a 100%'), findsOneWidget);
      expect(find.text('Completar descrição comercial'), findsOneWidget);
      expect(find.text('Criar serviços/produtos'), findsOneWidget);
      expect(find.textContaining('pontos ao completar'),
          findsNWidgets(a.pendentes.length));
      await t.ensureVisible(find.text('Como o percentual é calculado'));
      await t.tap(find.text('Como o percentual é calculado'));
      await t.pumpAndSettle();
      expect(find.text('Todas as ofertas ativas com foto'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
  for (final largura in [360.0, 1200.0]) {
    testWidgets('painel aguarda consulta e explica todos os pontos em $largura',
        (t) async {
      await t.binding.setSurfaceSize(Size(largura, 1800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final repo = _Repo();
      final c = FornecedorController(
          ai: _Ai(), gerenciarServicosProduto: GerenciarServicosProduto(repo));
      c.fornecedor.value = fornecedor().copyWith(descricao: 'Curta');
      await t.pumpWidget(MaterialApp(
        theme: ThemeData(
            fontFamily: 'CatalogoPoppins',
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
        home: Scaffold(
            body: SingleChildScrollView(
                child: Padding(
          padding: const EdgeInsets.all(16),
          child: RepaintBoundary(
              key: const Key('catalogo-validado'),
              child: PerfilSection(controller: c)),
        ))),
      ));
      expect(find.text('Aguardando dados'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(PerfilSection.calcularScoreCatalogo(c), isNull);
      final futuro = c.catalogo.listarComDetalhes('f', atualizarIa: false);
      await t.pump();
      expect(find.text('Atualizando catálogo'), findsOneWidget);
      repo.resposta.complete([]);
      await futuro;
      await t.pumpAndSettle();
      expect(find.text('36,4% preparado'), findsOneWidget);
      expect(find.text('Completar descrição comercial'), findsOneWidget);
      expect(find.text('Criar serviços/produtos'), findsOneWidget);
      expect(find.text('Adicionar imagens aos serviços'), findsOneWidget);
      expect(
          find.textContaining('4 de 10 critérios atendidos'), findsOneWidget);
      expect(PerfilSection.calcularScoreCatalogo(c),
          closeTo(40 / 110 * 100, .0001));
      expect(t.takeException(), isNull);
      await expectLater(
          find.byKey(const Key('catalogo-validado')),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/catalogo-criterios-${largura.toInt()}.png'));
      c.servicosDetalhado.assignAll(completas());
      c.fornecedor.value = fornecedor();
      await t.pumpAndSettle();
      expect(find.text('100,0% preparado'), findsOneWidget);
      expect(find.text('Todos os critérios atendidos'), findsOneWidget);
      expect(find.text('O que falta para chegar a 100%'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await c.catalogo.cancelarEscuta();
    });
  }
}
