import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/pages/central_mediacao_detalhe_page.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/data/datasources/remote/central_mediacao_remote.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/central_mediacao_controller.dart';
import 'package:app_faca_festa/domain/entities/financeiro/mediacao_operacional.dart';

class _Remote extends Fake implements CentralMediacaoRemote {
  int chamadas = 0;
  int consultasCaso = 0;
  bool incluirHistorico = false;
  String? enviado;
  bool falhar = false;

  @override
  Future<Map<String, dynamic>> consultarDetalhe(
          {required String idOrcamento}) async =>
      {
        'resumo': {
          'idEvento': 'evento',
          'estadoComercial': 'Contratado',
          'nomeServico': 'Decoração'
        },
        'contratacao_servico': {
          'estado_comercial': 'Contratado',
          'estado_execucao': 'entrega_informada'
        },
        'historico_mediacao': {
          'caso_aberto': {'id': 'caso'},
          if (incluirHistorico)
            'consulta_caso': {
              'caso': {'id': 'caso', 'estado': 'em_analise'},
              'registros': [
                {'id': 'registro', 'texto': 'Registro consolidado'},
              ],
            },
        },
      };

  @override
  dynamic noSuchMethod(Invocation invocation) {
    chamadas++;
    return super.noSuchMethod(invocation);
  }

  @override
  Future<Map<String, dynamic>> registrarRegistro(
      {required String idCaso,
      required String texto,
      String tipo = 'analise',
      String? visibilidade,
      String? novoEstado}) async {
    chamadas++;
    enviado = texto;
    if (falhar) {
      throw const FinanceiroCallableException(
          'invalid-argument', 'Informe o texto do registro.');
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> consultarCaso(
      {required String idCaso,
      String? papelConsulta,
      String? idFornecedorOperador}) async {
    consultasCaso++;
    return {
      'caso': {'id': idCaso, 'estado': 'em_analise'},
      'registros': []
    };
  }
}

class _Functions extends Fake implements FirebaseFunctions {}

class _Gateway extends Fake implements FinanceiroCallableGateway {
  @override
  Future<Map<String, dynamic>> call(String nome,
      [Map<String, dynamic>? dados,
      Duration timeout = const Duration(seconds: 90)]) async {
    final consulta = {
      'caso': {
        'id': 'caso',
        'estado': 'em_analise',
        'idResponsavel': 'uid-atual',
      },
      'registros': [
        for (final id in ['uid-anterior', 'uid-atual', 'uid-removido'])
          {
            'tipo': 'atribuicao',
            'texto': 'Responsável atribuído: $id',
            'autorId': 'uid-autor',
          },
        {'tipo': 'nota_interna', 'texto': 'Análise concluída.'},
      ],
    };
    if (nome == 'consultarCasoMediacao') {
      return {
        ...consulta,
        'papel_consulta': dados?['papelConsulta'] ?? 'admin',
      };
    }
    expect(nome, 'consultarDetalheContratacao');
    return {
      'resumo': {'nomeServico': 'Decoração'},
      'historico_mediacao': {'consulta_caso': consulta},
    };
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  final lidos = <String>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    expect(collectionPath, 'usuarios');
    return _Usuarios(lidos);
  }
}

// ignore: subtype_of_sealed_class
class _Usuarios extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Usuarios(this.lidos);
  final List<String> lidos;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    lidos.add(path!);
    return _UsuarioDoc(path);
  }
}

// ignore: subtype_of_sealed_class
class _UsuarioDoc extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _UsuarioDoc(this.uid);
  final String uid;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get(
          [GetOptions? options]) async =>
      _UsuarioSnapshot(switch (uid) {
        'uid-atual' => {'nome': ' Maria Costa '},
        'uid-anterior' => {'nome_completo': 'João Silva'},
        _ => null,
      });
}

