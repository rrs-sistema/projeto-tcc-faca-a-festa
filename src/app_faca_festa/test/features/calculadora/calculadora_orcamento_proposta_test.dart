import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/data/models/orcamento/orcamento_model.dart';

void main() {
  test('proposta da calculadora não substitui valor contratado', () {
    final item = OrcamentoModel.fromMap({
      'id_orcamento': 'bolo',
      'id_evento': 'festa',
      'anotacoes': 'Bolo',
      'custo_estimado': 150,
      'custo_sugerido_calculadora': 240,
      'quantidade_sugerida_calculadora': 3,
      'status': 'fechado',
    });
    expect(item.custoEstimado, 150);
    expect(item.custoSugeridoCalculadora, 240);
    expect(item.isFechado, isTrue);
    final atualizado =
        OrcamentoModel.fromEntity(item.copyWith(anotacoes: 'Bolo contratado'));
    expect(atualizado.toMap()['custo_sugerido_calculadora'], 240);
    expect(atualizado.toMap()['quantidade_sugerida_calculadora'], 3);
    expect(atualizado.custoEstimado, 150);
  });
}
