import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/data/models/cardapio/cardapio_model.dart';
import 'package:app_faca_festa/data/models/evento/calculadora_festa_model.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/tipo_evento.dart';
import 'package:app_faca_festa/domain/entities/rascunho_calculadora.dart';
import 'package:app_faca_festa/domain/services/analise_refeicao_service.dart';
import 'package:app_faca_festa/domain/services/medicao_uso_calculadora.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/eventos/controllers/evento_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calculadora_composicao_test.dart' show AiQA, AuthQA;
import 'calculadora_jornada_test.dart'
    show RepoJornada, BaseJornada, CardapioQA, MigracaoQA;
import 'calculadora_integridade_ponta_a_ponta_test.dart' show regra;

class RepoRascunho extends RepoJornada {
  final salvos = <String, CalculadoraFesta>{};
  List<CalculadoraFestaItem> itensSalvos = [];
  @override
  Future<void> salvarSimulacao(
      {required CalculadoraFesta calculo,
      required List<CalculadoraFestaItem> itens}) async {
    salvos[calculo.idCalculo] = calculo;
    itensSalvos = itens;
  }
}

class EventoAtivo extends Fake implements EventoController {
  @override
  final eventoAtual = Rx<Evento?>(null);
  @override
  Evento get eventoAtualEntidade => Evento(
      idEvento: 'anterior',
      idUsuario: 'owner',
      idTipoEvento: 'casamento',
      nomeEvento: 'Anterior',
      localEvento: '',
      data: DateTime(2026, 12),
      totalAdultos: 99,
      custoEstimado: 99999);
  @override
  TipoEvento? get tipoEventoAtualEntidade => null;
}

