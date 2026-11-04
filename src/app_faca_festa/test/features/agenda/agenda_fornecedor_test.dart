import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/data/local/recebimento_pendente_store.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/controllers/agenda_fornecedor_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/agenda/agenda_fornecedor_page.dart';

class Store implements RecebimentoPendenteStore {
  final m = <String, Map<String, dynamic>>{};
  @override
  Future<Map<String, dynamic>?> ler(String u) async => m[u];
  @override
  Future<void> salvar(String u, Map<String, dynamic> d) async {
    m[u] = d;
  }

  @override
  Future<void> limpar(String u, {String? chave}) async {
    if (chave == null || m[u]?['chave'] == chave) m.remove(u);
  }
}

Map<String, dynamic> fixture() => {
      'capacidade': 2,
      'revisaoConfig': 3,
      'itens': <Map>[],
      'reservas': [],
      'compromissos': [
        {
          'idOrcamento': 'a',
          'idContrato': 'a',
          'idEvento': 'e',
          'idCotacao': null,
          'servico': 'Buffet contratado',
          'local': 'Local compartilhado',
          'dataEvento': '2030-01-02T03:00:00Z',
          'estadoExecucao': 'agendado',
          'ativo': true,
          'revisao': 1,
          'unidades': 1,
          'recursos': [],
          'pendencias': [],
          'referenciasCalculadora': [],
          'agenda': {
            'fuso': 'America/Sao_Paulo',
            'janelas': [
              {
                'tipo': 'montagem',
                'inicio': '2030-01-02T12:00:00Z',
                'fim': '2030-01-02T13:00:00Z'
              },
              {
                'tipo': 'execucao',
                'inicio': '2030-01-02T13:00:00Z',
                'fim': '2030-01-02T15:00:00Z'
              }
            ]
          }
        },
        {
          'idOrcamento': 'b',
          'idContrato': 'b',
          'idEvento': 'e',
          'servico': 'Contrato sem horário',
          'local': null,
          'dataEvento': null,
          'estadoExecucao': 'nao_iniciado',
          'ativo': true,
          'agenda': null,
          'revisao': 0,
          'unidades': 1,
          'recursos': [],
          'pendencias': ['Horário e intervalo pendentes'],
          'referenciasCalculadora': []
        }
      ]
    };

class Gateway implements CallableSessaoGateway {
  String? uid = 'f';
  final stream = StreamController<String?>.broadcast();
  final chamadas = <Map<String, dynamic>>[];
  Map<String, dynamic> d = fixture();
  bool falhaConsulta = false, timeout = false, conflito = false;
  Completer<Map<String, dynamic>>? leitura;
  @override
  String? get usuario => uid;
  @override
  Stream<String?> get sessoes => stream.stream;
  @override
  Future<Map<String, dynamic>> chamar(String f, Map<String, dynamic> x) async {
    if (f == 'consultarAgendaFornecedorFn') {
      if (falhaConsulta) throw Exception('indisponível');
      return leitura?.future ?? Future.value(d);
    }
    chamadas.add({'funcao': f, ...x});
    if (timeout) {
      timeout = false;
      throw TimeoutException('após commit');
    }
    if (conflito) {
      throw FirebaseFunctionsException(
          code: 'failed-precondition', message: 'Conflito de capacidade');
    }
    if (f == 'configurarCapacidadeFornecedorFn') {
      d = {...d, 'capacidade': x['capacidade'], 'revisaoConfig': 4};
    }
    return {'ok': true};
  }

  void trocar(String? u) {
    uid = u;
    stream.add(u);
  }
}