// ignore: subtype_of_sealed_class
class _UsuarioSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _UsuarioSnapshot(this.dados);
  final Map<String, dynamic>? dados;

  @override
  Map<String, dynamic>? data() => dados;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test(
      'resolve os responsáveis do caso e do histórico apenas na consulta admin',
      () async {
    final db = _Firestore();
    final remote = CentralMediacaoRemote(
        functions: _Functions(), firestore: db, gateway: _Gateway());
    final admin = await remote.consultarCaso(idCaso: 'caso');
    expect(admin['caso']['nomeResponsavel'], 'Maria Costa');
    expect(admin['caso']['idResponsavel'], 'uid-atual');
    expect((admin['registros'] as List).map((r) => r['texto']), [
      'Responsável atribuído: João Silva',
      'Responsável atribuído: Maria Costa',
      'Responsável atribuído (nome indisponível)',
      'Análise concluída.',
    ]);
    expect(db.lidos,
        unorderedEquals(['uid-atual', 'uid-anterior', 'uid-removido']));
    db.lidos.clear();
    await remote.consultarCaso(idCaso: 'caso', papelConsulta: 'cliente');
    expect(db.lidos, isEmpty);
  });

  testWidgets('detalhe mostra o nome atual e os nomes das atribuições antigas',
      (tester) async {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final remote = CentralMediacaoRemote(
        functions: _Functions(), firestore: _Firestore(), gateway: _Gateway());
    await tester.pumpWidget(GetMaterialApp(
        home: CentralMediacaoDetalhePage(
            controller: CentralMediacaoController(remote: remote),
            themeController: EventThemeController(),
            idOrcamento: 'orc',
            abrirMediacao: true)));
    await tester.pumpAndSettle();
    expect(find.text('Maria Costa'), findsOneWidget);
    expect(find.text('Responsável atribuído: João Silva'), findsOneWidget);
    expect(find.text('Responsável atribuído: Maria Costa'), findsOneWidget);
    expect(find.textContaining('uid-'), findsNothing);
  });

  test('usa os registros do detalhe e aceita respostas da versão anterior',
      () async {
    final remote = _Remote()..incluirHistorico = true;
    final controller = CentralMediacaoController(remote: remote);
    await controller.abrirDetalhe('orc');
    expect(remote.consultasCaso, 0);
    expect(controller.casoDetalhe.value?['estado'], 'em_analise');
    expect(controller.registrosCaso.single.texto, 'Registro consolidado');

    remote.incluirHistorico = false;
    await controller.abrirDetalhe('orc');
    expect(remote.consultasCaso, 1);
    expect(controller.registrosCaso, isEmpty);
  });

  testWidgets(
      'nota vazia mostra erro no campo e permite corrigir sem erro global',
      (tester) async {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1366, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final remote = _Remote();
    final controller = CentralMediacaoController(remote: remote);
    await tester.pumpWidget(GetMaterialApp(
        home: CentralMediacaoDetalhePage(
            controller: controller,
            themeController: EventThemeController(),
            idOrcamento: 'orc')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mediação e histórico'));
    await tester.pumpAndSettle();
    final nota = find.text('Nota interna');
    await tester.scrollUntilVisible(nota, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(nota);
    await tester.pumpAndSettle();
    await tester.tap(nota);
    await tester.pumpAndSettle();
    expect(remote.chamadas, 0);
    expect(controller.erro.value, isEmpty);
    expect(controller.erroRegistro.value,
        'Escreva o texto no campo Novo registro antes de continuar.');
    expect(
        find.text('Escreva o texto no campo Novo registro antes de continuar.'),
        findsOneWidget);
    final campo = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Novo registro');
    expect(tester.widget<TextField>(campo).focusNode!.hasFocus, true);
    await tester.enterText(campo, 'Análise documentada.');
    await tester.pumpAndSettle();
    expect(controller.erroRegistro.value, isEmpty);
    await tester.ensureVisible(nota);
    await tester.tap(nota);
    await tester.pumpAndSettle();
    expect(remote.chamadas, 1);
    expect(tester.widget<TextField>(campo).controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('texto vazio ou só espaços não chama servidor para ações do registro',
      () async {
    final remote = _Remote();
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    for (final texto in ['', '   \n ']) {
      expect(await c.registrarAnalise(texto), false);
      expect(await c.registrarAnalise(texto, interna: false), false);
      expect(await c.solicitarInfo(texto), false);
      expect(await c.registrarDecisao(texto), false);
      expect(await c.recomendarBloqueio(texto), false);
      expect(c.erroRegistro.value, contains('Novo registro'));
    }
    expect(remote.chamadas, 0);
    expect(c.erro.value, isEmpty);
    expect(c.enviando.value, false);
  });

  test('decisão e conclusão respeitam os limites do backend antes de enviar',
      () async {
    final remote = _Remote();
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    for (final texto in ['curto', List.filled(2001, 'a').join()]) {
      expect(await c.registrarDecisao(texto), false);
      expect(c.erroRegistro.value, contains('10 a 2000'));
      expect(await c.fecharCaso(texto), false);
      expect(c.erroConclusao.value, contains('10 a 2000'));
    }
    expect(remote.chamadas, 0);
  });

  test('registro válido limpa erro anterior e envia texto sem espaços externos',
      () async {
    final remote = _Remote();
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    await c.registrarAnalise('');
    c.erro.value = 'erro antigo';
    expect(await c.registrarAnalise('  Análise documentada.  '), true);
    expect(remote.enviado, 'Análise documentada.');
    expect(remote.chamadas, 1);
    expect(c.erroRegistro.value, isEmpty);
    expect(c.erro.value, isEmpty);
  });

  test('erro conhecido de envio fica no campo sem prefixo técnico', () async {
    final remote = _Remote()..falhar = true;
    final c = CentralMediacaoController(remote: remote);
    c.casoDetalhe.value = {'id': 'caso'};
    expect(await c.registrarAnalise('Análise documentada.'), false);
    expect(c.erroRegistro.value, 'Informe o texto do registro.');
    expect(c.erro.value, isEmpty);
  });

  test('linha normaliza o estado comercial recebido com maiúsculas e espaços',
      () {
    final linha =
        LinhaCentralContratacao.fromMap({'estado_comercial': ' Contratado '});
    expect(linha.estadoComercial, 'contratado');
  });
}
