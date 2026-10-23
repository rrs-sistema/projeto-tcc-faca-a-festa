import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_faca_festa/data/datasources/remote/cardapio_remote_datasource.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/services/criacao_cardapio_inicial_service.dart';
import 'package:app_faca_festa/domain/services/plano_evento_service.dart';
import 'package:app_faca_festa/domain/services/proposta_refeicao_service.dart';
import 'package:app_faca_festa/presentation/modules/calculadora/widgets/calculadora_criar_cardapio_dialog.dart';
import 'plano_evento_test.dart' show calculo;
import 'calculadora_proposta_refeicao_test.dart' show item;

DestinoPlanoEvento previa(
        [FormatoPlanoInicial formato = FormatoPlanoInicial.churrasco]) =>
    const PlanoEventoService()
        .gerar(
            calculo: calculo(),
            cardapios: [],
            itensPorCardapio: {},
            regras: [],
            formato: formato)
        .destinos
        .single;
CriacaoCardapioInicial criar() =>
    const CriacaoCardapioInicialService().preparar(
        destino: previa(),
        calculo: calculo(),
        usuario: 'owner',
        contexto: {},
        titulo: 'Almoço');

// Substitutos apenas da fronteira: executam a callback real da transação,
// publicando as escritas juntas somente se ela terminar sem erro.
class BancoTx extends Fake implements FirebaseFirestore {
  final dados = <String, Map<String, dynamic>>{
    'evento/evento': {'id_usuario': 'owner'}
  };
  bool falhar = false;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      ColecaoTx(this, path);
  @override
  Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler,
      {Duration timeout = const Duration(seconds: 30),
      int maxAttempts = 5}) async {
    final tx = TransacaoTx(this);
    final resultado = await transactionHandler(tx);
    if (falhar) throw StateError('Conexão interrompida antes do commit');
    dados.addAll(tx.escritas);
    return resultado;
  }
}

// ignore: subtype_of_sealed_class
class ColecaoTx extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  ColecaoTx(this.banco, this.caminho);
  final BancoTx banco;
  final String caminho;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      DocumentoTx(banco, '$caminho/$path');
}

// ignore: subtype_of_sealed_class
class DocumentoTx extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  DocumentoTx(this.banco, this.caminho);
  final BancoTx banco;
  final String caminho;
  @override
  String get path => caminho;
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) =>
      ColecaoTx(banco, '$caminho/$collectionPath');
}

// ignore: subtype_of_sealed_class
class SnapshotTx<T extends Object?> extends Fake
    implements DocumentSnapshot<T> {
  SnapshotTx(this.valor);
  final T? valor;
  @override
  bool get exists => valor != null;
  @override
  T? data() => valor;
}

class TransacaoTx extends Fake implements Transaction {
  TransacaoTx(this.banco);
  final BancoTx banco;
  final escritas = <String, Map<String, dynamic>>{};
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
          DocumentReference<T> reference) async =>
      SnapshotTx<T>(banco.dados[reference.path] as T?);
  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data,
      [SetOptions? options]) {
    escritas[documentReference.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }
}

