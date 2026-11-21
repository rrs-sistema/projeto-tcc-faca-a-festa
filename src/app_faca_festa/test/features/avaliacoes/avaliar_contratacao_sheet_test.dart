import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/domain/repositories/avaliacao_servico_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_avaliacoes_servico.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/controllers/avaliacao_servico_controller.dart';
import 'package:app_faca_festa/presentation/modules/avaliacao/pages/avaliar_contratacao_sheet.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/widgets/star_rating_widget.dart';

class _Repo implements AvaliacaoServicoRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Controller extends AvaliacaoServicoController {
  _Controller(this.lista)
      : super(avaliacoes: GerenciarAvaliacoesServico(_Repo()));
  final List<Map<String, dynamic>> lista;
  final enviadas = <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> contratosAvaliaveis(
          {required String idFornecedor,
          required String idEvento,
          String? idServico,
          String? idOrcamento,
          bool detalhar = false}) async =>
      lista;

  @override
  Future<void> registrarAvaliacao({
    required String idFornecedor,
    required String idOrcamento,
    required int nota,
    required String comentario,
    String? idServico,
    String? idEvento,
  }) async {
    enviadas.add({
      'idOrcamento': idOrcamento,
      'nota': nota,
      'idServico': idServico,
      'comentario': comentario,
    });
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(Get.reset);

  testWidgets('as duas notas aparecem juntas e o envio espera estrela inteira',
      (t) async {
    final c = _Controller([
      {
        'idOrcamento': 'o1',
        'idContrato': 'c1',
        'nome': 'Arco floral',
        'idServico': 's1',
        'pendenteFornecedor': true,
        'pendenteServico': true,
        'elegivel': true,
      }
    ]);
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: AvaliarContratacaoSheet(
          idFornecedor: 'f',
          idEvento: 'e',
          idOrcamento: 'o1',
          nomeFornecedor: 'Débora Festas',
          nomeServico: 'Arco floral',
          controller: c,
          themeController: EventThemeController(),
        ),
      ),
    ));
    await t.pumpAndSettle();

    expect(find.text('Como foi esta contratação?'), findsOneWidget);
    expect(find.textContaining('não se somam'), findsOneWidget);
    expect(find.text('O fornecedor'), findsOneWidget);
    expect(find.text('Este serviço'), findsOneWidget);
    expect(find.text('Enviar as duas notas'), findsOneWidget);
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    await t.tap(find.byType(StarRatingWidget).at(0));
    await t.tap(find.byType(StarRatingWidget).at(1));
    await t.pumpAndSettle();
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull);

    await t.tap(find.text('Enviar as duas notas'));
    await t.pumpAndSettle();
    expect(c.enviadas, hasLength(2));
    expect(c.enviadas.every((e) => e['nota'] is int), isTrue);
    expect(c.enviadas.map((e) => e['idServico']).toList(), [null, 's1']);
  });

  testWidgets('nota já enviada fica só como confirmação', (t) async {
    final c = _Controller([
      {
        'idOrcamento': 'o1',
        'nome': 'Buffet',
        'idServico': 's1',
        'pendenteFornecedor': false,
        'pendenteServico': true,
      }
    ]);
    await t.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: AvaliarContratacaoSheet(
          idFornecedor: 'f',
          idEvento: 'e',
          idOrcamento: 'o1',
          controller: c,
          themeController: EventThemeController(),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.textContaining('nota do fornecedor já foi enviada'),
        findsOneWidget);
    expect(find.text('Enviar nota do serviço'), findsOneWidget);
    expect(find.byType(StarRatingWidget), findsOneWidget);
  });

  testWidgets('sem entrega aceita explica o próximo passo', (t) async {
    final c = _Controller([]);
    await t.pumpWidget(GetMaterialApp(
      home: Scaffold(
        body: AvaliarContratacaoSheet(
          idFornecedor: 'f',
          idEvento: 'e',
          idOrcamento: 'o1',
          controller: c,
          themeController: EventThemeController(),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.textContaining('ainda não está pronta para nota'),
        findsOneWidget);
    expect(find.byType(StarRatingWidget), findsNothing);
  });
}
