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
        'ator_auth_type': 'unknown',
        'visivel_fornecedor': true,
        'origem': 'firestore_trigger',
        'operacao': 'updated',
        'document_path': 'fornecedor_servico/serv-1',
        'source_event_id': 'firebase-event-1',
        'algoritmo_hash': 'sha256',
        'hash_integridade': 'abc123',
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
    expect(model.atorAuthType, 'unknown');
    expect(model.origem, 'firestore_trigger');
    expect(model.operacao, 'updated');
    expect(model.documentPath, 'fornecedor_servico/serv-1');
    expect(model.sourceEventId, 'firebase-event-1');
    expect(model.algoritmoHash, 'sha256');
    expect(model.hashIntegridade, 'abc123');
  });

  test('parses snapshot detail with raw document data', () {
    final model = AuditoriaEventoModel.fromMap(
      {
        'acao': 'ORCAMENTO_REGISTRADO',
        'area': 'ORCAMENTO',
        'nivel': 'INFO',
        'resumo': 'Orçamento registrado no sistema.',
        'origem': 'snapshot',
        'document_path': 'orcamento/1788344088644',
        'detalhe': {
          'tipo': 'snapshot',
          'document_path': 'orcamento/1788344088644',
          'dados': {
            'anotacoes': 'Passagens aéreas',
            'custo_estimado': 1650,
            'status': 'pendente',
          },
        },
      },
      id: 'orcamento_1788344088644',
    );

    expect(model.origem, 'snapshot');
    expect(model.documentPath, 'orcamento/1788344088644');
    expect(model.detalhe?['dados'], isA<Map>());
    expect(
      (model.detalhe?['dados'] as Map)['anotacoes'],
      'Passagens aéreas',
    );
  });
}
