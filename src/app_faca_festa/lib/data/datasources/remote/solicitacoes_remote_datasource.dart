import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cotacao/cotacao_model.dart';
import '../../../domain/repositories/solicitacoes_repository.dart';

class SolicitacoesRemoteDatasource {
  SolicitacoesRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<CotacaoModel>> observarSolicitacoesFornecedor(
    String idFornecedor,
  ) {
    return _db
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .asyncMap<List<CotacaoModel>>((snapshot) async {
      final resultado = <CotacaoModel>[];

      for (final fornecedorDoc in snapshot.docs) {
        final cotacaoRef = fornecedorDoc.reference.parent.parent;
        if (cotacaoRef == null) continue;

        final cotacaoDoc = await cotacaoRef.get();
        if (!cotacaoDoc.exists) continue;

        final cotacao = CotacaoModel.fromMap(cotacaoDoc.data()!, cotacaoDoc.id);

        final servicosSnap =
            await fornecedorDoc.reference.collection('servicos').get();
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
    final idSolicitante = (data['id_usuario_solicitante'] ?? '').toString();

    if (statusAtual != 'pendente' &&
        statusAtual != 'aguardando' &&
        statusAtual != 'parcial' &&
        statusAtual != 'respondida') {
      throw SolicitacaoNaoCancelavelException(statusAtual.toString());
    }

    // Organizador cancela a cotação inteira; fornecedor só a própria participação.
    final ehSolicitante = idSolicitante == canceladoPor;
    final fornecedoresSnap = await cotacaoRef.collection('fornecedores').get();

    if (fornecedoresSnap.docs.isEmpty) {
      throw const SolicitacaoSemFornecedorException();
    }

    final batch = _db.batch();

    if (ehSolicitante) {
      for (final doc in fornecedoresSnap.docs) {
        batch.update(doc.reference, {
          'status': 'cancelada',
          'data_cancelamento': FieldValue.serverTimestamp(),
        });
      }
      batch.update(cotacaoRef, {
        'status': 'cancelada',
        'data_cancelamento': FieldValue.serverTimestamp(),
        'cancelado_por': canceladoPor,
      });
    } else {
      QueryDocumentSnapshot<Map<String, dynamic>>? meuDoc;
      for (final doc in fornecedoresSnap.docs) {
        final id = (doc.data()['id_fornecedor'] ?? doc.id).toString();
        if (id == canceladoPor) {
          meuDoc = doc;
          break;
        }
      }
      if (meuDoc == null) {
        throw const SolicitacaoNaoEncontradaException();
      }
      batch.update(meuDoc.reference, {
        'status': 'recusado',
        'respondido': true,
        'data_cancelamento': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
