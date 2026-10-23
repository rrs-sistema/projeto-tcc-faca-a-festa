import 'dart:async';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/domain/entities/convidados_equivalentes.dart';
import 'package:app_faca_festa/domain/services/publico_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/repositories/convidado_repository.dart';
import 'package:app_faca_festa/domain/repositories/presente_reservation_repository.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/convidado_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_festa_screen.dart';
import 'package:app_faca_festa/presentation/modules/convidado/controllers/cardapio_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'calculadora_jornada_test.dart' show EventoQA, CardapioQA, MigracaoQA;
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;
import 'calculadora_composicao_test.dart' show AiQA;

class RepoPublico extends RepoJornada {
  bool falhar = false;
  int gravacoes = 0;
  final alteracoes = StreamController<Map<String, dynamic>>.broadcast();
  @override
  Stream<Map<String, dynamic>> observarOperacaoEvento(String id) async* {
    yield operacao;
    yield* alteracoes.stream;
  }

  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) async {
    if (falhar) throw StateError('Sem conexão');
    gravacoes++;
    operacao = const OperacaoCalculadoraService().aplicar(operacao, acao);
    return operacao;
  }
}

Convidado pessoa(String id,
        {String evento = 'festa',
        StatusConvidado status = StatusConvidado.pendente,
        TipoConvidado tipo = TipoConvidado.adulto}) =>
    Convidado(
        idConvidado: id,
        idEvento: evento,
        nome: id,
        contato: '',
        status: status,
        tipoConvidado: tipo,
        dataCadastro: DateTime(2026),
        dataAtualizacao: DateTime(2026));

class ListaRepo extends Fake implements ConvidadoRepository {
  final streams = <String, StreamController<List<Convidado>>>{};
  Completer<void>? cancelamento;
  @override
  Stream<List<Convidado>> observarPorEvento(String id) =>
      (streams[id] = StreamController<List<Convidado>>(
              onCancel: () => id == 'A' ? cancelamento?.future : null))
          .stream;
}

