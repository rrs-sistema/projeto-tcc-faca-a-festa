import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/services/medicao_uso_calculadora.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa.dart';
import 'package:app_faca_festa/domain/entities/calculadora_festa_item.dart';
import 'package:app_faca_festa/domain/entities/evento.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'calculadora_composicao_test.dart' show AiQA, AuthQA, regraQA;
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'catalogo_contextual_test.dart' show CatalogoLeituraQA;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;

class RepoMedicao extends RepoJornada {
  bool falhar = false;
  int gravacoesDeRegras = 0;
  CalculadoraFesta? simulacao;
  List<CalculadoraFestaItem> resultados = [];

  @override
  Future<Map<String, dynamic>> alterarOperacaoEvento(
      String id, Map<String, dynamic> acao) {
    if (acao['tipo'] == 'regras') gravacoesDeRegras++;
    return super.alterarOperacaoEvento(id, acao);
  }

  @override
  Future<void> salvarSimulacao(
      {required CalculadoraFesta calculo,
      required List<CalculadoraFestaItem> itens}) async {
    if (falhar) throw StateError('falha de gravação');
    simulacao = calculo;
    resultados = itens;
  }
}

void main() {
  testWidgets(
      'salva a simulação manual com catálogo indisponível após atualizar',
      (tester) async {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
    final repo = RepoMedicao();
    final catalogo = CatalogoLeituraQA()
      ..consultar = () async => throw StateError('catálogo offline');
    final c = CalculadoraFestaController(
        repository: repo, itensBaseRepository: catalogo, aiService: AiQA());
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
        adultosManuais: 26);
    c.sincronizarEvento(Evento(
        idEvento: 'qa',
        idUsuario: 'owner',
        idTipoEvento: 'aniversario',
        nomeEvento: 'Festa',
        localEvento: '',
        data: DateTime(2026)));
    expect(c.possuiResultado, isFalse);
    expect(c.podeTentarCarregarBase, isTrue);
    await c.salvarItemManual(regraQA('Bolo'), anterior: null);
    await c.carregarItensBasePorTipoEvento();
    expect(c.contextoEvento.estimarQuantidades, isTrue);
    expect(c.itensCalculados.single.nome, 'Bolo');
    await c.salvarCalculo();
    expect(repo.gravacoesDeRegras, 1);
    expect(repo.simulacao?.baseCalculo, BaseCalculoFesta.manual);
    expect(repo.simulacao?.totalConvidados, 26);
    expect(repo.resultados.single.nome, 'Bolo');
    await tester.pumpAndSettle();
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });

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
