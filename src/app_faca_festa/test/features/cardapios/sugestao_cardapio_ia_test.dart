import 'package:flutter_test/flutter_test.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/entities/sugestao_cardapio_ia.dart';

void main() {
  test('parseia sugestão válida e rejeita unidades inválidas', () {
    final sugestao = SugestaoCardapioIa.fromMap({
      'nome_cardapio': 'Almoço de aniversário',
      'resumo_publico': '30 adultos · Almoço',
      'justificativa': 'Sugestão equilibrada.',
      'premissas': ['Sem álcool por padrão'],
      'bebes_considerados': false,
      'aviso_bebes': null,
      'aviso_estimativa': 'As quantidades são estimativas.',
      'fonte': 'ia_generativa',
      'categorias': [
        {
          'nome': 'Bebidas',
          'itens': [
            {
              'nome': 'Água mineral',
              'tipo': 'bebida',
              'quantidade': 12,
              'unidade': 'l',
              'observacao': 'Estimativa para o público.',
              'publico_alvo': 'todos',
            },
            {
              'nome': 'Item inválido',
              'tipo': 'bebida',
              'quantidade': 2,
              'unidade': 'xícara',
              'observacao': null,
              'publico_alvo': 'todos',
            },
          ],
        },
      ],
    });

    expect(sugestao.nomeCardapio, 'Almoço de aniversário');
    expect(sugestao.categorias, hasLength(1));
    expect(sugestao.todosItens, hasLength(1));
    expect(sugestao.todosItens.first.tipo, TipoItemCardapio.bebida);
    expect(sugestao.todosItens.first.unidade, 'l');
  });

  test('payload da entrada não inclui dados pessoais', () {
    final entrada = EntradaGeracaoCardapioIa(
      idEvento: 'evt1',
      tipoFesta: 'Aniversário',
      totalPessoas: 40,
      momentoRefeicao: 'Almoço',
      adultos: 30,
      criancas: 10,
      observacoes: 'sem bebidas alcoólicas',
    );
    final payload = entrada.toPayload();
    expect(payload.containsKey('convidados'), isFalse);
    expect(payload['total_pessoas'], 40);
    expect(payload['observacoes'], 'sem bebidas alcoólicas');
  });
}
