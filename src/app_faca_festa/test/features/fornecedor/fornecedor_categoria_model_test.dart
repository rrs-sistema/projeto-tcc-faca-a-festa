import 'package:app_faca_festa/data/models/servico_produto/fornecedor_categoria_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads supplier category subcategories from legacy map keys', () {
    final model = FornecedorCategoriaModel.fromMap({
      'id_fornecedor': 'fornecedor-1',
      'id_categoria': 'buffet',
      'nome_categoria': 'Buffet',
      'subcategorias': [
        {
          'idSubcategoria': 'salgados',
          'nomeSubcategoria': 'Salgados',
        },
        {
          'id_subcategoria': 'doces',
          'nome': 'Doces',
        },
      ],
    });

    expect(model.subcategorias.map((s) => s.idSubcategoria), [
      'salgados',
      'doces',
    ]);
    expect(model.subcategorias.map((s) => s.nomeSubcategoria), [
      'Salgados',
      'Doces',
    ]);

    final parsed = FornecedorCategoriaModel.fromMap(model.toMap());
    expect(
      parsed.subcategorias
          .singleWhere((s) => s.idSubcategoria == 'salgados')
          .nomeSubcategoria,
      'Salgados',
    );
  });
}
