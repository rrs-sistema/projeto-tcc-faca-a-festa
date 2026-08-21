import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cotacao/cotacao_model.dart';

class SolicitacoesRemoteDatasource {
  SolicitacoesRemoteDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<CotacaoModel>> observarSolicitacoesFornecedor(
    String idFornecedor,
  ) {
    return _db
        .collection('cotacao')
        .snapshots()
        .asyncMap<List<CotacaoModel>>((snapshot) async {
      final resultado = <CotacaoModel>[];

      for (final cotacaoDoc in snapshot.docs) {
        final cotacao = CotacaoModel.fromMap(cotacaoDoc.data(), cotacaoDoc.id);

        final fornecedoresSnap = await cotacaoDoc.reference
            .collection('fornecedores')
            .where('id_fornecedor', isEqualTo: idFornecedor)
            .get();

        if (fornecedoresSnap.docs.isEmpty) continue;

        final servicosSnap =
            await cotacaoDoc.reference.collection('servicos').get();
        final servicos = servicosSnap.docs.map((doc) {
          final data = doc.data();
          return {
            'nome': data['nome_produto_servico'] ?? '',
            'quantidade': data['quantidade'] ?? 0,
            'valor_estimado':
                (data['valor_estimado'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();

        resultado.add(
          CotacaoModel(
            id: cotacao.id,
            idEvento: cotacao.idEvento,
            idUsuarioSolicitante: cotacao.idUsuarioSolicitante,
            nomeUsuarioSolicitante: cotacao.nomeUsuarioSolicitante,
            dataCadastro: cotacao.dataCadastro,
            status: cotacao.status,
            valorEstimadoTotal: cotacao.valorEstimadoTotal,
            descricao: cotacao.descricao,
            categoriaNome: cotacao.categoriaNome,
            fornecedores: const [],
            servicos: servicos,
          ),
        );
      }

      resultado.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
      return resultado.take(5).toList();
    });
  }

  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  }) async {
    final cotacaoRef = _db.collection('cotacao').doc(idCotacao);
    final cotacaoDoc = await cotacaoRef.get();

    if (!cotacaoDoc.exists) {
      throw const SolicitacaoNaoEncontradaException();
    }

    final data = cotacaoDoc.data()!;
    final statusAtual = data['status'] ?? 'pendente';

    if (statusAtual != 'pendente' && statusAtual != 'aguardando') {
      throw SolicitacaoNaoCancelavelException(statusAtual.toString());
    }

    final fornecedoresSnap = await cotacaoRef.collection('fornecedores').get();

    if (fornecedoresSnap.docs.isEmpty) {
      throw const SolicitacaoSemFornecedorException();
    }

    final batchFornecedores = _db.batch();

    for (final doc in fornecedoresSnap.docs) {
      batchFornecedores.update(doc.reference, {
        'status': 'cancelada',
        'data_cancelamento': FieldValue.serverTimestamp(),
      });
    }

    await batchFornecedores.commit();
    await Future.delayed(const Duration(milliseconds: 800));

    await cotacaoRef.update({
      'status': 'cancelada',
      'data_cancelamento': FieldValue.serverTimestamp(),
      'cancelado_por': canceladoPor,
    });
  }
}

class SolicitacaoNaoEncontradaException implements Exception {
  const SolicitacaoNaoEncontradaException();
}

class SolicitacaoNaoCancelavelException implements Exception {
  const SolicitacaoNaoCancelavelException(this.status);

  final String status;
}

class SolicitacaoSemFornecedorException implements Exception {
  const SolicitacaoSemFornecedorException();
}
