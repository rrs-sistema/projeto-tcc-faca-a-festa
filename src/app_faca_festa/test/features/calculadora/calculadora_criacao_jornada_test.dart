import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/repositories/cardapio_repository.dart';
import 'package:app_faca_festa/domain/services/criacao_cardapio_inicial_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'calculadora_composicao_test.dart' show AuthQA, AiQA;
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'catalogo_contextual_test.dart' show referenciaQA;
import 'calculadora_jornada_test.dart'
    show RepoJornada, BaseJornada, CardapioQA, EventoQA, MigracaoQA;

class Usuario extends Fake implements User {
  @override
  String get uid => 'owner';
}

class AuthOwner extends AuthQA {
  @override
  User? get currentUser => Usuario();
}

class Historico extends RepoJornada {
  CriacaoCardapioInicial? gravado;
  @override
  Future<List<CalculadoraFestaItem>> listarItensDaSimulacao(String id) async =>
      gravado?.resultados ?? [];
  @override
  Future<List<CalculadoraFesta>> listarSimulacoesPorEvento(String id) async =>
      gravado == null ? [] : [gravado!.calculo];
}

class MenuInicial extends CardapioQA
    implements CriacaoCardapioInicialRepository {
  MenuInicial(this.historico);
  final Historico historico;
  int chamadas = 0;
  bool falhar = true;
  final atualizacoes = StreamController<List<Cardapio>>.broadcast();
  @override
  Stream<List<Cardapio>> observarCardapios(String idEvento) async* {
    yield [];
    yield* atualizacoes.stream;
  }

  @override
  Stream<List<CardapioItem>> observarItens(String id, {String? idEvento}) =>
      Stream.value(historico.gravado!.itens);
  @override
  Future<bool> criarCardapioInicial(CriacaoCardapioInicial proposta) async {
    chamadas++;
    if (falhar) throw StateError('offline');
    historico.gravado = proposta;
    atualizacoes.add([proposta.cardapio]);
    return true;
  }
}

void main() {
  testWidgets(
      'evento vazio chega à revisão, bloqueia contexto alterado e cria menu e histórico após nova tentativa',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.runAsync(() async {
      for (final peso in [
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
        FontWeight.w900
      ]) {
        GoogleFonts.poppins(fontWeight: peso);
      }
      await GoogleFonts.pendingFonts();
    });
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    final repo = Historico();
    final menusRepo = MenuInicial(repo);
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    final menus = CardapioController(repository: menusRepo);
    final tema = EventThemeController();
    Get.put(tema);
    final captura = GlobalKey();
    addTearDown(() async {
      c.onClose();
      menus.onClose();
      await menusRepo.atualizacoes.close();
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(GetMaterialApp(
        builder: (_, child) => RepaintBoundary(key: captura, child: child!),
        home: CalculadoraFestaScreen(
            idEvento: 'qa',
            tipoEvento: 'Aniversário',
            adultosIniciais: 20,
            calculadoraController: c,
            eventoController: EventoQA(),
            themeController: tema,
            cardapioController: menus,
            fornecedorMigracaoAdminController: MigracaoQA())));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.scrollUntilVisible(find.text('Continuar'), 150,
          scrollable: find
              .descendant(
                  of: find.byKey(const Key('rolagem_calculadora')),
                  matching: find.byType(Scrollable))
              .first);
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }
    final refs = [
      referenciaQA(extra: {
        'id': 'dog_qa',
        'aliases': ['Cachorro-quente'],
        'nome': 'Cachorro-quente',
        'unidade': 'unidade',
        'minimo': 1,
        'maximo': 1,
        'padrao': 1
      }),
      referenciaQA(extra: {
        'id': 'frutas_qa',
        'aliases': ['Frutas'],
        'nome': 'Frutas',
        'minimo': .125,
        'maximo': .125,
        'padrao': .125
      }),
    ];
    final modelo = ReferenciaContextual({
      ...refs.first.dados,
      'id': 'modelo_qa',
      'nome': 'Lanche escolhido',
      'tipo': 'modelo',
      'itens': [
        {'nome': 'Cachorro-quente', 'tipo': 'comida'},
        {'nome': 'Frutas', 'tipo': 'comida'}
      ]
    });
    c.catalogoContextual.value = CatalogoContextual([...refs, modelo]);
    await tester.pumpAndSettle();
    final seletor = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('catalogo_modelo')));
    seletor.onChanged!(modelo.chave);
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      tester
          .widget<DropdownButtonFormField<String>>(
              find.byKey(ValueKey('plano_obtencao_sugestao_$i')))
          .onChanged!('servir');
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
              find.byKey(ValueKey('plano_referencia_sugestao_$i')))
          .onChanged!(refs[i].chave);
      await tester.pumpAndSettle();
    }
    Future<void> abrir() async {
      final botao = find.text('Criar cardápio com esta proposta');
      await tester.ensureVisible(botao);
      await tester.pumpAndSettle();
      await tester.tap(botao);
      await tester.pumpAndSettle();
    }

    await abrir();
    c.totalAdultos.value++;
    await tester.tap(find.text('Criar cardápio'));
    await tester.pumpAndSettle();
    expect(menusRepo.chamadas, 0);
    expect(find.byKey(const Key('erro_criar_cardapio')), findsOneWidget);
    await tester.tap(find.text('Voltar').last);
    await tester.pumpAndSettle();
    await abrir();
    if (Platform.environment['CALCULADORA_QA_CAPTURE'] == '1') {
      await tester.runAsync(() async {
        final boundary =
            captura.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final imagem = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
        final arquivo =
            File('.dart_tool/qa-calculadora/criar-cardapio-inicial.png');
        await arquivo.parent.create(recursive: true);
        await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
        imagem.dispose();
      });
    }
    await tester.tap(find.text('Criar cardápio'));
    await tester.pumpAndSettle();
    expect(menusRepo.chamadas, 1);
    expect(repo.gravado, isNull);
    menusRepo.falhar = false;
    await tester.tap(find.text('Criar cardápio'));
    await tester.pumpAndSettle();
    expect(menusRepo.chamadas, 2);
    expect(
        repo.gravado!.itens
            .every((i) => !i.confirmado && i.quantidadeFinal == 0),
        true);
    expect(menus.cardapios.single.idCardapio, 'plano_inicial_qa');
    expect(c.simulacoesSalvas.length, 1);
    expect(
        c.regrasManuais
            .where((r) => r.premissas['id_cardapio'] == 'plano_inicial_qa')
            .length,
        2);
    await tester
        .runAsync(() => c.carregarSimulacaoNoEditor(repo.gravado!.calculo));
    await tester.pumpAndSettle();
    expect(c.itensCardapio.length, 2);
    expect(c.cardapiosEvento['plano_inicial_qa']!.length, 2);
    expect(c.itensCalculados.map((i) => i.quantidade),
        repo.gravado!.resultados.map((i) => i.quantidade));
    expect(c.consultaCardapiosCompleta.value, true);
    expect(tester.takeException(), isNull);
  });
}
