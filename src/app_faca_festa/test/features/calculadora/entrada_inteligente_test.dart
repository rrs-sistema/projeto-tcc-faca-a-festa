import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:app_faca_festa/domain/repositories/entrada_assistente_calculadora_repository.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/controllers/calculadora_festa_controller.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_entrada_inteligente_dialog.dart';
import 'calculadora_composicao_test.dart' show AiQA, regraQA;
import 'calculadora_criacao_jornada_test.dart' show AuthOwner;
import 'calculadora_jornada_test.dart' show RepoJornada, BaseJornada;

class EntradaRepo extends RepoJornada
    implements EntradaAssistenteCalculadoraRepository {
  Map<String, dynamic>? pedido, revisao;
  bool falhar = false;
  Map<String, dynamic>? resultado;
  Completer<Map<String, dynamic>>? espera;
  Map<String, dynamic> resposta = {
    'id': 'p',
    'assinatura': 'backend',
    'resumo': 'Confira duas ações',
    'acoes': [
      {
        'id': 'c',
        'descricao': 'Compra já realizada: 5 kg',
        'evidencia': 'comprei 5 kg'
      },
      {
        'id': 'p',
        'descricao': 'Preço por kg: R\$ 6,00',
        'evidencia': '6 reais por kg'
      },
    ],
    'perguntas': ['Qual é o rendimento da receita?'],
    'aviso_duplicidade': null
  };
  @override
  Future<Map<String, dynamic>> interpretarEntradaCalculadora(
      Map<String, dynamic> entrada) async {
    pedido = entrada;
    return espera?.future ?? resposta;
  }

  @override
  Future<Map<String, dynamic>> aplicarEntradaCalculadora(
      Map<String, dynamic> entrada) async {
    revisao = entrada;
    if (falhar) throw StateError('Sem conexão. Tente novamente.');
    return resultado ??
        {
          'aplicado': true,
          'operacao': {'revisao': 1},
          'regras_alteradas': []
        };
  }
}

