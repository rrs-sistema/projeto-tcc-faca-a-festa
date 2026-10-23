import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/services/medicao_uso_calculadora.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_composicao_test.dart' show AiQA, AuthQA;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;

class RepoMedicao extends RepoJornada {
  bool falhar = false;
  @override
  Future<void> salvarSimulacao(
      {required CalculadoraFesta calculo,
      required List<CalculadoraFestaItem> itens}) async {
    if (falhar) throw StateError('falha de gravação');
  }
}

void main() {
  testWidgets(
      'resultado registrado corresponde à gravação e à falha reais do repositório',
      (tester) async {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthQA());
    final repo = RepoMedicao();
    final c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    addTearDown(() {
      c.onClose();
      Get.reset();
    });
    await tester
        .pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    await c.prepararCalculadora(
        idEvento: 'qa',
        tipoEvento: 'Aniversário',
        base: BaseCalculoFesta.manual,
        adultosManuais: 20);
    c.calcular();
    expect(c.possuiResultado, isTrue);
    await c.salvarCalculo();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    repo.falhar = true;
    await c.salvarCalculo();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(c.medicaoUso.resumo['resultados'],
        {'salvar_simulacao_sucesso': 1, 'salvar_simulacao_falha': 1});
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test(
      'tempo ativo exclui segundo plano e limita ociosidade sem contar duas vezes',
      () {
    var agora = Duration.zero;
    final m = MedicaoUsoCalculadora(relogio: () => agora)
      ..iniciarSessao('teste');
    agora = const Duration(seconds: 10);
    m.atividade();
    agora = const Duration(seconds: 15);
    m.visibilidade(false);
    agora = const Duration(minutes: 5);
    expect(m.tempoAtivo.inSeconds, 15);
    m.visibilidade(true);
    agora += const Duration(minutes: 2);
    expect(m.tempoAtivo.inSeconds, 45);
    m.atividade();
    expect(m.tempoAtivo.inSeconds, 45);
    m.registrarCorrecao();
    m.registrarResultado('salvar', sucesso: false);
    m.registrarResultado('salvar', sucesso: true);
    expect(m.resumo['correcoes'], 1);
    expect(m.resumo['resultados'], {'salvar_falha': 1, 'salvar_sucesso': 1});
    m.iniciarSessao('outra');
    expect(m.tempoAtivo, Duration.zero);
    expect(m.resumo['resultados'], isEmpty);
  });
}