class ConvidadosVivos extends Fake implements ConvidadoController {
  @override
  final idEventoAtual = 'anterior'.obs;
  @override
  final carregando = false.obs;
  @override
  final erro = ''.obs;
  @override
  final convidados = <Convidado>[].obs;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthQA());
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() => Get.reset());
  CalculadoraFestaController criar(RepoRascunho repo) {
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    addTearDown(c.onClose);
    return c;
  }

  Future<void> preparar(CalculadoraFestaController c) => c.prepararCalculadora(
      idEvento: '',
      tipoEvento: 'Aniversário',
      permitirEstimativaSemEvento: true,
      adultosManuais: 12,
      criancasManuais: 3);
  Convidado pessoa(String id, StatusConvidado status,
          {String evento = 'festa'}) =>
      Convidado(
          idConvidado: id,
          idEvento: evento,
          nome: id,
          contato: '',
          status: status,
          dataCadastro: DateTime(2026),
          dataAtualizacao: DateTime(2026));

  test(
      'rascunho preserva regras, seleções e premissas ao reabrir e vincula uma vez por ID',
      () async {
    final repo = RepoRascunho(), c = criar(RepoRascunho());
    c.idCardapioAtual = 'anterior';
    c.tituloCardapio = 'Cardápio anterior';
    await preparar(c);
    expect(c.idCardapioAtual, isEmpty);
    expect(c.tituloCardapio, isEmpty);
    c.atualizarOrcamentoDisponivel(2500);
    c.atualizarVerbaAlimentacao(900);
    c.atualizarDuracao(6);
    c.adicionarItemManual(regra.copyWith(
        id: 'receita',
        premissas: {...regra.premissas, 'receita': 'Da família'}));
    c.alternarItemEstimativa(c.itensEstimativa.first.id, false);
    final r = c.capturarRascunho('cadastro');
    final restaurado = RascunhoCalculadora.fromMap(r.toMap());
    expect(restaurado.criadoEm.microsecondsSinceEpoch,
        r.criadoEm.microsecondsSinceEpoch);
    expect(restaurado.regras('regras_manuais').single.premissas['receita'],
        'Da família');
    final copia = r.contexto;
    (copia['regras_manuais'] as List).clear();
    expect(r.regras('regras_manuais'), isNotEmpty);
    await preparar(c);
    expect(c.verbaAlimentacao.value, isNull);
    c.restaurarRascunho(r);
    expect(c.verbaAlimentacao.value, 900);
    expect(c.orcamentoDisponivel.value, 2500);
    expect(c.duracaoHoras.value, 6);
    expect(c.regrasManuais.single.premissas['receita'], 'Da família');
    expect(c.itensEstimativa.first.selecionado, false);
    final gravador = criar(repo);
    final evento = Evento(
        idEvento: 'novo',
        idUsuario: 'owner',
        idTipoEvento: 'aniversario',
        nomeEvento: 'Novo',
        localEvento: '',
        data: DateTime(2026),
        totalAdultos: 20,
        totalCriancas: 1,
        totalBebes: 0,
        custoEstimado: 3000);
    await gravador.vincularRascunho(r, evento);
    await gravador.vincularRascunho(r, evento);
    expect(repo.salvos.length, 1);
    expect(repo.salvos.values.single.idEvento, 'novo');
    expect(repo.salvos.values.single.contextoPlanejamento['verba_alimentacao'],
        900);
    expect(repo.salvos.values.single.orcamentoDisponivel, 3000);
    expect(repo.salvos.values.single.totalAdultos, 20);
    expect(
        repo.salvos.values.single.contextoPlanejamento['publico_evento']
            ['criancas'],
        1);
    expect(repo.salvos.values.single.contextoPlanejamento['id_rascunho_origem'],
        'cadastro');
    expect(repo.itensSalvos.every((i) => i.idEvento == 'novo'), isTrue);
    expect(gravador.idEventoAtual.value, isEmpty);
  });

  testWidgets(
      'novo cadastro não herda evento, público ou limite do evento ativo e devolve o rascunho',
      (tester) async {
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
    final c = criar(RepoRascunho());
    final menus = CardapioController(repository: CardapioQA());
    final theme = EventThemeController();
    addTearDown(menus.onClose);
    RascunhoCalculadora? devolvido;
    await tester.pumpWidget(GetMaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => CalculadoraFestaScreen(
                                idEvento: '',
                                tipoEvento: 'Aniversário',
                                orcamentoInicial: 1200,
                                permitirEstimativaSemEvento: true,
                                idRascunho: 'novo',
                                onRascunho: (r) => devolvido = r,
                                calculadoraController: c,
                                eventoController: EventoAtivo(),
                                themeController: theme,
                                cardapioController: menus,
                                fornecedorMigracaoAdminController:
                                    MigracaoQA()))),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(c.idEventoAtual.value, isEmpty);
    expect(c.totalConvidados, 0);
    expect(c.orcamentoDisponivel.value, 1200);
    expect(c.itensCardapio, isEmpty);
    c.atualizarTotaisManuais(adultos: 8, criancas: 2, bebes: 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(devolvido!.adultos, 8);
    expect(devolvido!.criancas, 2);
    expect(devolvido!.limite, 1200);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lista atualiza público na calculadora aberta e respeita manual',
      (tester) async {
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
    final c = criar(RepoRascunho());
    final convidados = ConvidadosVivos();
    final menus = CardapioController(repository: CardapioQA());
    addTearDown(menus.onClose);
    await tester.pumpWidget(GetMaterialApp(
        home: CalculadoraFestaScreen(
            idEvento: 'anterior',
            tipoEvento: 'Aniversário',
            calculadoraController: c,
            eventoController: EventoAtivo(),
            themeController: EventThemeController(),
            cardapioController: menus,
            convidadoController: convidados,
            fornecedorMigracaoAdminController: MigracaoQA())));
    await tester.pumpAndSettle();
    convidados.convidados.assignAll(
        [pessoa('sim', StatusConvidado.confirmado, evento: 'anterior')]);
    await tester.pumpAndSettle();
    expect(c.totalAdultos.value, 99); // A lista parcial preserva a previsão.
    c.alterarBaseCalculo(BaseCalculoFesta.naoRecusados); // Escolha explícita.
    convidados.convidados.refresh();
    await tester.pumpAndSettle();
    expect(c.totalAdultos.value, 1);
    Finder adultos() => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Adultos');
    await tester.scrollUntilVisible(adultos(), 120,
        scrollable: find.byType(Scrollable).last);
    expect(tester.widget<TextField>(adultos()).controller!.text, '1');
    c.atualizarTotaisManuais(adultos: 7, criancas: 0, bebes: 0);
    convidados.convidados.assignAll(
        [pessoa('nao', StatusConvidado.recusado, evento: 'anterior')]);
    await tester.pumpAndSettle();
    expect(c.totalAdultos.value, 7);
    expect(tester.widget<TextField>(adultos()).controller!.text, '7');
    expect(tester.takeException(), isNull);
  });

  test(
      'fontes de público distinguem previstos, todos, não recusados e confirmados sem afetar manual',
      () {
    final c = criar(RepoRascunho());
    c.idEventoAtual.value = 'festa';
    c.totalAdultosEvento.value = 35;
    final lista = [
      pessoa('sim', StatusConvidado.confirmado),
      pessoa('talvez', StatusConvidado.pendente),
      pessoa('nao', StatusConvidado.recusado),
      pessoa('outro', StatusConvidado.confirmado, evento: 'outro')
    ];
    c.alterarBaseCalculo(BaseCalculoFesta.naoRecusados);
    c.sincronizarConvidados(lista);
    expect(c.totalAdultos.value, 2);
    c.alterarBaseCalculo(BaseCalculoFesta.apenasConfirmados);
    expect(c.totalAdultos.value, 1);
    c.alterarBaseCalculo(BaseCalculoFesta.todosConvidados);
    expect(c.totalAdultos.value, 3);
    c.alterarBaseCalculo(BaseCalculoFesta.previstos);
    expect(c.totalAdultos.value, 35);
    c.atualizarTotaisManuais(adultos: 7, criancas: 0, bebes: 0);
    c.sincronizarConvidados([]);
    expect(c.totalAdultos.value, 7);
    c.alterarBaseCalculo(BaseCalculoFesta.naoRecusados);
    c.sincronizarConvidados([pessoa('nao', StatusConvidado.recusado)]);
    expect(c.totalAdultos.value, 0);
    expect(BaseCalculoFestaModelExtension.fromString('naoRecusados'),
        BaseCalculoFesta.naoRecusados);
  });

  test(
      'escopo de cardápio é preservado e categoria não recebe diagnóstico de refeição',
      () {
    final antigo = CardapioModel.fromMap(
        {'id_cardapio': 'bebidas', 'id_evento': 'festa', 'titulo': 'Bebidas'});
    expect(antigo.escopo, EscopoCardapio.naoDefinido);
    final novo = antigo.copyWith(escopo: EscopoCardapio.categoria);
    expect(
        CardapioModel.fromMap(novo.toMap()).escopo, EscopoCardapio.categoria);
    const analise = AnaliseRefeicaoService();
    expect(
        analise.analisar([regra],
            refeicao: 'Almoço', avaliarComposicao: false).pendencias,
        isEmpty);
    expect(
        analise.analisar([regra], refeicao: 'Almoço').pendencias, isNotEmpty);
    final c = criar(RepoRascunho());
    c.atualizarCardapio([],
        titulo: 'Almoço', disponivel: true, escopo: EscopoCardapio.categoria);
    expect(c.analiseRefeicao.pendencias, isEmpty);
    expect(c.snapshotPlanejamento['escopo_cardapio'], 'categoria');
  });

  test(
      'medição não conta cada tecla como campo nem conta atualização automática como edição',
      () async {
    final c = criar(RepoRascunho());
    await preparar(c);
    c.atualizarTotaisManuais(
        adultos: 1, criancas: 0, bebes: 0, intervencaoHumana: true);
    c.atualizarTotaisManuais(
        adultos: 12, criancas: 0, bebes: 0, intervencaoHumana: true);
    expect(c.medicaoUso.camposDistintosEditados, 2);
    final antes = c.medicaoUso.resumo;
    c.atualizarTotaisManuais(adultos: 20, criancas: 9, bebes: 3);
    expect(c.medicaoUso.resumo, antes);
    final m = MedicaoUsoCalculadora()
      ..registrarDecisao('salvar')
      ..registrarDecisao('salvar');
    expect(m.decisoesRegistradas, 2);
    expect(m.relatorio(), contains('nem comprova a meta'));
  });
}
