import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/entities/registro_consumo_calculadora.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/repositories/cardapio_repository.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/fornecedor_migracao_admin_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'calculadora_composicao_test.dart'
    show AuthQA, RepositoryQA, BaseQA, AiQA, catalogoQA;

class EventoQA extends Fake implements EventoController {
  @override
  Evento? get eventoAtualEntidade => null;
  @override
  TipoEvento? get tipoEventoAtualEntidade => null;
}

class MigracaoQA extends Fake implements FornecedorMigracaoAdminController {}

class RepoJornada extends RepositoryQA {
  Map<String, dynamic> operacao = {};
  @override
  Stream<Map<String, dynamic>> observarOperacaoEvento(String id) =>
      Stream.value(operacao);
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) async {
    operacao = const OperacaoCalculadoraService().aplicar(operacao, acao);
    return operacao;
  }

  List<Map<String, dynamic>> gastos = [];
  List<ItemEstimativaFinanceira> receitas = [];
  List<String>? ultimaCobertura;
  @override
  Future<List<ItemEstimativaFinanceira>> listarReceitasDoOrganizador() async =>
      receitas;
  @override
  Future<void> salvarCoberturaOrcamento(
      String id, List<String> identidades) async {
    ultimaCobertura = identidades;
    gastos = gastos
        .map((g) => g['id'] == id
            ? {
                ...g,
                'cobre_itens': identidades,
                'conferencia_financeira': 'revisar',
                'cobertura_identificavel': true
              }
            : g)
        .toList();
  }

  Map<String, dynamic>? ultimaConferencia;
  @override
  Future<void> salvarConferenciaFinanceira(
      String id, Map<String, dynamic> conferencia) async {
    ultimaConferencia = conferencia;
    gastos = gastos
        .map((g) => g['id'] == id
            ? {
                ...g,
                'conferencia_financeira': conferencia['modo'],
                'cobertura_identificavel': conferencia['modo'] == 'sem_itens' ||
                    g['cobertura_identificavel'] == true
              }
            : g)
        .toList();
  }

  @override
  Future<List<RegistroConsumoCalculadora>> listarConsumosDoOrganizador(
          {int limite = 100}) async =>
      [];
  @override
  Future<List<Convidado>> listarConvidadosDoEvento(String id) async => [];
  @override
  Future<List<CalculadoraFesta>> listarSimulacoesPorEvento(String id) async =>
      [];
  @override
  Future<List<Map<String, dynamic>>> listarCompromissosDoEvento(
          String id) async =>
      gastos;
  @override
  Stream<List<Map<String, dynamic>>> observarCompromissosDoEvento(String id) =>
      Stream.value(gastos);
}

class BaseJornada extends BaseQA {
  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback(
          {required String tipoEvento, String? perfilFesta}) async =>
      catalogoQA();
}

class CardapioQA extends Fake implements CardapioRepository {
  CardapioItem? ultimoSalvo;
  void Function(CardapioItem)? aoSalvar;
  @override
  Future<void> salvarItem(String idCardapio, CardapioItem item) async {
    ultimoSalvo = item;
    aoSalvar?.call(item);
  }

  @override
  Future<void> atualizarResumo(
      String idCardapio, ResumoCardapio resumo) async {}
  @override
  Stream<List<Cardapio>> observarCardapios(String idEvento) => Stream.value(
      [const Cardapio(idCardapio: 'almoco', idEvento: 'qa', titulo: 'Almoço')]);
  @override
  Stream<List<CardapioItem>> observarItens(String idCardapio,
          {String? idEvento}) =>
      Stream.value(['Churrasco 🥩', 'Macarrão 🍝', 'Arroz 🍚', 'Refrigerante']
          .map((n) => CardapioItem(
              idItem: n,
              idEvento: 'qa',
              idCardapio: 'almoco',
              nome: n,
              unidade: n == 'Refrigerante' ? 'L' : 'un'))
          .toList());
}