void main() {
  late EntradaRepo repo;
  late CalculadoraFestaController c;
  setUp(() {
    Get.testMode = true;
    Get.put<FirebaseAuth>(AuthOwner());
    repo = EntradaRepo();
    c = CalculadoraFestaController(
        repository: repo,
        itensBaseRepository: BaseJornada(),
        aiService: AiQA());
    c.idEventoAtual.value = 'festa';
  });
  tearDown(() {
    c.onClose();
    Get.reset();
  });

  Future<void> abrir(WidgetTester tester,
      {Future<XFile?> Function()? arquivo}) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => CalculadoraEntradaInteligenteDialog(
                            controller: c, selecionarArquivo: arquivo)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> ler(WidgetTester tester) async {
    await tester.tap(find.text('Preparar leitura'));
    await tester.pumpAndSettle();
  }

  testWidgets('revisa conjunto, desmarca preço e aplica somente compra',
      (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextField), 'Comprei 5 kg de arroz');
    await ler(tester);
    final preco =
        find.widgetWithText(CheckboxListTile, 'Preço por kg: R\$ 6,00');
    await tester.ensureVisible(preco);
    await tester.tap(preco);
    await tester.pump();
    await tester.tap(find.text('Aplicar 1 ação(ões)'));
    await tester.pumpAndSettle();
    expect(repo.pedido!['evento'], 'festa');
    expect(repo.revisao!['selecionadas'], ['c']);
    expect(find.byType(CalculadoraEntradaInteligenteDialog), findsNothing);
  });
  testWidgets('erro de gravação mantém revisão e permite tentar novamente',
      (tester) async {
    repo.falhar = true;
    await abrir(tester);
    await ler(tester);
    await tester.tap(find.text('Aplicar 2 ação(ões)'));
    await tester.pumpAndSettle();
    expect(find.text('Aplicar 2 ação(ões)'), findsOneWidget);
    expect(find.textContaining('Sem conexão'), findsOneWidget);
    repo.falhar = false;
    await tester.tap(find.text('Aplicar 2 ação(ões)'));
    await tester.pumpAndSettle();
    expect(find.byType(CalculadoraEntradaInteligenteDialog), findsNothing);
  });
  testWidgets(
      'documento sem identidade pede conferência, editar invalida revisão',
      (tester) async {
    repo.resposta['aviso_duplicidade'] = 'Confira duplicidade';
    await abrir(tester);
    await ler(tester);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Aplicar 2 ação(ões)'))
            .onPressed,
        isNull);
    final conferir =
        find.widgetWithText(CheckboxListTile, 'Confira duplicidade');
    await tester.ensureVisible(conferir);
    await tester.tap(conferir);
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Aplicar 2 ação(ões)'))
            .onPressed,
        isNotNull);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Corrigir pedido');
    await tester.pump();
    expect(find.text('Aplicar 0 ação(ões)'), findsOneWidget);
    expect(repo.revisao, isNull);
  });
  testWidgets('TXT é lido como documento e não transmite antes do comando',
      (tester) async {
    await abrir(tester,
        arquivo: () async => XFile.fromData(
            Uint8List.fromList(utf8.encode('Cotação de teste')),
            path: 'cotacao.txt',
            name: 'cotacao.txt'));
    await tester.tap(find.text('Anexar documento ou foto'));
    await tester.pumpAndSettle();
    expect(repo.pedido, isNull);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Cotação de teste');
    await ler(tester);
    expect(repo.pedido!['documento'], true);
    expect(repo.pedido!['anexo'], isEmpty);
  });
  testWidgets('tela estreita com teclado e fonte ampliada não transborda',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await abrir(tester);
    await ler(tester);
    expect(tester.takeException(), isNull);
  });
  test('contexto alterado ou histórico bloqueia aplicação antes de gravar',
      () async {
    final assinatura = c.assinaturaProposta;
    c.duracaoHoras.value = 7;
    await expectLater(
        c.aplicarEntradaAssistente(repo.resposta, ['c'], assinatura),
        throwsStateError);
    c.usandoContextoHistorico.value = true;
    await expectLater(
        c.interpretarEntradaAssistente('teste'), throwsStateError);
    expect(repo.revisao, isNull);
  });
  test('referência genérica é vinculada à refeição e item antes da leitura',
      () async {
    c.itensEstimativa.add(regraQA('Arroz', premissas: {'estado': 'cru'}));
    c.itensCardapio.add(const CardapioItem(
        idItem: 'arroz',
        idEvento: 'festa',
        idCardapio: 'almoco',
        nome: 'Arroz',
        unidade: 'kg'));
    await c.interpretarEntradaAssistente(
        'Preço do arroz do almoço: 6 reais por kg');
    final regra = (repo.pedido!['regras'] as List).single;
    expect(regra['id'], 'menu_almoco_arroz');
    expect(regra['premissas']['id_cardapio'], 'almoco');
  });
  test('aplicação atualiza preço e limite sem perder edição local concorrente',
      () async {
    final r = regraQA('Arroz', premissas: {'id_evento': 'festa'});
    c.regrasManuais.add(r);
    repo.resultado = {
      'aplicado': true,
      'limite_atual': 8500,
      'operacao': {
        'revisao': 1,
        'execucao': {
          'regras': [r.copyWith(valorUnitarioMedio: 6).toPlanejamento()]
        }
      },
      'regras_alteradas': [r.id]
    };
    await c.aplicarEntradaAssistente(
        repo.resposta, ['p'], c.assinaturaProposta);
    expect(c.orcamentoDisponivel.value, 8500);
    expect(c.regrasManuais.single.valorUnitarioMedio, 6);
    final pendente =
        c.aplicarEntradaAssistente(repo.resposta, ['p'], c.assinaturaProposta);
    c.orcamentoDisponivel.value = 9000;
    c.regrasManuais.assignAll([r.copyWith(valorUnitarioMedio: 9)]);
    await pendente;
    expect(c.regrasManuais.single.valorUnitarioMedio, 9);
    expect(c.orcamentoDisponivel.value, 9000);
  });
  test(
      'configuração recebida restaura público e não desfaz ajuste local em outra ação',
      () {
    final cfg = {
      'base': 'manual',
      'publico': {'adultos': 29, 'criancas': 8, 'bebes': 0},
      'duracao': 6,
      'revisao': 1
    };
    c.restaurarConfiguracaoEntrada({'configuracao_planejamento': cfg});
    expect(c.totalAdultos.value, 29);
    expect(c.totalCriancas.value, 8);
    expect(c.duracaoHoras.value, 6);
    c.duracaoHoras.value = 8;
    c.restaurarConfiguracaoEntrada({'configuracao_planejamento': cfg});
    expect(c.duracaoHoras.value, 8);
    c.restaurarConfiguracaoEntrada({
      'configuracao_planejamento': {
        ...cfg,
        'perfil': 'premium',
        'revisao': 2,
        'campos_alterados': ['perfil']
      }
    });
    expect(c.duracaoHoras.value, 8);
  });
}
