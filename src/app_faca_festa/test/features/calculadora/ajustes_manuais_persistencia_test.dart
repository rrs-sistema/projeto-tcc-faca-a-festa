import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/estimativa_financeira.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/calculadora_regra_manual_dialog.dart';
import 'calculadora_composicao_test.dart' show AiQA;
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;

ItemEstimativaFinanceira ajuste(String menu, double preco, String estado) =>
    ItemEstimativaFinanceira(
        id: 'menu_${menu}_arroz',
        categoria: 'comida',
        nome: 'Arroz',
        tipoItem: 'comida',
        publicoAlvo: 'todos',
        unidade: UnidadeEstimativa.quilo,
        quantidadePorConvidadoEquivalente: .05,
        valorUnitarioMedio: preco,
        premissas: {
          'id_evento': 'festa',
          'id_cardapio': menu,
          'id_item_cardapio': 'arroz',
          'estado': estado,
          'rendimento': 2,
          'revisada_pelo_organizador': true
        });

class RepoAjustes extends RepoJornada {
  bool falhar = false;
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) {
    if (falhar) throw StateError('Sem conexão para salvar.');
    return super.alterarOperacaoEvento(id, acao);
  }
}

class RepoAjustesLento extends RepoAjustes {
  final resposta = Completer<void>();
  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) async {
    final salvo = await super.alterarOperacaoEvento(id, acao);
    await resposta.future;
    return salvo;
  }
}

