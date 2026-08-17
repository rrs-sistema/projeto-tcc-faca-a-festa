import 'dart:async';

import 'package:app_faca_festa/controllers/convidado/cardapio_controller.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/repositories/cardapio_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _CardapioRepositoryFake repository;
  late CardapioController controller;

  setUp(() {
    repository = _CardapioRepositoryFake();
    controller = CardapioController(repository: repository);
  });

  tearDown(() async {
    controller.onClose();
    await repository.close();
  });

  test('observes menus and items while preserving current totals', () async {
    await controller.escutarCardapios('evento-1');
    repository.cardapios.add([_cardapio()]);
    await Future<void>.delayed(Duration.zero);
    repository.itens('cardapio-1').add([
      _item('Arroz', TipoItemCardapio.comida),
      _item('Bolo', TipoItemCardapio.bolo, id: 'item-2'),
      _item('Suco', TipoItemCardapio.bebida, id: 'item-3'),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(repository.eventoObservado, 'evento-1');
    expect(repository.cardapioItensObservado, 'cardapio-1');
    expect(controller.totalItensDoCardapio('cardapio-1'), 3);
    expect(controller.totalComidasDoCardapio('cardapio-1'), 2);
    expect(controller.totalBebidasDoCardapio('cardapio-1'), 1);
  });

  test('save operations delegate pure domain entities', () async {
    final cardapio = _cardapio();
    final item = _item('Arroz', TipoItemCardapio.comida);

    await controller.adicionarCardapio(cardapio);
    await controller.addItem('cardapio-1', item);
    await controller.toggleConfirmado('cardapio-1', item);

    expect(repository.cardapioSalvo, same(cardapio));
    expect(repository.itemSalvo?.nome, 'Arroz');
    expect(repository.itemAlternado, same(item));
  });

  test('repository stream errors preserve loading and error behavior',
      () async {
    await controller.escutarCardapios('evento-1');
    repository.cardapios.addError(StateError('falha'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.carregando.value, isFalse);
    expect(controller.erro.value, contains('falha'));
  });
}

Cardapio _cardapio() => const Cardapio(
      idCardapio: 'cardapio-1',
      idEvento: 'evento-1',
      titulo: 'Principal',
    );

CardapioItem _item(
  String nome,
  TipoItemCardapio tipo, {
  String id = 'item-1',
}) =>
    CardapioItem(
      idItem: id,
      idEvento: 'evento-1',
      idCardapio: 'cardapio-1',
      nome: nome,
      tipo: tipo,
    );

class _CardapioRepositoryFake implements CardapioRepository {
  final cardapios = StreamController<List<Cardapio>>.broadcast();
  final _itens = <String, StreamController<List<CardapioItem>>>{};

  String? eventoObservado;
  String? cardapioItensObservado;
  Cardapio? cardapioSalvo;
  CardapioItem? itemSalvo;
  CardapioItem? itemAlternado;

  StreamController<List<CardapioItem>> itens(String idCardapio) =>
      _itens.putIfAbsent(
        idCardapio,
        () => StreamController<List<CardapioItem>>.broadcast(),
      );

  Future<void> close() async {
    await cardapios.close();
    for (final controller in _itens.values) {
      await controller.close();
    }
  }

  @override
  Stream<List<Cardapio>> observarCardapios(String idEvento) {
    eventoObservado = idEvento;
    return cardapios.stream;
  }

  @override
  Stream<List<CardapioItem>> observarItens(
    String idCardapio, {
    String? idEvento,
  }) {
    cardapioItensObservado = idCardapio;
    return itens(idCardapio).stream;
  }

  @override
  Future<void> salvarCardapio(Cardapio cardapio) async {
    cardapioSalvo = cardapio;
  }

  @override
  Future<void> salvarItem(String idCardapio, CardapioItem item) async {
    itemSalvo = item;
  }

  @override
  Future<void> alternarConfirmado(
    String idCardapio,
    CardapioItem item,
  ) async {
    itemAlternado = item;
  }

  @override
  Future<void> atualizarResumo(
    String idCardapio,
    ResumoCardapio resumo,
  ) async {}

  @override
  Future<void> excluirCardapio(String idCardapio) async {}

  @override
  Future<void> excluirItem(String idCardapio, String idItem) async {}
}
