import 'package:app_faca_festa/data/models/fornecedor/fornecedor_model.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads supplier categories from mixed legacy map keys', () {
    final model = FornecedorModel.fromMap({
      'id_fornecedor': 'fornecedor-1',
      'id_usuario': 'usuario-1',
      'razao_social': 'Doces Ana',
      'telefone': '44999999999',
      'email': 'ana@email.com',
      'data_cadastro': '2026-01-01T00:00:00.000',
      'categorias': [
        {
          'id_categoria': 'buffet',
          'nome': 'Buffet',
          'descricao': 'Comida e bebida',
          'subcategoria': 'Salgados',
        },
        {
          'idCategoria': 'decoracao',
          'nomeCategoria': 'Decoração',
          'subcategorias': [
            {
              'idSubcategoria': 'flores',
              'nomeSubcategoria': 'Flores',
            },
          ],
        },
      ],
    });

    expect(model.categorias, hasLength(2));
    expect(model.categorias.first.idCategoria, 'buffet');
    expect(model.categorias.first.nomeCategoria, 'Buffet');
    expect(
      model.categorias.first.subcategorias.map((s) => s.nomeSubcategoria),
      ['Salgados'],
    );
    expect(model.categorias.last.idCategoria, 'decoracao');
    expect(model.categorias.last.nomeCategoria, 'Decoração');
    expect(model.categorias.last.subcategorias.first.idSubcategoria, 'flores');
    expect(
      model.categorias.first.termosBusca.toList(),
      ['Buffet', 'Comida e bebida', 'Salgados'],
    );
  });

  test('serializes typed categories without keeping raw maps', () {
    final original = FornecedorModel(
      idFornecedor: 'fornecedor-1',
      idUsuario: 'usuario-1',
      razaoSocial: 'Doces Ana',
      telefone: '44999999999',
      email: 'ana@email.com',
      dataCadastro: DateTime(2026),
      categorias: const [
        FornecedorCategoriaResumo(
          idCategoria: 'buffet',
          nomeCategoria: 'Buffet',
        ),
      ],
    );

    final parsed = FornecedorModel.fromMap(original.toMap());

    expect(parsed.categorias.single.idCategoria, 'buffet');
    expect(parsed.categorias.single.nomeCategoria, 'Buffet');
  });
}
