import 'package:firebase_auth/firebase_auth.dart';
import '../../services/stream_da_sessao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cotacao/cotacao_model.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';
import 'package:app_faca_festa/domain/entities/cotacao_chat.dart';
import 'package:app_faca_festa/domain/repositories/solicitacoes_repository.dart';
import 'cotacao_functions_datasource.dart';

class SolicitacoesRemoteDatasource {
  SolicitacoesRemoteDatasource({
    required FirebaseFirestore firestore,
    required CotacaoFunctionsDatasource functions,
  })  : _db = firestore,
        _functions = functions;

  final FirebaseFirestore _db;
  final CotacaoFunctionsDatasource _functions;

  Stream<List<CotacaoModel>> observarSolicitacoesFornecedor(
    String idFornecedor,
  ) {
    final fonte = _db
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .asyncMap<List<CotacaoModel>>((snapshot) async {
      final resultado = <CotacaoModel>[];

      for (final fornecedorDoc in snapshot.docs) {
        final cotacaoRef = fornecedorDoc.reference.parent.parent;
        if (cotacaoRef == null || cotacaoRef.parent.id != 'cotacao') continue;

        final cotacaoDoc = await cotacaoRef.get();
        if (!cotacaoDoc.exists) continue;

        final cotacao = CotacaoModel.fromMap(cotacaoDoc.data()!, cotacaoDoc.id);
        final fornData = fornecedorDoc.data();
        final pai = cotacaoDoc.data()!;
        final idOrc = fornData['id_orcamento']?.toString() ??
            (pai['id_fornecedor_contratado'] == idFornecedor
                ? pai['id_orcamento_contratado']?.toString()
                : null);
        String? execucao = fornData['estado_execucao']?.toString();
        if (idOrc != null) {
          final o = await _db.collection('orcamento').doc(idOrc).get();
          final d = o.data();
          if (d != null && d['id_fornecedor'] == idFornecedor) {
            execucao = (d['contrato_financeiro'] is Map
                        ? d['contrato_financeiro']['estado_execucao']
                        : null)
                    ?.toString() ??
                d['estado_execucao']?.toString();
          }
        }

        // Status do fornecedor (não o do pai): assim respondidas/fechadas aparecem.
        final statusFornecedor =
            StatusCotacao.fromString(fornData['status']?.toString());
        final valorCotado = (fornData['valor_cotado'] as num?)?.toDouble();

        final servicosSnap =
            await fornecedorDoc.reference.collection('servicos').get();
        final servicos = servicosSnap.docs.map((doc) {
          final data = doc.data();
          return CotacaoServicoResumo(
            nome: (data['nome_produto_servico'] ?? '').toString(),
            quantidade: data['quantidade'] ?? 0,
            valorEstimado: (data['valor_estimado'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        resultado.add(
          CotacaoModel(
            estadoComercial: fornData['estado_comercial']?.toString(),
            estadoExecucao: execucao,
            idOrcamento: idOrc,
            id: cotacao.id,
            idEvento: cotacao.idEvento,
            idUsuarioSolicitante: cotacao.idUsuarioSolicitante,
            nomeUsuarioSolicitante: cotacao.nomeUsuarioSolicitante,
            dataCadastro: cotacao.dataCadastro,
            status: statusFornecedor,
            valorEstimadoTotal: (valorCotado != null && valorCotado > 0)
                ? valorCotado
                : servicos.fold<double>(
                    0, (s, v) => s + v.valorEstimado * v.quantidade),
            descricao: cotacao.descricao,
            categoriaNome: cotacao.categoriaNome,
            fornecedores: const [],
            servicos: servicos,
          ),
        );
      }

      resultado.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
      return resultado;
    });
    return streamDaSessao(
        fonte: fonte,
        sessoes: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
        identidade: FirebaseAuth.instance.currentUser?.uid,
        vazio: <CotacaoModel>[]);
  }

  Future<void> cancelarCotacao({
    required String idCotacao,
    required String canceladoPor,
  }) async {
    try {
      await _functions.cancelarCotacao(idCotacao: idCotacao);
    } on CotacaoFunctionsException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('not-found')) {
        throw const SolicitacaoNaoEncontradaException();
      }
      if (code.contains('failed-precondition')) {
        throw SolicitacaoNaoCancelavelException(e.message);
      }
      rethrow;
    }
  }
}
