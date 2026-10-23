import '../test/features/calculadora/plano_evento_test.dart' show calculo;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/data/datasources/remote/orcamento_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/orcamento_gasto_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_festa_remote_datasource.dart';
import 'package:app_faca_festa/data/datasources/remote/calculadora_itens_base_remote_datasource.dart';
import 'package:app_faca_festa/data/repositories_impl/orcamento_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora_festa_repository_impl.dart';
import 'package:app_faca_festa/data/repositories_impl/calculadora/calculadora_itens_base_repository_impl.dart';
import 'package:app_faca_festa/data/models/evento/evento_model.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_orcamentos.dart';
import 'package:app_faca_festa/presentation/modules/orcamento/controllers/orcamento_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_capacidade_dialog.dart';
import '../test/features/calculadora/calculadora_composicao_test.dart'
    show AiQA;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'financeiro real e verba durável: parcial, limites, cancelar, confirmar e retomar',
      (tester) async {
    const evento = String.fromEnvironment('FINANCEIRO_QA_EVENTO');
    if (!const bool.fromEnvironment('CALCULADORA_QA') ||
        !RegExp(r'^financeiro-[0-9]+$').hasMatch(evento)) {
      throw StateError('Use o harness demo local.');
    }
    final app = await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            appId: '1:1234567890:android:1234567890abcdef',
            messagingSenderId: '1234567890',
            projectId: 'demo-financeiro08'));
    if (app.options.projectId != 'demo-financeiro08') {
      throw StateError('Projeto recusado.');
    }
    final auth = FirebaseAuth.instanceFor(app: app),
        db = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('127.0.0.1', 9099, automaticHostMapping: false);
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('127.0.0.1', 8080, automaticHostMapping: false);
    await auth.signInWithEmailAndPassword(
        email: 'financeiro-owner@example.test', password: 'TesteLocal123!');
    Get.testMode = true;
    Get.put<FirebaseAuth>(auth);
    Future<void> esperar(bool Function() pronto) async {
      for (var i = 0; i < 200; i++) {
        if (pronto()) return;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      throw StateError('Atualização financeira não recebida.');
    }

    final orcRepo = OrcamentoRepositoryImpl(
        OrcamentoRemoteDatasource(firestore: db, auth: auth));
    final resumo = OrcamentoController(
        orcamentos: GerenciarOrcamentos(orcRepo),
        usuarioAtual: () => auth.currentUser?.uid);
    await resumo.carregarOrcamentosDoEvento(evento);
    await esperar(() => resumo.resumoFinanceiro.value.completo);
    expect(resumo.totalCustoEstimado.value, 6500);
    expect(resumo.totalPagoGeral.value, 500);
    expect(resumo.totalContratado, 6500);
    final gastos = OrcamentoGastoRemoteDatasource(firestore: db),
        id = '$evento-buffet',
        despesa = db.doc('orcamento/$id/orcamento_gasto/parcial');
    await gastos.marcarComoPago(
        idOrcamento: id, idGasto: 'parcial', valorTotal: 750);
    await esperar(() => resumo.totalPagoGeral.value == 750);
    await gastos.marcarComoPago(
        idOrcamento: id, idGasto: 'parcial', valorTotal: 750);
    expect((await despesa.get()).data()!['pago'], 750);
    await expectLater(
        gastos.marcarComoPago(
            idOrcamento: id, idGasto: 'parcial', valorTotal: 6501),
        throwsArgumentError);
    await expectLater(
        despesa.update({'pago': 6501}), throwsA(isA<FirebaseException>()));
    await expectLater(despesa.update({'id_orcamento': 'outro'}),
        throwsA(isA<FirebaseException>()));
    final repo = CalculadoraFestaRepositoryImpl(
            CalculadoraFestaRemoteDatasource(firestore: db, auth: auth)),
        base = CalculadoraItensBaseRepositoryImpl(
            CalculadoraItensBaseRemoteDatasource(firestore: db, auth: auth));
    Future<CalculadoraFestaController> abrir() async {
      final c = CalculadoraFestaController(
          repository: repo, itensBaseRepository: base, aiService: AiQA());
      await c.prepararCalculadora(
          idEvento: evento,
          tipoEvento: 'Corporativo',
          adultosEvento: 20,
          totalConvidadosEvento: 20);
      c.sincronizarEvento(
          EventoModel.fromMap((await db.doc('evento/$evento').get()).data()!));
      return c;
    }

    final c = await abrir();
    expect(c.verbaAlimentacao.value, 200);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (ctx) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: ctx,
                        builder: (_) => CalculadoraCapacidadeDialog(
                            controller: c,
                            calculo: c.calculoAtual.value ??
                                calculo().copyWith(idEvento: evento),
                            cardapios: const [],
                            itens: const {},
                            regras: const [],
                            consultaCompleta: true)),
                    child: const Text('Abrir verba'))))));
    final antes = (await db.doc('calculadora_operacao/$evento').get()).data();
    await tester.tap(find.text('Abrir verba'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1450,00');
    await tester.tap(find.text('Simular capacidade'));
    await tester.pumpAndSettle();
    expect(c.verbaAlimentacao.value, 200);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    expect((await db.doc('calculadora_operacao/$evento').get()).data(), antes);
    await tester.tap(find.text('Abrir verba'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1450,00');
    await tester.tap(find.text('Usar esta verba'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraCapacidadeDialog), findsNothing);
    expect(c.verbaAlimentacao.value, 1450);
    final salvo = (await db.doc('calculadora_operacao/$evento').get()).data()!,
        cfg = salvo['configuracao_planejamento'];
    expect(cfg['verba_confirmacao']['fonte'], 'organizador');
    expect(cfg['verba_confirmacao']['confirmado_por'], 'financeiro-owner');
    expect(cfg['verba_confirmacao']['valor'], 1450);
    c.onClose();
    final novo = await abrir();
    expect(novo.verbaAlimentacao.value, 1450);
    final comando =
        novo.prepararConfirmacaoConfiguracao({'verba_alimentacao': 1500});
    await db.doc('evento/$evento').update({'custo_estimado': 1000});
    await expectLater(novo.confirmarConfiguracao(comando), throwsStateError);
    novo.sincronizarEvento(
        EventoModel.fromMap((await db.doc('evento/$evento').get()).data()!));
    expect(novo.orcamentoDisponivel.value, 1000);
    expect(novo.verbaAlimentacao.value, 1450);
    expect((await despesa.get()).data()!['pago'], 750);
    expect(novo.resumoCompras.limite, 1000);
    novo.onClose();
    await resumo.encerrarEscutas();
    await auth.signOut();
    await auth.signInWithEmailAndPassword(
        email: 'financeiro-other@example.test', password: 'TesteLocal123!');
    await expectLater(
        despesa.update({'pago': 800}), throwsA(isA<FirebaseException>()));
    await expectLater(db.doc('calculadora_operacao/$evento').get(),
        throwsA(isA<FirebaseException>()));
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
    await auth.signOut();
  });
}
