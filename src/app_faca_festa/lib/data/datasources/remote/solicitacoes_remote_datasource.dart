import 'dart:async';

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
      final documentos = snapshot.docs;

      // Limita o número de leituras simultâneas em listas grandes.
      const tamanhoLote = 10;
      for (var i = 0; i < documentos.length; i += tamanhoLote) {
        final lote = documentos.skip(i).take(tamanhoLote);
        final solicitacoes = await Future.wait(
          lote.map((doc) => _carregarSolicitacao(doc, idFornecedor)),
        );
        resultado.addAll(solicitacoes.whereType<CotacaoModel>());
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

  Future<CotacaoModel?> _carregarSolicitacao(
    QueryDocumentSnapshot<Map<String, dynamic>> fornecedorDoc,
    String idFornecedor,
  ) async {
    final cotacaoRef = fornecedorDoc.reference.parent.parent;
    if (cotacaoRef == null || cotacaoRef.parent.id != 'cotacao') return null;

    final cotacaoDoc = await cotacaoRef.get();
    if (!cotacaoDoc.exists) return null;

    final pai = cotacaoDoc.data()!;
    final cotacao = CotacaoModel.fromMap(pai, cotacaoDoc.id);
    final fornData = fornecedorDoc.data();
    final idOrc = fornData['id_orcamento']?.toString() ??
        (pai['id_fornecedor_contratado'] == idFornecedor
            ? pai['id_orcamento_contratado']?.toString()
            : null);
    String? execucao = fornData['estado_execucao']?.toString();
    final (orcamento, servicosSnap) = await (
      idOrc == null
          ? Future<DocumentSnapshot<Map<String, dynamic>>?>.value()
          : _db.collection('orcamento').doc(idOrc).get(),
      fornecedorDoc.reference.collection('servicos').get(),
    ).wait;
    final dadosOrcamento = orcamento?.data();
    if (dadosOrcamento != null &&
        dadosOrcamento['id_fornecedor'] == idFornecedor) {
      final contrato = dadosOrcamento['contrato_financeiro'];
      execucao =
          (contrato is Map ? contrato['estado_execucao'] : null)?.toString() ??
              dadosOrcamento['estado_execucao']?.toString();
    }

    // O status do fornecedor pode divergir do status geral da cotação.
    final statusFornecedor =
        StatusCotacao.fromString(fornData['status']?.toString());
    final valorCotado = (fornData['valor_cotado'] as num?)?.toDouble();
    final servicos = servicosSnap.docs.map((doc) {
      final data = doc.data();
      return CotacaoServicoResumo(
        nome: (data['nome_produto_servico'] ?? '').toString(),
        quantidade: data['quantidade'] ?? 0,
        valorEstimado: (data['valor_estimado'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return CotacaoModel(
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
    );
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
