import 'package:app_faca_festa/data/models/cardapio/cardapio_item_model.dart';
import 'package:app_faca_festa/data/models/cardapio/cardapio_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('menu map preserves the Firestore field contract', () {
    const model = CardapioModel(
      idCardapio: 'cardapio-1',
      idEvento: 'evento-1',
      titulo: 'Principal',
      publicoAlvo: PublicoAlvoCardapio.adultos,
      totalItens: 3,
    );

    expect(model.toMap(), containsPair('id_cardapio', 'cardapio-1'));
    expect(model.toMap(), containsPair('publico_alvo', 'adultos'));
    expect(model.toMap(), containsPair('total_itens', 3));
  });

  test('item map preserves enum and numeric persistence values', () {
    const model = CardapioItemModel(
      idItem: 'item-1',
      idEvento: 'evento-1',
      idCardapio: 'cardapio-1',
      nome: 'Suco',
      tipo: TipoItemCardapio.bebida,
      quantidadeFinal: 12.5,
    );

    expect(model.toMap(), containsPair('tipo', 'bebida'));
    expect(model.toMap(), containsPair('quantidade_final', 12.5));
    expect(model.toMap(), containsPair('confirmado', false));
  });
}
