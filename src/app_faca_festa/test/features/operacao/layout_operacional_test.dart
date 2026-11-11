import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/services/functions/mensagem_falha_operacional.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/agenda_fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/agenda/agenda_fornecedor_page.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/planejamento_financeiro_controller.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/planejamento_financeiro_page.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/gestao_reputacao_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/widgets/gestao_reputacao_painel.dart';
import 'package:app_faca_festa/presentation/widgets/operacao/operacao_scaffold.dart';
import '../agenda/agenda_fornecedor_test.dart' as agenda;
import '../planejamento/planejamento_financeiro_test.dart' as financeiro;
import '../avaliacoes/gestao_reputacao_test.dart' as reputacao;

class Gateway implements CallableSessaoGateway {
  bool falha;
  Gateway(this.falha);
  @override
  String? get usuario => 'f';
  @override
  Stream<String?> get sessoes => const Stream.empty();
  @override
  Future<Map<String, dynamic>> chamar(
      String nome, Map<String, dynamic> dados) async {
    if (nome == 'consultarPermissaoReputacaoFn') {
      return {'moderar': false};
    }
    if (falha) {
      throw FirebaseFunctionsException(code: 'internal', message: 'internal');
    }
    if (nome == 'consultarAgendaFornecedorFn') return agenda.fixture();
    if (nome == 'consultarPlanejamentoFornecedorFn') {
      if (dados['inicio'] == 'invalida') {
        throw FirebaseFunctionsException(
            code: 'invalid-argument', message: 'Data inválida');
      }
      return financeiro.fixture();
    }
    return reputacao.pagina();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonte = FontLoader('OperacaoPoppins');
    for (final arquivo in [
      'Poppins-Regular.ttf',
      'Poppins-SemiBold.ttf',
      'Poppins-Bold.ttf'
    ]) {
      fonte.addFont(Future.value(ByteData.sublistView(
          await File('assets/fonts/$arquivo').readAsBytes())));
    }
    await fonte.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('erro técnico vira orientação; validação de negócio continua explícita',
      () {
    expect(
        mensagemFalhaOperacional(
            FirebaseFunctionsException(code: 'internal', message: 'internal'),
            recurso: 'a agenda'),
        isNot(contains('internal')));
    expect(
        mensagemFalhaOperacional(
            FirebaseFunctionsException(
                code: 'invalid-argument', message: 'Período inválido'),
            recurso: 'o relatório'),
        'Período inválido');
    expect(
        mensagemFalhaOperacional(
            FirebaseFunctionsException(
                code: 'permission-denied', message: 'internal'),
            recurso: 'a agenda'),
        contains('permissão'));
  });
  testWidgets(
      'consulta inválida mantém filtros editáveis e limpar recupera o relatório',
      (t) async {
    final c = PlanejamentoFinanceiroController(
        gateway: Gateway(false), store: agenda.Store());
    await t.pumpWidget(
        MaterialApp(home: PlanejamentoFinanceiroPage(controller: c)));
    await t.pumpAndSettle();
    c.filtros['inicio'] = 'invalida';
    await c.carregar();
    await t.pumpAndSettle();
    expect(find.text('Data inválida'), findsOneWidget);
    final filtro = find.text('Filtrar por evento e período');
    await t.ensureVisible(filtro);
    await t.tap(filtro);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('filtro-evento')), findsOneWidget);
    await t.scrollUntilVisible(find.text('Limpar filtros'), 200,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    await t.tap(find.text('Limpar filtros'));
    await t.pumpAndSettle();
    expect(c.filtros, isEmpty);
    expect(c.dados.value, isNotNull);
    expect(c.erro.value, isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.onClose();
  });
  testWidgets(
      'reputação mantém filtros após falha de uma consulta já carregada',
      (t) async {
    final c = GestaoReputacaoController(
        gateway: Gateway(false), store: agenda.Store(), idFornecedor: 'f');
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child:
                    GestaoReputacaoPainel(controller: c, idFornecedor: 'f')))));
    await t.pumpAndSettle();
    (c.gateway as Gateway).falha = true;
    await c.carregar();
    await t.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<int>), findsWidgets);
    expect(find.byType(OperacaoFalha), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  for (final area in ['agenda', 'financeiro', 'reputacao']) {
    for (final largura in [360.0, 1366.0]) {
      for (final erro in [false, true]) {
        testWidgets('$area em $largura com ${erro ? 'falha' : 'dados'}',
            (t) async {
          await t.binding.setSurfaceSize(Size(largura, 1100));
          addTearDown(() => t.binding.setSurfaceSize(null));
          final g = Gateway(erro), store = agenda.Store();
          final ac = AgendaFornecedorController(gateway: g, store: store);
          final fc = PlanejamentoFinanceiroController(gateway: g, store: store);
          final rc = GestaoReputacaoController(
              gateway: g, store: store, idFornecedor: 'f');
          Widget pagina() => switch (area) {
                'agenda' => AgendaFornecedorPage(controller: ac),
                'financeiro' => PlanejamentoFinanceiroPage(controller: fc),
                _ => OperacaoScaffold(
                    title: 'Reputação e respostas',
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: GestaoReputacaoPainel(
                            controller: rc, idFornecedor: 'f')))
              };
          Widget app(double escala) => MaterialApp(
              theme: ThemeData(
                  fontFamily: 'OperacaoPoppins',
                  colorScheme:
                      ColorScheme.fromSeed(seedColor: const Color(0xFF009688))),
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(escala)),
                  child: child!),
              home: pagina());
          await t.pumpWidget(app(1));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          expect(find.text('internal'), findsNothing);
          if (erro) {
            expect(find.byType(OperacaoFalha), findsOneWidget);
            expect(find.text('Tentar novamente'), findsOneWidget);
            expect(find.text('Aplicar filtros'), findsNothing);
          }
          await expectLater(
              find.byType(Scaffold).first,
              matchesGoldenFile(
                  '../../../docs/evidencias_validacao/operacao-fornecedor/mensagens/$area-${largura.toInt()}-${erro ? 'falha' : 'dados'}.png'));
          await t.pumpWidget(app(2));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          if (erro) {
            g.falha = false;
            await t.ensureVisible(find.text('Tentar novamente'));
            await t.pumpAndSettle();
            await t.tap(find.text('Tentar novamente'));
            await t.pumpAndSettle();
            expect(find.byType(OperacaoFalha), findsNothing);
            expect(t.takeException(), isNull);
          }
          await t.pumpWidget(const SizedBox());
          ac.onClose();
          fc.onClose();
        });
      }
    }
  }
}
