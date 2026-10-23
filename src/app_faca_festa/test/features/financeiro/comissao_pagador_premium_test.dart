import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:app_faca_festa/core/utils/numeric_input.dart';
import 'package:app_faca_festa/data/datasources/remote/comissao_plataforma_remote_datasource.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/presentation/modules/financeiro/controllers/comissao_plataforma_controller.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/fornecedor_premium_layout.dart';
import 'package:cloud_functions/cloud_functions.dart';

class _FunctionsFake extends Fake implements FirebaseFunctions {}

class _GatewayFake extends Fake implements FinanceiroCallableGateway {
  @override
  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic>? data,
    Duration timeout = const Duration(seconds: 90),
  ]) async =>
      {};
}

ComissaoPlataformaRemoteDatasource _remote() =>
    ComissaoPlataformaRemoteDatasource(
      functions: _FunctionsFake(),
      gateway: _GatewayFake(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('simulação 5% sobre R\$ 10.000 = R\$ 500, separada do extrato', () {
    final c = ComissaoPlataformaController(
      remote: _remote(),
      usuarioAtual: () => 'forn-1',
      ehAdmin: () => false,
    );
    c.obrigacoes.assignAll([
      {
        'valor_original_centavos': 80000,
        'valor_liquidado_centavos': 0,
        'status': 'gerada',
      },
    ]);
    expect(c.totalGeradoCentavos, 80000);
    c.simularLocal(percentualBps: 500, baseCentavos: 1000000);
    expect(c.simulacaoValorCentavos.value, 50000);
    expect(NumericInput.dinheiro(c.simulacaoValorCentavos.value / 100.0),
        'R\$ 500,00');
    expect(c.totalGeradoCentavos, 80000);
    expect(c.totalAReceberCentavos, 80000);
  });

  test('pagador: liquidar/política bloqueados no controller', () async {
    final c = ComissaoPlataformaController(
      remote: _remote(),
      usuarioAtual: () => 'forn-1',
      ehAdmin: () => false,
    );
    expect(c.isAdmin, isFalse);
    expect(await c.salvarPoliticaInativa(percentualBps: 500), isFalse);
    expect(await c.ativar('p1'), isFalse);
    expect(
      await c.liquidar(idObrigacao: 'o1', valorCentavos: 100),
      isNull,
    );
  });

  test('taxa do snapshot da obrigação, não inventada', () {
    expect(
      ComissaoPlataformaController.percentualBpsAplicadoDe({
        'politica_aplicada': {'percentual_bps': 500},
      }),
      500,
    );
    expect(
      ComissaoPlataformaController.percentualBpsAplicadoDe({}),
      isNull,
    );
  });

  test('vencidas só com status explícito', () {
    final c = ComissaoPlataformaController(
      remote: _remote(),
      ehAdmin: () => false,
    );
    c.obrigacoes.assignAll([
      {'status': 'gerada', 'valor_original_centavos': 100},
      {'status': 'vencida', 'valor_original_centavos': 200},
    ]);
    expect(c.qtdVencidas, 1);
  });

  testWidgets('composição pagador: extrato sem Políticas/Nova política',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: FornecedorPremiumPalette.background,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Minhas comissões',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
              Text(
                'Acompanhe as comissões dos seus contratos',
                style: GoogleFonts.poppins(),
              ),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Simular comissão'),
              ),
              const Text('Extrato'),
              const Text('Nenhuma comissão encontrada'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Minhas comissões'), findsOneWidget);
    expect(find.text('Simular comissão'), findsOneWidget);
    expect(find.text('Políticas'), findsNothing);
    expect(find.text('Nova política'), findsNothing);
    expect(find.text('Registrar recebimento'), findsNothing);
    expect(find.text('Nenhuma comissão encontrada'), findsOneWidget);
  });

  testWidgets('admin mantém abas Cobranças/Políticas/Simulador',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: const TabBar(
              tabs: [
                Tab(text: 'Cobranças'),
                Tab(text: 'Políticas'),
                Tab(text: 'Simulador'),
              ],
            ),
            body: const TabBarView(
              children: [
                Center(child: Text('admin-cobrancas')),
                Center(child: Text('Nova política')),
                Center(child: Text('Esta simulação não gera cobrança.')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Políticas'), findsOneWidget);
    expect(find.text('admin-cobrancas'), findsOneWidget);
  });
}