void main() {
  test('resultado desconhecido preserva chave e payload ao reabrir', () async {
    final g = Gateway(),
        s = Store(),
        c = AgendaFornecedorController(gateway: g, store: s);
    await c.iniciar();
    g.timeout = true;
    expect(
        await c.comandar(
            'configurarCapacidadeFornecedorFn', {'capacidade': 2, 'revisao': 3},
            geracao: c.geracao),
        false);
    final primeiro = g.chamadas.single;
    c.onClose();
    final reaberto = AgendaFornecedorController(gateway: g, store: s);
    await reaberto.iniciar();
    expect(reaberto.pendente.value, isNotNull);
    expect(await reaberto.retomar(), true);
    expect(g.chamadas.last, primeiro);
    expect(s.m, isEmpty);
    reaberto.onClose();
    await g.stream.close();
  });
  test('resultado antigo de consulta descartado na troca de sessão', () async {
    final g = Gateway(),
        c = AgendaFornecedorController(gateway: g, store: Store());
    await c.iniciar();
    g.leitura = Completer();
    final load = c.carregar();
    g.trocar(null);
    await Future<void>.delayed(Duration.zero);
    g.leitura!.complete(fixture());
    await load;
    expect(c.dados.value, isNull);
    c.onClose();
    await g.stream.close();
  });
  testWidgets('agenda mostra janelas com fuso e sem horário inventado',
      (t) async {
    await t.binding.setSurfaceSize(const Size(1100, 1500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway(),
        c = AgendaFornecedorController(gateway: g, store: Store());
    await t.pumpWidget(MaterialApp(home: AgendaFornecedorPage(controller: c)));
    await t.pumpAndSettle();
    expect(
        find.textContaining('Execução: 02/01/2030 10:00 (America/Sao_Paulo)'),
        findsOneWidget);
    expect(find.text('Intervalo pendente de definição'), findsOneWidget);
    expect(find.textContaining('Montagem:'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('configuração envia revisão e persiste retorno', (t) async {
    final g = Gateway(),
        c = AgendaFornecedorController(gateway: g, store: Store());
    await t.pumpWidget(MaterialApp(home: AgendaFornecedorPage(controller: c)));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('· Configurar'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, '3');
    await t.tap(find.text('Salvar capacidade'));
    await t.pumpAndSettle();
    expect(g.chamadas.single['capacidade'], 3);
    expect(g.chamadas.single['revisao'], 3);
    expect(find.textContaining('Capacidade: 3'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('falha tem retry e não exibe capacidade zero', (t) async {
    final g = Gateway()..falhaConsulta = true,
        c = AgendaFornecedorController(gateway: g, store: Store());
    await t.pumpWidget(MaterialApp(home: AgendaFornecedorPage(controller: c)));
    await t.pumpAndSettle();
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.textContaining('Capacidade: 0'), findsNothing);
    g.falhaConsulta = false;
    await t.tap(find.text('Tentar novamente'));
    await t.pumpAndSettle();
    expect(find.textContaining('Capacidade: 2'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('troca de sessão bloqueia formulário antigo', (t) async {
    final g = Gateway(),
        c = AgendaFornecedorController(gateway: g, store: Store());
    await t.pumpWidget(MaterialApp(home: AgendaFornecedorPage(controller: c)));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('· Configurar'));
    await t.pumpAndSettle();
    g.trocar(null);
    await t.pumpAndSettle();
    expect(find.text('Sessão alterada'), findsOneWidget);
    expect(find.text('Salvar capacidade'), findsNothing);
    expect(g.chamadas, isEmpty);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('reagendamento revisado e conflito não altera compromisso',
      (t) async {
    await t.binding.setSurfaceSize(const Size(1100, 1500));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway()..conflito = true,
        c = AgendaFornecedorController(gateway: g, store: Store());
    await t.pumpWidget(MaterialApp(home: AgendaFornecedorPage(controller: c)));
    await t.pumpAndSettle();
    await t.tap(find.text('Reagendar com revisão'));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(
            TextFormField, 'Motivo da confirmação/reagendamento'),
        'Revisão de equipe e montagem');
    await t.ensureVisible(find.text('Revalidar e confirmar'));
    await t.tap(find.text('Revalidar e confirmar'));
    await t.pumpAndSettle();
    expect(g.chamadas.single['revisao'], 1);
    expect(g.chamadas.single['agenda']['janelas'][1]['inicio'],
        '2030-01-02T13:00:00.000Z');
    expect(find.text('Conflito de capacidade'), findsOneWidget);
    expect(c.pendente.value, isNull);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  testWidgets('agenda responsiva em 360 pixels', (t) async {
    await t.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final g = Gateway(),
        c = AgendaFornecedorController(gateway: g, store: Store());
    await t.pumpWidget(MaterialApp(home: AgendaFornecedorPage(controller: c)));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Agenda e capacidade'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    c.onClose();
    await g.stream.close();
  });
  test('movimento físico usa callable existente com chave estável', () async {
    final g = Gateway(),
        s = Store(),
        c = AgendaFornecedorController(gateway: g, store: s);
    await c.iniciar();
    expect(
        await c.comandar('devolverEstoqueFornecedor',
            {'idFornecedor': 'f', 'idReserva': 'r'},
            geracao: c.geracao),
        true);
    expect(g.chamadas.single['funcao'], 'devolverEstoqueFornecedor');
    expect(g.chamadas.single['chaveIdempotencia'], g.chamadas.single['chave']);
    c.onClose();
    await g.stream.close();
  });
}
