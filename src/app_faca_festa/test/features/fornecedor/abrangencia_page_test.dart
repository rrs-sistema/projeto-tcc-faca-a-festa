import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/data/datasources/remote/abrangencia_remote_datasource.dart';
import 'package:app_faca_festa/data/services/functions/callable_sessao_gateway.dart';
import 'package:app_faca_festa/presentation/modules/admin/pages/tabelas_abrangencia_admin_page.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/pages/abrangencia_fornecedor_page.dart';

void main() {
  testWidgets('fornecedor consulta o raio e abre as condições de abrangência',
      (tester) async {
    final gateway = _GatewayAbrangencia();
    await tester.pumpWidget(GetMaterialApp(
      home: AbrangenciaFornecedorPage(
        datasource: AbrangenciaRemoteDatasource(gateway: gateway),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('34 km de raio'), findsOneWidget);
    expect(find.text('Até 20 km'), findsOneWidget);
    expect(find.text('Até 30 km'), findsOneWidget);
    expect(find.text(r'R$ 22,00'), findsOneWidget);
    expect(
        find.text('A contratação ainda não está disponível.'), findsOneWidget);

    await tester.tap(find.text('Ver condições de abrangência'));
    await tester.pumpAndSettle();
    expect(find.text('Condições de Abrangência do Fornecedor'), findsOneWidget);
  });

  testWidgets(
      'admin publica faixas consecutivas e envia os valores em centavos',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = _GatewayAbrangencia();
    await tester.pumpWidget(MaterialApp(
      home: TabelasAbrangenciaAdminPage(
        datasource: AbrangenciaRemoteDatasource(gateway: gateway),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar tabela'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(gateway.publicacao, isNull);
    expect(find.text('Informe um valor maior que zero.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '1000');
    await tester.pump();
    expect(find.text(r'Total até 25 km R$ 10,00/mês'), findsOneWidget);
    await tester.ensureVisible(find.text('Adicionar 5 km'));
    await tester.tap(find.text('Adicionar 5 km'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.enterText(find.byType(TextFormField).last, '1200');
    await tester.pump();
    expect(find.text(r'Total até 30 km R$ 22,00/mês'), findsOneWidget);
    await tester.ensureVisible(find.text('Remover última faixa'));
    await tester.tap(find.text('Remover última faixa'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Adicionar 5 km'));
    await tester.tap(find.text('Adicionar 5 km'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty);
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.enterText(find.byType(TextFormField).last, '1200');
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();

    expect(gateway.publicacao?['vigencia'], '2040-04-01');
    expect(gateway.publicacao?['valoresCentavos'], [1000, 1200]);
    expect(gateway.publicacao?['pedidoId'], isNotEmpty);
    expect(find.text('Publicar tabela de abrangência'), findsNothing);
  });

  for (final largura in [360.0, 1280.0]) {
    testWidgets(
        'tabela vigente fica aberta e separa publicações futuras em ${largura.toInt()} px',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(largura, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: TabelasAbrangenciaAdminPage(
          datasource: AbrangenciaRemoteDatasource(
              gateway: _GatewayAbrangencia(comTabelas: true)),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tabela vigente'), findsOneWidget);
      expect(find.text('Até 20 km'), findsOneWidget);
      expect(find.text('Até 30 km'), findsOneWidget);
      expect(find.text(r'R$ 22,00'), findsOneWidget);
      expect(find.text('Responsável pela publicação: Ana Administradora'),
          findsOneWidget);
      expect(find.text('admin-teste'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Próximas vigências'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Agendada'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('anterior')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Substituída'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}

class _GatewayAbrangencia implements CallableSessaoGateway {
  _GatewayAbrangencia({this.comTabelas = false});

  final bool comTabelas;
  Map<String, dynamic>? publicacao;

  @override
  String? get usuario => 'usuario-teste';

  @override
  Stream<String?> get sessoes => const Stream.empty();

  @override
  Future<Map<String, dynamic>> chamar(
      String funcao, Map<String, dynamic> dados) async {
    switch (funcao) {
      case 'consultarAbrangenciaFornecedor':
        return {
          'raioGratuitoKm': 20,
          'territorios': [
            {'tipo': 'raio', 'raioKm': 34},
          ],
          'tabela': {
            'id': 'tabela',
            'vigencia': '2040-04-01',
            'faixas': [
              {
                'ateKm': 25,
                'adicionalCentavos': 1000,
                'mensalidadeCentavos': 1000,
              },
              {
                'ateKm': 30,
                'adicionalCentavos': 1200,
                'mensalidadeCentavos': 2200,
              },
            ],
          },
        };
      case 'consultarTabelasAbrangenciaAdmin':
        return {
          'hoje': '2040-04-01',
          'raioGratuitoKm': 20,
          'incrementoKm': 5,
          'vigente': comTabelas ? _tabela('vigente', '2040-04-01') : null,
          'historico': comTabelas
              ? [
                  _tabela('agendada', '2040-05-01'),
                  _tabela('agendada-substituida', '2040-05-01'),
                  _tabela('vigente', '2040-04-01'),
                  _tabela('anterior', '2040-04-01'),
                ]
              : [],
        };
      case 'publicarTabelaAbrangenciaAdmin':
        publicacao = dados;
        return {};
      default:
        throw StateError('Função inesperada: $funcao');
    }
  }

  Map<String, dynamic> _tabela(String id, String vigencia) => {
        'id': id,
        'vigencia': vigencia,
        'publicadaEm': '2040-04-01T15:30:00Z',
        'autorId': 'admin-teste',
        'autorNome': 'Ana Administradora',
        'faixas': [
          {'ateKm': 25, 'adicionalCentavos': 1000, 'mensalidadeCentavos': 1000},
          {'ateKm': 30, 'adicionalCentavos': 1200, 'mensalidadeCentavos': 2200},
        ],
      };
}
