import 'package:app_faca_festa/presentation/modules/financeiro/widgets/ajuda_fluxo_financeiro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (perfil, botao, primeiraEtapa) in [
    (
      PerfilAjudaFinanceira.organizador,
      'Entenda o pagamento',
      'Pague e declare'
    ),
    (
      PerfilAjudaFinanceira.fornecedor,
      'Como funciona o repasse',
      'Valor previsto'
    ),
    (
      PerfilAjudaFinanceira.administrador,
      'Guia de recebimento e repasse',
      'Conferir e registrar o recebimento',
    ),
  ]) {
    testWidgets('ajuda de ${perfil.name} abre o contexto e o guia',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: AjudaFluxoFinanceiro(
            perfil: perfil,
            contrato: (
              contrato: 'Arco floral para altar',
              situacao: 'Pagamento em conferência',
              proximoPasso: 'Acompanhar a conferência',
              responsavel: 'plataforma',
            ),
          ),
        ),
      ));
      await tester.tap(find.text(botao));
      await tester.pumpAndSettle();
      expect(find.text('Arco floral para altar'), findsOneWidget);
      expect(find.text('Pagamento em conferência'), findsOneWidget);
      expect(find.text('Quem age • Plataforma'), findsOneWidget);
      expect(find.text('Acompanhar a conferência'), findsOneWidget);
      await tester.scrollUntilVisible(find.text(primeiraEtapa), 180);
      expect(find.text(primeiraEtapa).hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Fechar ajuda'));
      await tester.pumpAndSettle();
      expect(find.text('Arco floral para altar'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
