import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/data/models/fornecedor/territorio_model.dart';

void main() {
  test('reads territory with numeric coordinates and string radius', () {
    final model = TerritorioModel.fromMap({
      'id_fornecedor': 'fornecedor-1',
      'latitude': '-25.43',
      'longitude': -49.27,
      'raio_km': '12',
      'ativo': 'true',
      'tipo_cobertura': 'raio',
    }, documentId: 'territorio-1');

    expect(model.idTerritorio, 'territorio-1');
    expect(model.idFornecedor, 'fornecedor-1');
    expect(model.latitude, closeTo(-25.43, 0.001));
    expect(model.longitude, closeTo(-49.27, 0.001));
    expect(model.raioKm, 12);
    expect(model.ativo, isTrue);
    expect(model.tipoCobertura, 'raio');
  });

  test('reads mixed region points without throwing', () {
    final model = TerritorioModel.fromMap({
      'id_territorio': 'territorio-2',
      'id_fornecedor': 'fornecedor-2',
      'tipo_cobertura': 'regiao',
      'regioes': [
        '-25.4,-49.2',
        {'latitude': -25.5, 'longitude': -49.3},
        10,
      ],
    });

    expect(model.regioes, ['-25.4,-49.2', '-25.5,-49.3']);
  });
}
