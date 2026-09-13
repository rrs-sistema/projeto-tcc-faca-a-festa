import 'package:app_faca_festa/data/models/evento/inspiracao_model.dart';
import 'package:app_faca_festa/domain/entities/inspiracao_sugestao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads suggested tasks and budget items from legacy map keys', () {
    final model = InspiracaoModel.fromMap({
      'id': 'insp-1',
      'titulo': 'Casamento no jardim',
      'descricao': 'Clima ao ar livre',
      'imagemUrl': 'https://exemplo.test/foto.jpg',
      'tarefasSugeridas': [
        {
          'nome': 'Reservar buffet',
          'descricao': 'Confirmar cardápio',
          'categoria': 'Alimentação',
          'diasAntes': 45,
        },
      ],
      'itensOrcamentoSugeridos': [
        {
          'nome': 'Buffet completo',
          'categoria': 'Alimentação',
          'valorEstimado': '2500,50',
        },
      ],
    });

    expect(model.tarefasSugeridas.single.titulo, 'Reservar buffet');
    expect(model.tarefasSugeridas.single.diasAntesEvento, 45);
    expect(model.itensOrcamentoSugeridos.single.item, 'Buffet completo');
    expect(model.itensOrcamentoSugeridos.single.custoEstimado, 2500.50);
  });

  test('serializes typed inspiration suggestions with compatibility keys', () {
    final original = InspiracaoModel(
      id: 'insp-1',
      titulo: 'Casamento no jardim',
      descricao: 'Clima ao ar livre',
      imagemUrl: 'https://exemplo.test/foto.jpg',
      tarefasSugeridas: const [
        TarefaInspiracaoSugerida(
          titulo: 'Reservar buffet',
          categoria: 'Alimentação',
        ),
      ],
      itensOrcamentoSugeridos: const [
        ItemOrcamentoInspiracaoSugerido(
          item: 'Buffet completo',
          categoria: 'Alimentação',
          custoEstimado: 2500,
        ),
      ],
    );

    final firestore = original.toFirestore();
    final parsed = InspiracaoModel.fromMap({
      'id': original.id,
      'titulo': original.titulo,
      'descricao': original.descricao,
      'imagemUrl': original.imagemUrl,
      'tarefasSugeridas': firestore['tarefasSugeridas'],
      'itensOrcamentoSugeridos': firestore['itensOrcamentoSugeridos'],
    });

    expect(parsed.tarefasSugeridas.single.titulo, 'Reservar buffet');
    expect(parsed.itensOrcamentoSugeridos.single.item, 'Buffet completo');
    expect(parsed.itensOrcamentoSugeridos.single.custoEstimado, 2500);
  });
}
