import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_faca_festa/data/models/auditoria/auditoria_evento_model.dart';

void main() {
  test('parses an audit document with diffs and actor', () {
    final model = AuditoriaEventoModel.fromMap(
      {
        'acao': 'SERVICO_FORNECEDOR_SALVO',
        'area': 'SERVICO',
        'nivel': 'INFO',
        'resumo': 'Serviço publicado',
        'entidade_nome': 'Buffet premium',
        'id_fornecedor': 'forn-1',
        'ator_nome': 'Ana',
        'ator_email': 'ana@festa.com',
        'ator_tipo': 'F',
        'visivel_fornecedor': true,
        'mudancas': [
          {'campo': 'Preço', 'de': '100', 'para': '150'},
        ],
        'criado_em': Timestamp.fromDate(DateTime(2026, 8, 26, 8, 30)),
      },
      id: 'evt-1',
    );

    expect(model.id, 'evt-1');
    expect(model.acao, 'SERVICO_FORNECEDOR_SALVO');
    expect(model.entidadeNome, 'Buffet premium');
    expect(model.idFornecedor, 'forn-1');
    expect(model.visivelFornecedor, isTrue);
    expect(model.mudancas, hasLength(1));
    expect(model.mudancas.first.campo, 'Preço');
    expect(model.mudancas.first.para, '150');
    expect(model.atorNome, 'Ana');
  });
}