void main() {
  test(
      'formatos geram proposta sem alterar cardápios existentes ou criar dados',
      () {
    for (final formato in FormatoPlanoInicial.values
        .where((f) => f != FormatoPlanoInicial.automatico)) {
      final p = previa(formato);
      expect(p.resultados.length, p.itens.length);
      expect(p.resultados.every((r) => r.quantidade > 0), true);
      expect(p.sugerido, true);
    }
    expect(previa(FormatoPlanoInicial.coquetel).itens.map((i) => i.tipo),
        contains(TipoItemCardapio.bolo));
  });
  test('catálogo contextual não soma a porção inteira de cada variedade', () {
    final p = const PropostaRefeicaoService().gerar(
        itens: [item('Brigadeiro', id: 'b'), item('Beijinho', id: 'j')],
        regras: []);
    expect(p.regras.length, 2);
    expect(p.regras.map((r) => r.fatorComposicao), everyElement(.5));
    final inteiros = const PropostaRefeicaoService().gerar(
        itens: [item('Brigadeiro', id: 'b'), item('Beijinho', id: 'j')],
        regras: [],
        respostas: {'variedades_docinhos': 'inteiros'});
    expect(inteiros.regras.map((r) => r.fatorComposicao), everyElement(1));
  });
  test('salgados junto de lanche exigem contexto em vez de uma soma genérica',
      () {
    final p = const PropostaRefeicaoService().gerar(
        itens: [item('Cachorro-quente', id: 'd'), item('Salgadinhos', id: 's')],
        regras: []);
    expect(p.regras.any((r) => r.premissas['id_item_cardapio'] == 's'), false);
    expect(p.pendencias.join(), contains('porção'));
    final ajustado = const PropostaRefeicaoService().gerar(
        itens: [item('Cachorro-quente', id: 'd'), item('Salgadinhos', id: 's')],
        regras: [],
        respostas: {'porcao_salgados_s': '4'});
    expect(
        ajustado.regras
            .firstWhere((r) => r.premissas['id_item_cardapio'] == 's')
            .quantidadePorConvidadoEquivalente,
        4);
  });
  test('não divide variedades entre serviços ou públicos diferentes', () {
    final p = const PropostaRefeicaoService().gerar(
        itens: [item('Mini coxinha', id: 'a'), item('Mini quibe', id: 'b')],
        regras: [],
        respostas: {'salgados_a': 'festa', 'salgados_b': 'empresarial'});
    expect(p.regras.map((r) => r.fatorComposicao), everyElement(1));
    final distintos = const PropostaRefeicaoService().gerar(
        itens: [item('Brigadeiro', id: 'a'), item('Beijinho', id: 'b')],
        regras: [],
        publicosDosItens: {'a': 'grupo1', 'b': 'grupo2'});
    expect(distintos.regras.map((r) => r.fatorComposicao), everyElement(1));
  });
  test('alimento ambíguo não recebe referência por aproximação do nome', () {
    for (final nome in [
      'Feijoada',
      'Coxinha grande',
      'Arroz doce',
      'Torta desconhecida'
    ]) {
      final p = const PropostaRefeicaoService()
          .gerar(itens: [item(nome)], regras: []);
      expect(p.regras, isEmpty, reason: nome);
    }
  });
  test(
      'materialização remapeia identidades, preserva contexto e só cria sugestões',
      () {
    final contexto = <String, dynamic>{
      'original': {'valor': 2}
    };
    final antes = jsonEncode(contexto);
    final p = const CriacaoCardapioInicialService().preparar(
        destino: previa(),
        calculo: calculo(),
        usuario: 'owner',
        contexto: contexto,
        titulo: 'Almoço');
    expect(p.cardapio.idCardapio, 'plano_inicial_evento');
    expect(p.calculo.idUsuario, 'owner');
    expect(p.calculo.idCalculo, p.cardapio.idCardapio);
    expect(jsonEncode(contexto), antes);
    expect(
        p.itens.every((i) =>
            i.quantidadeFinal == 0 &&
            !i.confirmado &&
            i.disponibilidade == null &&
            i.quantidadeSugerida > 0),
        true);
    expect(
        p.resultados.every((r) =>
            r.idCardapio == p.cardapio.idCardapio &&
            r.adicionadoAoCardapio &&
            !r.adicionadoAoOrcamento),
        true);
    expect(p.resultados.map((r) => r.quantidade),
        previa().resultados.map((r) => r.quantidade));
    expect(
        p.regras
            .every((r) => r.premissas['id_cardapio'] == p.cardapio.idCardapio),
        true);
  });
  test(
      'público ausente, destino existente e usuário ausente não são materializados',
      () {
    for (final usuario in ['', 'owner']) {
      expect(
          () => const CriacaoCardapioInicialService().preparar(
              destino: previa(),
              calculo: calculo(pessoas: 0),
              usuario: usuario,
              contexto: {},
              titulo: 'Lanche'),
          throwsStateError);
    }
  });
  test(
      'transação real cria conjunto, preserva edição na repetição e não deixa gravação parcial',
      () async {
    final banco = BancoTx();
    final remote = CardapioRemoteDatasource(banco);
    final p = criar();
    banco.falhar = true;
    await expectLater(remote.criarCardapioInicial(p), throwsStateError);
    expect(banco.dados.keys, ['evento/evento']);
    banco.falhar = false;
    expect(await remote.criarCardapioInicial(p), true);
    expect(banco.dados.length, 3 + 2 * p.itens.length);
    banco.dados['cardapios/plano_inicial_evento']!['titulo'] =
        'Editado pelo organizador';
    final antes = jsonEncode(banco.dados, toEncodable: (v) => v.toString());
    expect(await remote.criarCardapioInicial(p), false);
    expect(jsonEncode(banco.dados, toEncodable: (v) => v.toString()), antes);
  });
  test('colisões e itens órfãos bloqueiam sem substituir dados', () async {
    for (final path in [
      'cardapios/plano_inicial_evento',
      'cardapios/plano_inicial_evento/itens/sugestao_carne',
      'calculadora_festa/plano_inicial_evento'
    ]) {
      final banco = BancoTx()..dados[path] = {'origem': 'anterior'};
      final antes = jsonEncode(banco.dados);
      await expectLater(
          CardapioRemoteDatasource(banco).criarCardapioInicial(criar()),
          throwsStateError);
      expect(jsonEncode(banco.dados), antes);
    }
  });
  testWidgets(
      'revisão mantém erro, bloqueia toque duplo e permite nova tentativa',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final pendente = Completer<void>();
    var chamadas = 0;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => CalculadoraCriarCardapioDialog(
                            destino: previa(),
                            onSalvar: (_) async {
                              chamadas++;
                              if (chamadas == 1) return pendente.future;
                            })),
                    child: const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar cardápio'));
    await tester.pump();
    expect(chamadas, 1);
    expect(
        (tester.widget<FilledButton>(
            find.byWidgetPredicate((w) => w is FilledButton))).onPressed,
        isNull);
    pendente.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('erro_criar_cardapio')), findsOneWidget);
    await tester.tap(find.text('Criar cardápio'));
    await tester.pumpAndSettle();
    expect(chamadas, 2);
    expect(find.byType(CalculadoraCriarCardapioDialog), findsNothing);
  });
}