void main() {
  testWidgets('jornada móvel mostra números, detalhes e edição de uma porção',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.runAsync(() async {
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      await (FontLoader('Roboto')
            ..addFont(rootBundle.load('assets/fonts/NotoSans-Regular.ttf')))
          .load();
    });
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthQA());
    tester.view.physicalSize = const Size(420, 910);
    tester.view.devicePixelRatio = 1;
    final repo = RepoJornada();
    final calculadora = CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    final menuRepo = CardapioQA();
    final cardapio = CardapioController(repository: menuRepo);
    menuRepo.aoSalvar = (item) {
      cardapio.itensPorCardapio[item.idCardapio] = cardapio
          .itensDoCardapio(item.idCardapio)
          .map((i) => i.idItem == item.idItem ? item : i)
          .toList();
    };
    final theme = EventThemeController();
    Get.put(theme);
    final captura = GlobalKey();
    addTearDown(() {
      calculadora.onClose();
      cardapio.onClose();
      Get.reset();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(GetMaterialApp(
        theme: ThemeData(fontFamily: GoogleFonts.poppins().fontFamily),
        builder: (_, child) => RepaintBoundary(key: captura, child: child!),
        home: CalculadoraFestaScreen(
            idEvento: 'qa',
            tipoEvento: 'Aniversário',
            adultosIniciais: 100,
            calculadoraController: calculadora,
            eventoController: EventoQA(),
            themeController: theme,
            cardapioController: cardapio,
            fornecedorMigracaoAdminController: MigracaoQA())));
    await tester.pumpAndSettle();
    Future<void> capturar(String nome) async {
      if (Platform.environment['CALCULADORA_QA_CAPTURE'] != '1') return;
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            captura.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final imagem = await boundary.toImage(pixelRatio: 1);
        final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
        final destino = File('.dart_tool/qa-calculadora/$nome.png');
        destino.parent.createSync(recursive: true);
        destino.writeAsBytesSync(bytes!.buffer.asUint8List());
        imagem.dispose();
      });
    }

    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      if (i == 0) {
        tester.view.physicalSize = const Size(360, 800);
        await tester.pumpAndSettle();
        final economico = find.text('Econômico');
        final padrao = find.text('Padrão');
        final premium = find.text('Premium');
        expect(tester.getCenter(economico).dy, tester.getCenter(padrao).dy);
        expect(tester.getCenter(padrao).dy, tester.getCenter(premium).dy);
        expect(economico.hitTestable(), findsOneWidget);
        expect(premium.hitTestable(), findsOneWidget);
        await tester.tap(premium);
        await tester.pumpAndSettle();
        expect(calculadora.perfilSelecionado.value.nome, 'Premium');
        await tester.tap(padrao);
        await tester.pumpAndSettle();
        await capturar('perfis-mobile');
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        await tester.pumpAndSettle();
        await tester.ensureVisible(premium);
        await tester.pumpAndSettle();
        expect(premium.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await tester.pumpAndSettle();
        tester.view.physicalSize = const Size(420, 910);
        await tester.pumpAndSettle();
      }
    }
    expect(calculadora.itensCalculados.length, 4);
    await capturar('proposta-refeicao-mobile');
    final proposta = find.text('Conferir e usar proposta');
    await tester.ensureVisible(proposta);
    await tester.tap(proposta);
    await tester.pumpAndSettle();
    await capturar('proposta-dialog-mobile');
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('4 de 4 itens com consumo configurado.'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('4 de 4 itens com consumo configurado.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('5,50 kg'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('5,50 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturar('jornada-mobile');
    final detalhe = find.byTooltip('Ver cálculo e ajustar Arroz 🍚');
    await tester.ensureVisible(detalhe);
    await tester.pumpAndSettle();
    await tester.tap(detalhe);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sem quantidade final para comparar.'),
        findsOneWidget);
    await capturar('detalhe-mobile');
    await tester.tap(find.text('Como chegamos a este cálculo'));
    await tester.pumpAndSettle();
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).data,
        contains('Participação 100% (sem divisão automática)'));
    await tester.tap(find.text('Ajustar porção ou preço'));
    await tester.pumpAndSettle();
    expect(find.text('Regra de consumo'), findsOneWidget);
    expect(find.text('Composição e compra'), findsOneWidget);
    await capturar('regra-mobile');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    // Disponibilidade real é registrada sem transformar o planejado em compra.
    final arrozResultado =
        calculadora.itensCalculados.firstWhere((i) => i.nome == 'Arroz 🍚');
    final arrozRegra = calculadora.regraDoResultado(arrozResultado)!;
    calculadora.adicionarItemManual(arrozRegra.copyWith(premissas: {
      ...arrozRegra.premissas,
      'estado': 'cru',
      'estado_compra': 'cru',
      'papel_na_refeicao': 'acompanhamento'
    }));
    await tester.pumpAndSettle();
    final listaCompras = find.text('Ver lista de compras');
    await tester.ensureVisible(listaCompras);
    await tester.pumpAndSettle();
    await tester.tap(listaCompras);
    await tester.pumpAndSettle();
    expect(find.text('Sua lista de compras'), findsOneWidget);
    expect(
        find.textContaining('4 itens precisam de conferência'), findsOneWidget);
    await capturar('lista-compras-mobile');
    final linhaArroz = find.byKey(const ValueKey('lista_compra_Arroz 🍚'));
    final resolver = find.descendant(
        of: linhaArroz, matching: find.text('Resolver pendência'));
    await tester.ensureVisible(resolver);
    await tester.pumpAndSettle();
    await tester.tap(resolver);
    await tester.pumpAndSettle();
    expect(find.text('O que já tenho'), findsOneWidget);
    final disponibilidadeCampos = find.byType(TextFormField);
    await tester.ensureVisible(disponibilidadeCampos.first);
    await tester.enterText(disponibilidadeCampos.first, '2');
    await tester.ensureVisible(disponibilidadeCampos.last);
    expect(tester.widget<TextFormField>(disponibilidadeCampos.last).enabled,
        false);
    await capturar('disponibilidade-mobile');
    await tester.tap(find.text('Salvar disponibilidade'));
    await tester.pumpAndSettle();
    expect(menuRepo.ultimoSalvo!.disponibilidade!.comprado, 2);
    expect(menuRepo.ultimoSalvo!.disponibilidade!.estoque, 0);
    expect(menuRepo.ultimoSalvo!.quantidadeFinal, 0);
    expect(menuRepo.ultimoSalvo!.confirmado, isFalse);
    final opcoesRefeicao = find.text('Público e estoque');
    await tester.scrollUntilVisible(opcoesRefeicao, -300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(opcoesRefeicao);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Público e alimentação desta refeição'));
    await tester.pumpAndSettle();
    await capturar('publico-refeicao-premium-mobile');
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Usar público da festa'));
    await tester.tap(find.text('Usar público da festa'));
    await tester.pumpAndSettle();
    final adultosRefeicao = find.byKey(const ValueKey('publico-adultos'));
    await tester.ensureVisible(adultosRefeicao);
    await tester.tap(adultosRefeicao);
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pumpAndSettle();
    expect(find.text('Salvar ajustes').hitTestable(), findsOneWidget);
    await capturar('publico-refeicao-teclado-320px');
    tester.view.resetViewInsets();
    tester.view.physicalSize = const Size(420, 910);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    final estoqueCentral = find.text('Estoque e reservas da festa');
    await tester.scrollUntilVisible(estoqueCentral, -300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(estoqueCentral);
    await tester.pumpAndSettle();
    await capturar('estoque-vazio-premium-mobile');
    await tester.tap(find.text('Cadastrar lote'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await capturar('estoque-novo-lote-premium-mobile');
    await tester.enterText(find.byType(TextFormField).first, 'Arroz reservado');
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await capturar('estoque-lote-teclado-mobile');
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reservar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, '1');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();
    expect(calculadora.operacaoEvento['lotes'], isNotEmpty);
    await capturar('estoque-central-mobile');
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(listaCompras, -250,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(listaCompras);
    await tester.pumpAndSettle();
    expect(find.text('Falta comprar: 2,50 kg'), findsOneWidget);
    await capturar('lista-compras-atualizada-mobile');
    await tester.tap(find.text('Voltar').last);
    await tester.pumpAndSettle();
    final outras = find.text('Outras opções');
    await tester.scrollUntilVisible(outras, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(outras);
    await tester.tap(outras);
    await tester.pumpAndSettle();
    Future<void> abrirOpcao(String titulo) async {
      final opcao = find.text(titulo);
      await tester.ensureVisible(opcao);
      await tester.pumpAndSettle();
      await tester.tap(opcao);
      await tester.pumpAndSettle();
    }

    await abrirOpcao('Ver compras da festa inteira');
    expect(find.text('Compras da festa inteira'), findsOneWidget);
    expect(find.text('Falta comprar: 2,50 kg'), findsOneWidget);
    await tester.tap(find.text('Voltar').last);
    await tester.pumpAndSettle();
    final arrozParaReceita =
        calculadora.itensCalculados.firstWhere((i) => i.nome == 'Arroz 🍚');
    final receitaArroz = calculadora.regraDoResultado(arrozParaReceita)!;
    repo.receitas = [
      receitaArroz.copyWith(valorUnitarioMedio: 0, premissas: {
        ...receitaArroz.premissas,
        'receita': 'Arroz da família',
        'estado': 'cru',
        'papel_na_refeicao': 'acompanhamento'
      })
    ];
    await abrirOpcao('Reutilizar uma receita salva');
    expect(find.text('Suas receitas salvas'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Arroz 🍚').last);
    await tester.pumpAndSettle();
    expect(find.text('Regra de consumo'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, 'Arroz da família'), findsOneWidget);
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    final regraReutilizada = calculadora.regraDoResultado(
        calculadora.itensCalculados.firstWhere((i) => i.nome == 'Arroz 🍚'))!;
    expect(regraReutilizada.premissas['receita'], 'Arroz da família');
    expect(regraReutilizada.valorUnitarioMedio, 0);
    await abrirOpcao('Conferir a refeição completa');
    expect(find.text('Sua refeição por inteiro'), findsOneWidget);
    await capturar('refeicao-completa-mobile');
    await tester.tap(find.text('Voltar').last);
    await tester.pumpAndSettle();
    calculadora.atualizarOrcamentoDisponivel(8500);
    await tester.pumpAndSettle();
    await abrirOpcao('Planejar dentro do limite');
    expect(find.textContaining('Não é possível afirmar que cabe no limite'),
        findsOneWidget);
    await capturar('limite-compras-mobile');
    await tester.tap(find.text('Usar esta reserva'));
    await tester.pumpAndSettle();
    expect(calculadora.margemPersonalizada.value, .05);
    calculadora.atualizarMargemPersonalizada(null);
    await tester.pumpAndSettle();
    await abrirOpcao('Revisão depois da festa');
    expect(find.text('Depois da festa'), findsOneWidget);
    expect(find.text('Nenhum registro encontrado neste contexto'),
        findsNWidgets(4));
    await capturar('pos-festa-mobile');
    await tester.tap(find.text('Concluir revisão'));
    await tester.pumpAndSettle();
    await abrirOpcao('Avaliar esta experiência');
    expect(find.textContaining('Listas abertas:'), findsOneWidget);
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    expect(find.text('Sua avaliação: 4 de 5'), findsOneWidget);
    await capturar('avaliacao-sessao-mobile');
    String? avaliacaoCopiada;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        avaliacaoCopiada = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    await tester.tap(find.text('Copiar avaliação'));
    await tester.pumpAndSettle();
    expect(avaliacaoCopiada, contains('Facilidade informada: 4 de 5'));
    expect(avaliacaoCopiada, isNot(contains('Arroz')));
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);

    // A alternativa só entra no cardápio após preencher sua própria porção/preço e confirmar.
    final bebida =
        calculadora.itensCalculados.firstWhere((i) => i.nome == 'Refrigerante');
    final regraBebida = calculadora.regraDoResultado(bebida)!;
    calculadora.adicionarItemManual(regraBebida.copyWith(premissas: {
      ...regraBebida.premissas,
      'papel_na_refeicao': 'bebida',
      'estado': 'pronto'
    }));
    await tester.pumpAndSettle();
    await abrirOpcao('Simular troca de ingrediente');
    await tester.tap(find.text('Refrigerante').last);
    await tester.pumpAndSettle();
    expect(find.text('Regra de consumo'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do item'), 'Suco');
    final porcaoAlternativa =
        find.widgetWithText(TextFormField, 'Quantidade por convidado');
    await tester.ensureVisible(porcaoAlternativa);
    await tester.pumpAndSettle();
    await tester.enterText(porcaoAlternativa, '0,4');
    await tester.ensureVisible(find.text('Preciso confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preciso confirmar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pronto para servir').last);
    await tester.pumpAndSettle();
    final precoAlternativa = find.widgetWithText(TextFormField, 'Preço por L');
    await tester.ensureVisible(precoAlternativa);
    await tester.pumpAndSettle();
    await tester.enterText(precoAlternativa, '500');
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar substituição'), findsOneWidget);
    expect(find.textContaining('Suco'), findsWidgets);
    expect(find.textContaining('Economia total indisponível'), findsOneWidget);
    await capturar('substituicao-mobile');
    await tester.tap(find.text('Aplicar substituição'));
    await tester.pumpAndSettle();
    expect(menuRepo.ultimoSalvo!.nome, 'Suco');
    expect(calculadora.itensCardapio.any((i) => i.nome == 'Suco'), isTrue);
    expect(
        calculadora.itensCalculados
            .any((i) => i.nome == 'Suco' && i.valorUnitarioMedio == 5),
        isTrue);
    final comparar = find.text('Comparar porções e reserva');
    await tester.scrollUntilVisible(comparar, 400,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(comparar);
    await tester.pumpAndSettle();
    await capturar('planejamento-mobile');
    await tester.tap(comparar);
    await tester.pumpAndSettle();
    expect(find.textContaining('Economia indisponível:'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(Dialog), matching: find.textContaining(r'R$ 0,00')),
        findsNothing);
    await capturar('comparacao-mobile');
    tester.view.physicalSize = const Size(360, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    await tester.pumpAndSettle();
    expect(find.text('Manter atual').hitTestable(), findsOneWidget);
    expect(find.text('Usar cenário econômico').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.physicalSize = const Size(420, 910);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter atual'));
    await tester.pumpAndSettle();
    repo.gastos = [
      {
        'id': 'servico-qa',
        'descricao': 'Aluguel da Chácara',
        'valor': 6500,
        'identidade': 'aluguel_da_chacara||todos',
        'cobertura_identificavel': false,
        'cobre_itens': <String>[]
      }
    ];
    calculadora.compromissosOrcamento.assignAll(repo.gastos);
    await tester.pumpAndSettle();
    final conferirCustos = find.text('Conferir custos já orçados');
    await tester.scrollUntilVisible(conferirCustos, -300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(conferirCustos);
    await tester.tap(conferirCustos);
    await tester.pumpAndSettle();
    expect(find.text('Conferir custo já orçado'), findsOneWidget);
    final semItens = find.text(
        'Este valor não corresponde a itens do cardápio (ex.: espaço ou decoração)');
    await tester.ensureVisible(semItens);
    await tester.pumpAndSettle();
    await tester.tap(semItens);
    await tester.pumpAndSettle();
    await capturar('conciliacao-financeira-mobile');
    await tester.tap(find.text('Salvar conferência'));
    await tester.pumpAndSettle();
    expect(repo.ultimaConferencia!['modo'], 'sem_itens');
    await tester.runAsync(calculadora.carregarContextoOrcamento);
    await tester.pumpAndSettle();
    expect(calculadora.compromissosOrcamento.single['conferencia_financeira'],
        'sem_itens');
    final cobertura = find.text('Conferir cobertura dos serviços');
    await tester.scrollUntilVisible(cobertura, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(cobertura);
    await tester.pumpAndSettle();
    await tester.tap(cobertura);
    await tester.pumpAndSettle();
    expect(find.text('Cobertura do serviço'), findsOneWidget);
    final checkbox = find.byType(CheckboxListTile).first;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
    expect(find.text('1 selecionado(s)'), findsOneWidget);
    await capturar('cobertura-mobile');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(calculadora.compromissosOrcamento.single['cobre_itens'], isEmpty);
    await abrirOpcao('Conferir cobertura dos serviços');
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar cobertura'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => calculadora.carregarContextoOrcamento());
    await tester.pumpAndSettle();
    expect(repo.ultimaCobertura, hasLength(1));
    expect(repo.ultimaCobertura!.single, startsWith('v2:['));
    expect(repo.ultimaCobertura!.single, contains('almoco'));

    calculadora.compromissosOrcamento.clear();
    repo.gastos.clear();
    await tester.pumpAndSettle();
    final calibrar = find.text('Calibrar porções do cardápio');
    await tester.ensureVisible(calibrar);
    await tester.pumpAndSettle();
    await tester.tap(calibrar);
    await tester.pumpAndSettle();
    expect(find.text('Calibrar porções para esta refeição'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturar('seletor-mobile');
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    final salvo = calculadora.calculoAtual.value!;
    repo.itens = calculadora.itensCalculados.toList();
    await tester.runAsync(() => calculadora.carregarSimulacaoNoEditor(salvo));
    await tester.pumpAndSettle();
    cardapio.itensPorCardapio['almoco'] = [
      const CardapioItem(
          idItem: 'novo',
          idEvento: 'qa',
          idCardapio: 'almoco',
          nome: 'Item novo')
    ];
    await tester.pumpAndSettle();
    expect(calculadora.itensCardapio.length, 4);
    expect(
        calculadora.itensCardapio
            .firstWhere((i) => i.nome == 'Arroz 🍚')
            .disponibilidade!
            .comprado,
        2);
    expect(calculadora.usandoContextoHistorico.value, isTrue);
    final atualizar = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh;
    await tester.runAsync(atualizar);
    await tester.pumpAndSettle();
    expect(calculadora.itensCardapio.single.nome, 'Item novo');
    expect(calculadora.usandoContextoHistorico.value, isFalse);
    expect(tester.takeException(), isNull);
  });
}