void main() {
  late RepoAjustes repo;
  late CalculadoraFestaController c;
  CalculadoraFestaController criar() {
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    c.idEventoAtual.value = 'festa';
    return c;
  }

  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
    repo = RepoAjustes();
    c = criar();
  });
  tearDown(() {
    c.onClose();
    Get.reset();
  });
  test(
      'resposta de preço do acesso anterior não substitui edição feita ao reabrir o mesmo evento',
      () async {
    c.onClose();
    final lento = RepoAjustesLento();
    repo = lento;
    c = criar();
    final gravacao =
        c.salvarItemManual(ajuste('almoco', 5.75, 'seco'), anterior: null);
    await Future<void>.delayed(Duration.zero);
    await c.prepararCalculadora(idEvento: 'festa', tipoEvento: 'Formatura');
    c.adicionarItemManual(ajuste('almoco', 9, 'seco'));
    lento.resposta.complete();
    await gravacao;
    expect(c.regrasManuais.single.valorUnitarioMedio, 9);
  });

  test(
      'preço, estado e rendimento sobrevivem a controlador novo sem executor nem histórico',
      () async {
    await c.salvarItemManual(ajuste('almoco', 5.75, 'seco'), anterior: null);
    await c.salvarItemManual(ajuste('janta', 8, 'pronto'), anterior: null);
    c.onClose();
    c = criar();
    await c.iniciarOperacaoEvento();
    await Future<void>.delayed(Duration.zero);
    final almoco =
        c.regrasManuais.singleWhere((r) => r.id == 'menu_almoco_arroz');
    final janta =
        c.regrasManuais.singleWhere((r) => r.id == 'menu_janta_arroz');
    expect(almoco.valorUnitarioMedio, 5.75);
    expect(almoco.premissas['estado'], 'seco');
    expect(almoco.rendimento, 2);
    expect(janta.valorUnitarioMedio, 8);
    expect(janta.premissas['estado'], 'pronto');
    expect(repo.operacao['execucao']['contexto_desatualizado'], true);
  });

  test('falha de gravação preserva preço anterior e permite nova tentativa',
      () async {
    await c.salvarItemManual(ajuste('almoco', 5, 'seco'), anterior: null);
    final anterior = c.regraPersistida('menu_almoco_arroz');
    repo.falhar = true;
    await expectLater(
        c.salvarItemManual(ajuste('almoco', 9, 'pronto'), anterior: anterior),
        throwsStateError);
    expect(c.regrasManuais.single.valorUnitarioMedio, 5);
    expect(c.regraPersistida('menu_almoco_arroz')!['preco'], 5);
    repo.falhar = false;
    await c.salvarItemManual(ajuste('almoco', 9, 'pronto'), anterior: anterior);
    expect(c.regraPersistida('menu_almoco_arroz')!['preco'], 9);
  });

  test(
      'edição antiga do mesmo item é recusada; repetição igual não aumenta revisão',
      () async {
    final regra = ajuste('almoco', 5, 'seco');
    await c.salvarItemManual(regra, anterior: null);
    final revisao = repo.operacao['revisao'];
    await c.salvarItemManual(regra, anterior: null);
    expect(repo.operacao['revisao'], revisao);
    await expectLater(
        c.salvarItemManual(regra.copyWith(valorUnitarioMedio: 10),
            anterior: null),
        throwsStateError);
    expect(c.regraPersistida(regra.id)!['preco'], 5);
  });

  test(
      'salvamento do conjunto mantém configurações e dados operacionais existentes',
      () async {
    repo.operacao = {
      'revisao': 0,
      'refeicoes': {
        'almoco': {'servico': 'refeicao'}
      },
      'execucao': {
        'compras': [],
        'publico': {'adultos': 37}
      }
    };
    c.operacaoEvento.assignAll(repo.operacao);
    c.adicionarItemManual(ajuste('almoco', 5.75, 'seco'));
    await c.salvarAjustesManuais();
    expect(repo.operacao['refeicoes']['almoco']['servico'], 'refeicao');
    expect(repo.operacao['execucao']['publico']['adultos'], 37);
    expect(repo.operacao['execucao']['regras'].single['preco'], 5.75);
  });

  test('histórico não sobrescreve ajustes do evento atual', () async {
    c.adicionarItemManual(ajuste('almoco', 90, 'pronto'));
    c.usandoContextoHistorico.value = true;
    await c.salvarAjustesManuais();
    expect(repo.operacao, isEmpty);
  });

  test('regra inválida não altera nenhuma parte do conjunto', () {
    final valido = ajuste('almoco', 5.75, 'seco').toPlanejamento();
    final invalido = {
      ...ajuste('janta', 9, 'cru').toPlanejamento(),
      'preco': -1
    };
    final original = <String, dynamic>{'revisao': 0};
    expect(
        () => const OperacaoCalculadoraService().aplicar(original, {
              'tipo': 'regras',
              'revisao': 0,
              'regras': [valido, invalido],
              'anteriores': {valido['id']: null, invalido['id']: null}
            }),
        throwsArgumentError);
    expect(original, {'revisao': 0});
  });

  testWidgets(
      'modal mantém valores após falha, bloqueia envio duplo e fecha somente após confirmar gravação',
      (tester) async {
    var chamadas = 0;
    Completer<void>? pendente;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    child: const Text('Editar'),
                    onPressed: () => showDialog<ItemEstimativaFinanceira>(
                        context: context,
                        builder: (_) => CalculadoraRegraManualDialog(
                            inicial: ajuste('almoco', 5.75, 'seco'),
                            onSalvar: (_) async {
                              chamadas++;
                              if (chamadas == 1) {
                                throw StateError(
                                    'Falha de conexão. Tente novamente.');
                              }
                              pendente = Completer<void>();
                              await pendente!.future;
                            })))))));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('erro_salvar_regra')), findsOneWidget);
    expect(find.byType(CalculadoraRegraManualDialog), findsOneWidget);
    final preco = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Preço por kg'));
    expect(preco.controller!.text, contains('5,75'));
    await tester.tap(find.text('Usar no cálculo'));
    await tester.pump();
    expect(chamadas, 2);
    expect(find.text('Salvando…'), findsOneWidget);
    await tester.tap(find.text('Salvando…'), warnIfMissed: false);
    await tester.pump();
    expect(chamadas, 2);
    pendente!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraRegraManualDialog), findsNothing);
  });
}
