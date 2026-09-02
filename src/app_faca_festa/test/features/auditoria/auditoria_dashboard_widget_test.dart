import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/repositories/auditoria_repository.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_auditoria.dart';
import 'package:app_faca_festa/presentation/modules/auditoria/controllers/auditoria_controller.dart';
import 'package:app_faca_festa/presentation/modules/tema/controllers/event_theme_controller.dart';
import 'package:app_faca_festa/presentation/pages/admin/auditoria_dashboard_screen.dart';
import 'package:app_faca_festa/presentation/widgets/auditoria/auditoria_evento_card.dart';
import 'package:app_faca_festa/presentation/widgets/auditoria/auditoria_filtros.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  testWidgets('dashboard expands and collapses from the compact state',
      (tester) async {
    final controller = AuditoriaController(
      gerenciarAuditoria: GerenciarAuditoria(_AuditoriaRepositoryFake()),
      escopoAdmin: true,
    );
    controller.eventos.value = [
      AuditoriaEvento(
        id: '1',
        acao: 'LOGIN_REALIZADO',
        area: 'ACESSO',
        nivel: 'INFO',
        resumo: 'Login realizado',
        atorNome: 'Admin',
        criadoEm: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: AuditoriaDashboardPanel(
              controller: controller,
              theme: _theme,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ver painel completo'), findsOneWidget);
    expect(find.text('Atividade nos últimos 7 dias'), findsNothing);

    await tester.tap(find.text('Ver painel completo'));
    await tester.pump();

    expect(find.text('Recolher painel'), findsOneWidget);
    expect(find.text('Atividade nos últimos 7 dias'), findsOneWidget);

    await tester.tap(find.text('Recolher painel'));
    await tester.pump();

    expect(find.text('Ver painel completo'), findsOneWidget);
    expect(find.text('Atividade nos últimos 7 dias'), findsNothing);
  });

  testWidgets('event card opens full detail with copy evidence action',
      (tester) async {
    const evento = AuditoriaEvento(
      id: 'audit-1',
      acao: 'COTACAO_FECHADA',
      area: 'COTACAO',
      nivel: 'INFO',
      resumo: 'Cotação fechada com fornecedor selecionado.',
      entidadeTipo: 'cotacao',
      entidadeId: 'cot-1',
      entidadeNome: 'Fotografia',
      atorNome: 'Amanda Admin',
      atorEmail: 'admin@faca.festa',
      origem: 'firestore_trigger',
      operacao: 'updated',
      documentPath: 'cotacao/cot-1',
      sourceEventId: 'firebase-event-1',
      hashIntegridade: 'hash-integridade-1',
      algoritmoHash: 'sha256',
      detalhe: {
        'status': 'fechado',
      },
      mudancas: [
        AuditoriaMudanca(campo: 'status', de: 'parcial', para: 'fechado'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ScaffoldMessenger(
          child: Scaffold(
            body: AuditoriaEventoCard(
              evento: evento,
              theme: _theme,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cotação fechada'));
    await tester.pumpAndSettle();

    expect(find.text('Identificação'), findsOneWidget);
    expect(find.byTooltip('Copiar evidência'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Contexto'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Contexto'), findsOneWidget);
    expect(find.text('firebase-event-1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Ambiente'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Ambiente'), findsOneWidget);
    expect(find.text('hash-integridade-1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Payload de auditoria'),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text('Alterações'), findsOneWidget);
    expect(find.text('Payload de auditoria'), findsOneWidget);
  });

  testWidgets('dedicated dashboard renders audit indicators', (tester) async {
    final repository = _AuditoriaRepositoryFake()
      ..eventos = [
        AuditoriaEvento(
          id: '1',
          acao: 'LOGIN_REALIZADO',
          area: 'ACESSO',
          nivel: 'INFO',
          resumo: 'Login realizado',
          atorNome: 'Admin',
          hashIntegridade: 'hash-1',
          origem: 'firestore_trigger',
          criadoEm: DateTime.now(),
        ),
        AuditoriaEvento(
          id: '2',
          acao: 'LOGIN_FALHOU',
          area: 'ACESSO',
          nivel: 'WARN',
          resumo: 'Falha de login',
          atorNome: 'Sistema',
          origem: 'firestore_trigger',
          criadoEm: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    Get.put<GerenciarAuditoria>(GerenciarAuditoria(repository));
    Get.put<EventThemeController>(EventThemeController());

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: [
          GetPage(
            name: '/admin/auditoria',
            page: () => const Scaffold(body: Text('Histórico')),
          ),
        ],
        home: AuditoriaDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard de auditoria'), findsOneWidget);
    expect(find.text('Últimos 15 dias'), findsOneWidget);
    expect(find.text('Saúde operacional'), findsOneWidget);
    expect(find.text('Sem hash'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Principais ações'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Principais ações'), findsOneWidget);
  });
}

const _theme = AuditoriaVisualTheme(
  surface: Color(0xFFF8FAFC),
  card: Colors.white,
  ink: Color(0xFF111827),
  muted: Color(0xFF64748B),
  border: Color(0xFFE2E8F0),
  primary: Color(0xFF0F766E),
  danger: Color(0xFFE11D48),
  warning: Color(0xFFF97316),
  success: Color(0xFF059669),
);

class _AuditoriaRepositoryFake implements AuditoriaRepository {
  List<AuditoriaEvento> eventos = const [];

  @override
  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta) async =>
      eventos;

  @override
  Future<AuditoriaPagina> listarPagina(AuditoriaConsulta consulta) async {
    return AuditoriaPagina(eventos: eventos);
  }

  @override
  Future<String> registrar(RegistroAuditoria registro) async => 'ok';

  @override
  Future<void> registrarFalhaLogin(RegistroFalhaLogin registro) async {}
}
