import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/presentation/modules/fornecedor/sections/atualizacao_indicadores.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final f = FontLoader('PainelPoppins');
    for (final arquivo in ['Poppins-Regular.ttf', 'Poppins-SemiBold.ttf']) {
      f.addFont(Future.value(ByteData.sublistView(
          await File('assets/fonts/$arquivo').readAsBytes())));
    }
    await f.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('horário é convertido para Brasília, sem ISO ou data inventada', () {
    expect(horarioAtualizacaoPainel('2026-10-27T13:52:57.415Z'),
        '27/10/2026 às 10:52 · Brasília');
    expect(horarioAtualizacaoPainel(null), 'Atualização ainda não informada');
    expect(horarioAtualizacaoPainel('inválida'),
        'Atualização ainda não informada');
  });
  for (final largura in [360.0, 1280.0]) {
    testWidgets('status compacto e diagnóstico recolhido em $largura',
        (t) async {
      await t.binding.setSurfaceSize(Size(largura, 950));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final dados = <String, dynamic>{
        'consultadoEm': '2026-10-27T13:52:57.415Z',
        'fontes': {
          for (final nome in AtualizacaoIndicadores.nomes.keys)
            nome: {
              'estado': nome == 'estoque' ? 'indisponivel' : 'disponivel',
              if (nome == 'estoque') 'codigo': 'permission-denied'
            }
        }
      };
      Widget app(double escala) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
              fontFamily: 'PainelPoppins',
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(escala)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AtualizacaoIndicadores(
                      dados: dados, complementoIndisponivel: true))));
      await t.pumpWidget(app(1));
      await t.pumpAndSettle();
      expect(find.text('Atualização dos dados'), findsOneWidget);
      expect(find.text('27/10/2026 às 10:52 · Brasília'), findsOneWidget);
      expect(find.text('permission-denied'), findsNothing);
      await t.tap(find.text('Atualização dos dados'));
      await t.pumpAndSettle();
      expect(find.text('4 de 5 consultas disponíveis'), findsOneWidget);
      expect(find.text('Catálogo · Disponível'), findsOneWidget);
      expect(find.text('Estoque · Indisponível'), findsOneWidget);
      expect(find.textContaining('13:52:57.415Z'), findsNothing);
      expect(find.textContaining('Firestore'), findsNothing);
      await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
              '../../../docs/evidencias_validacao/operacao-fornecedor/atualizacao-indicadores/status-${largura.toInt()}.png'));
      await t.tap(find.text('Sobre os indicadores'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Detalhes para suporte'));
      await t.pumpAndSettle();
      await t.tap(find.text('Detalhes para suporte'));
      await t.pumpAndSettle();
      expect(find.textContaining('Estoque · código: permission-denied'),
          findsOneWidget);
      await t.pumpWidget(app(2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('primeira consulta ausente não vira status disponível',
      (t) async {
    await t.pumpWidget(
        const MaterialApp(home: Scaffold(body: AtualizacaoIndicadores())));
    expect(find.text('Aguardando a primeira consulta'), findsOneWidget);
    await t.tap(find.text('Atualização dos dados'));
    await t.pumpAndSettle();
    expect(find.text('0 de 5 consultas disponíveis'), findsNothing);
    expect(find.text('Contratos · Não informado'), findsOneWidget);
  });
}
