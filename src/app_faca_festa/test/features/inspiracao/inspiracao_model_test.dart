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

  test('reads admin visibility and event type lists from catalog maps', () {
    final model = InspiracaoModel.fromMap({
      'id': 'insp-2',
      'titulo': 'Chá revelação',
      'descricao': 'Paleta rosa e azul',
      'imagemUrl': 'https://exemplo.test/cha.jpg',
      'publicado': false,
      'deletado': true,
      'ordem': 7,
      'tipoEventoIds': ['cha_revelacao'],
      'tipoEventoSlugs': ['cha-revelacao'],
      'tipoEventoNomes': ['Chá revelação'],
      'tipoEventoSlug': 'cha_revelacao',
      'tipoEventoNome': 'Cha revelacao',
    });

    expect(model.publicado, isFalse);
    expect(model.deletado, isTrue);
    expect(model.ordem, 7);
    expect(model.tipoEventoIds, ['cha_revelacao']);
    expect(model.tipoEventoSlugs, ['cha-revelacao', 'cha_revelacao']);
    expect(model.tipoEventoNomes, ['Chá revelação', 'Cha revelacao']);
  });

  test('treats missing publicado as visible in the public catalog', () {
    final model = InspiracaoModel.fromMap({
      'id': 'insp-3',
      'titulo': 'Festa junina',
      'descricao': 'Bandeirinhas',
      'imagemUrl': 'https://exemplo.test/junina.jpg',
    });

    expect(model.publicado, isTrue);
    expect(model.deletado, isFalse);
    expect(model.ordem, 0);
  });
}