class ReservaRepo extends Fake implements PresenteReservationRepository {}

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() => Get.reset());

  test('manual zero explícito não herda a previsão de 40', () async {
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'festa',
        tipoEvento: 'Formatura',
        base: BaseCalculoFesta.manual,
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    expect(c.baseCalculo.value, BaseCalculoFesta.manual);
    expect(c.totalConvidados, 0);
    c.sincronizarConvidados([pessoa('um')], eventoFonte: 'festa');
    expect(c.totalConvidados, 0);
  });

  test(
      '40 previstos não caem para um no primeiro registro sem escolha confirmada',
      () async {
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'festa',
        tipoEvento: 'Formatura',
        base: BaseCalculoFesta.naoRecusados,
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    expect(c.totalConvidados, 40);
    c.sincronizarConvidados([
      Convidado(
          idConvidado: 'um',
          idEvento: 'festa',
          nome: 'Pessoa',
          contato: '',
          dataCadastro: DateTime(2026),
          dataAtualizacao: DateTime(2026))
    ]);
    expect(c.totalConvidados, 40);
  });
  test('bases exatas, zero, ausência e legado sem adultos presumidos', () {
    const service = PublicoPlanejamentoService();
    final lista = [
      pessoa('adulto'),
      pessoa('crianca',
          status: StatusConvidado.confirmado, tipo: TipoConvidado.crianca),
      pessoa('bebe',
          status: StatusConvidado.recusado, tipo: TipoConvidado.bebe),
      pessoa('alheio', evento: 'outro')
    ];
    const previsao = PrevisaoPublico(
        40, ConvidadosEquivalentes(adultos: 40, criancas: 0, bebes: 0));
    PublicoPlanejado resolver(BaseCalculoFesta? base,
            {bool disponivel = true}) =>
        service.resolver(
            evento: 'festa',
            previsao: previsao,
            convidados: lista,
            base: base,
            listaDisponivel: disponivel);
    expect(resolver(null).total, 40);
    expect(resolver(BaseCalculoFesta.todosConvidados).total, 3);
    expect(resolver(BaseCalculoFesta.naoRecusados).total, 2);
    expect(resolver(BaseCalculoFesta.apenasConfirmados).idades!.criancas, 1);
    expect(resolver(BaseCalculoFesta.todosConvidados, disponivel: false).total,
        isNull);
    final zero = service.resolver(
        evento: 'festa',
        previsao: previsao,
        convidados: [pessoa('pendente')],
        base: BaseCalculoFesta.apenasConfirmados);
    expect(zero.total, 0);
    expect(zero.idades, isNotNull);
    Evento evento({int? total, int? adultos}) => Evento(
        idEvento: 'festa',
        idUsuario: 'owner',
        idTipoEvento: 'tipo',
        nomeEvento: 'Teste',
        localEvento: '',
        data: DateTime(2026),
        totalConvidados: total,
        totalAdultos: adultos);
    expect(PrevisaoPublico.doEvento(evento()).total, isNull);
    expect(PrevisaoPublico.doEvento(evento(total: 0, adultos: 0)).total, 0);
    final legado = PrevisaoPublico.doEvento(evento(total: 40));
    expect(legado.total, 40);
    expect(legado.idades, isNull);
  });
  test(
      'legado conserva total, exige distribuição e não produz quantidades para adultos inferidos',
      () async {
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: RepoJornada(),
        itensBaseRepository: BaseJornada());
    addTearDown(c.onClose);
    await c.prepararCalculadora(
        idEvento: 'festa', tipoEvento: 'Formatura', totalConvidadosEvento: 40);
    expect(c.totalConvidados, 40);
    expect(c.totalAdultosEvento.value, 0);
    expect(c.publicoPlanejado.semDistribuicao, isTrue);
    expect(c.itensCalculados, isEmpty);
  });
  test(
      'declaração, escolha persistida, falha, reabertura e público próprio da refeição',
      () async {
    final repo = RepoPublico();
    addTearDown(repo.alteracoes.close);
    CalculadoraFestaController criar() {
      final c = CalculadoraFestaController(
          aiService: AiQA(),
          repository: repo,
          itensBaseRepository: BaseJornada());
      addTearDown(c.onClose);
      return c;
    }

    final c = criar();
    await c.prepararCalculadora(
        idEvento: 'festa',
        tipoEvento: 'Formatura',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    await c.iniciarOperacaoEvento();
    await Future<void>.delayed(Duration.zero);
    expect(c.completudeLista.value, CompletudeLista.desconhecida);
    c.sincronizarConvidados([pessoa('um')]);
    expect(c.totalConvidados, 40);
    await c.declararCompletude(CompletudeLista.emPreenchimento,
        assinatura: c.contextoEvento.assinatura);
    expect(
        c.publicoPlanejado.resumo, contains('em preenchimento: 1 cadastrado'));
    repo.falhar = true;
    await expectLater(
        c.confirmarBasePublico(BaseCalculoFesta.apenasConfirmados,
            assinatura: c.contextoEvento.assinatura),
        throwsStateError);
    expect(c.baseCalculo.value, BaseCalculoFesta.previstos);
    expect(c.totalConvidados, 40);
    repo.falhar = false;
    await c.confirmarBasePublico(BaseCalculoFesta.apenasConfirmados,
        assinatura: c.contextoEvento.assinatura);
    expect(c.totalConvidados, 0);
    final novo = criar();
    await novo.prepararCalculadora(
        idEvento: 'festa',
        tipoEvento: 'Formatura',
        adultosEvento: 40,
        totalConvidadosEvento: 40);
    await novo.iniciarOperacaoEvento();
    await Future<void>.delayed(Duration.zero);
    expect(novo.baseCalculo.value, BaseCalculoFesta.apenasConfirmados);
    expect(novo.totalConvidados, 0);
    novo.operacaoEvento['refeicoes'] = {
      'propria': {
        'publico': {'adultos': 8, 'criancas': 2, 'bebes': 0}
      }
    };
    novo.atualizarTotaisManuais(adultos: 15, criancas: 0, bebes: 0);
    novo.sincronizarConvidados(
        [pessoa('confirmado', status: StatusConvidado.confirmado)]);
    expect(novo.totalAdultos.value, 15);
    expect(novo.publicoDaRefeicao('propria').totalInformado, 10);
    expect(novo.basePublicoConfirmada.value, isFalse);
    await novo.confirmarBasePublico(BaseCalculoFesta.manual,
        assinatura: novo.contextoEvento.assinatura);
    expect(novo.basePublicoConfirmada.value, isTrue);
    await novo.declararCompletude(CompletudeLista.concluida,
        assinatura: novo.contextoEvento.assinatura);
    expect(novo.totalConvidados, 15);
    expect(novo.completudeLista.value, CompletudeLista.concluida);
  });
  test(
      'convidados rejeitam callbacks de A, estados não inferem completude e troca de usuário isola política',
      () async {
    final repo = ListaRepo()..cancelamento = Completer<void>();
    final planejamento = RepoPublico();
    var usuario = 'owner';
    final c = ConvidadoController(
        repository: repo,
        presenteReservationRepository: ReservaRepo(),
        planejamentoResolver: () => planejamento,
        usuarioContexto: () => usuario);
    await c.escutarConvidados('A');
    final troca = c.escutarConvidados('B');
    repo.streams['A']!.add([pessoa('antigo', evento: 'A')]);
    repo.cancelamento!.complete();
    await troca;
    repo.streams['B']!.add([pessoa('atual', evento: 'B')]);
    await Future<void>.delayed(Duration.zero);
    expect(c.convidados.single.idConvidado, 'atual');
    expect(
        c
            .publicoPlanejadoDoEvento(Evento(
                idEvento: 'B',
                idUsuario: 'owner',
                idTipoEvento: 'tipo',
                nomeEvento: 'Teste',
                localEvento: '',
                data: DateTime(2026),
                totalAdultos: 40))
            .completude,
        CompletudeLista.desconhecida);
    usuario = 'outro';
    planejamento.alteracoes.add({
      'configuracao_planejamento': {'lista_completude': 'concluida'}
    });
    await Future<void>.delayed(Duration.zero);
    expect(c.configuracaoPublico['lista_completude'], isNull);
    c.limpar();
    c.onClose();
    for (final stream in repo.streams.values) {
      await stream.close();
    }
    await planejamento.alteracoes.close();
  });
  testWidgets(
      'troca de fonte exige confirmação; cancelar não grava, confirmar zero grava',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final repo = RepoPublico();
    final c = CalculadoraFestaController(
        aiService: AiQA(),
        repository: repo,
        itensBaseRepository: BaseJornada());
    final menus = CardapioController(repository: CardapioQA());
    addTearDown(() async {
      c.onClose();
      menus.onClose();
      await repo.alteracoes.close();
    });
    await tester.pumpWidget(GetMaterialApp(
        home: CalculadoraFestaScreen(
            idEvento: 'festa',
            tipoEvento: 'Formatura',
            adultosIniciais: 40,
            calculadoraController: c,
            eventoController: EventoQA(),
            themeController: EventThemeController(),
            cardapioController: menus,
            fornecedorMigracaoAdminController: MigracaoQA())));
    await tester.pumpAndSettle();
    final chip = find.text('Confirmados');
    await tester.drag(find.byType(ListView).first, const Offset(0, -550));
    await tester.pumpAndSettle();
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(c.totalConvidados, 40);
    expect(repo.gravacoes, 0);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar fonte'));
    await tester.pumpAndSettle();
    expect(c.totalConvidados, 0);
    expect(repo.operacao['configuracao_planejamento']['base'], 'confirmados');
    expect(tester.takeException(), isNull);
  });
}
