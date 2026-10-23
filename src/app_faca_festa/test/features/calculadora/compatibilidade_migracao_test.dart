import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app_faca_festa/data/models/evento/evento_model.dart';
import 'package:app_faca_festa/data/models/evento/calculadora_festa_model.dart';
import 'package:app_faca_festa/data/models/cardapio/cardapio_model.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_contextual_repository.dart';
import 'package:app_faca_festa/domain/services/compatibilidade_planejamento_service.dart';
import 'package:app_faca_festa/domain/services/operacao_calculadora_service.dart';
import 'package:app_faca_festa/domain/services/publico_planejamento_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/pages/catalogo_contextual_admin_page.dart';

class SelecaoQA implements GovernancaCatalogoRepository {
  bool falhar = true;
  final confirmacoes = <int?>[];
  @override
  Future<void> aprovarReferencia(
      ReferenciaContextual r, int v, String p) async {}
  @override
  Future<void> selecionarVersao(
      String id, int esperada, int? alvo, String p) async {
    if (falhar) throw StateError('Offline');
    confirmacoes.add(alvo);
  }
}

void main() {
  const compat = CompatibilidadePlanejamentoService();
  test('ausência de previsão permanece diferente de zero em leitura e escrita',
      () {
    final vazio = EventoModel.fromMap({'id_evento': 'legado'});
    expect(vazio.totalConvidados, isNull);
    expect(vazio.previsaoPublicoInformada, false);
    expect(vazio.toMap()['total_convidados'], isNull);
    final zero =
        EventoModel.fromMap({'total_convidados': 0, 'total_adultos': 12});
    expect(zero.totalConvidados, 0);
    expect(PrevisaoPublico.doEvento(zero).idades, isNull);
  });
  test('evento sem término e total legado não inventa idades ou fim', () {
    final raw = {'id_evento': 'legado', 'total_convidados': 40};
    final e = EventoModel.fromMap(raw);
    expect(e.dataFim, isNull);
    expect(e.totalAdultos, isNull);
    expect(PrevisaoPublico.doEvento(e).total, 40);
    expect(PrevisaoPublico.doEvento(e).idades, isNull);
    expect(compat.evento(raw), hasLength(2));
    final relido = EventoModel.fromMap(e.toMap());
    expect(relido.totalAdultos, isNull);
    expect(relido.totalConvidados, 40);
  });
  test('cardápio legado continua sem escopo e sem ocorrência criada', () {
    final m =
        CardapioModel.fromMap({'id_cardapio': 'menu', 'id_evento': 'legado'});
    expect(m.escopo, EscopoCardapio.naoDefinido);
    expect(m.toMap().containsKey('ocorrencia'), false);
  });
  test('regra legada mantém origem ausente e operação futura falha fechada',
      () {
    final raw = {'id': 'regra', 'premissas': <String, dynamic>{}};
    final antes = jsonEncode(raw);
    expect(compat.regra(raw), hasLength(2));
    expect(jsonEncode(raw), antes);
    expect(
        () =>
            const OperacaoCalculadoraService().validarDocumento({'versao': 2}),
        throwsArgumentError);
    expect(() => const OperacaoCalculadoraService().aplicar({'versao': 2}, {}),
        throwsStateError);
    const OperacaoCalculadoraService().validarDocumento({});
  });
  test('motor anterior preserva custo/status/snapshot e identifica hipótese',
      () {
    final raw = <String, dynamic>{
      'id_calculo': 'hist',
      'total_convidados': 40,
      'custo_total_estimado': 120,
      'status_simulacao': 'aprovada',
      'contexto_planejamento': {'versao_motor': 3, 'receita': 'Fixture privada'}
    };
    final antes = jsonEncode(raw);
    final h = CalculadoraFestaModel.fromMap(raw);
    expect(h.distribuicaoEtariaHipotetica, true);
    expect(h.custoTotalEstimado, 120);
    expect(h.aprovada, true);
    expect(compat.historico(h.contextoPlanejamento), isNotEmpty);
    expect(jsonEncode(raw), antes);
    expect(h.copyWith().distribuicaoEtariaHipotetica, true);
    expect(
        CalculadoraFestaModel.fromMap(h.toMap()).distribuicaoEtariaHipotetica,
        true);
    expect(compat.historico({'versao_motor': 7}), isNotEmpty);
    expect(compat.historico({'versao_motor': 6}), isEmpty);
  });
  testWidgets(
      'seleção editorial valida, mantém falha e só confirma após resposta',
      (tester) async {
    final repo = SelecaoQA();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => CatalogoSelecaoDialog(
                            repository: repo, id: 'ref', ultima: 2)),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar seleção'));
    await tester.pumpAndSettle();
    expect(repo.confirmacoes, isEmpty);
    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('Confirmar seleção'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Seleção não confirmada'), findsOneWidget);
    expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text, '1');
    repo.falhar = false;
    await tester.tap(find.text('Confirmar seleção'));
    await tester.pumpAndSettle();
    expect(repo.confirmacoes, [1]);
    expect(find.text('Selecionar referência publicada'), findsNothing);
  });
}
