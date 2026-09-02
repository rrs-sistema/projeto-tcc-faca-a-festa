import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cotacao/cotacao_chat_model.dart';
import '../../models/model.dart';
import 'cotacao_functions_datasource.dart';

abstract interface class CotacaoRemoteDatasource {
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario);

  Stream<bool> observarCotacaoTemResposta(String idCotacao);

  Stream<List<CotacaoConversaModel>> observarConversasFornecedor(
    String idFornecedor,
  );

  Stream<List<CotacaoMensagemModel>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  });

  Stream<List<CotacaoFornecedorResumoModel>> observarFornecedoresDaCotacao(
    String idCotacao,
  );

  Stream<List<CotacaoServicoResumoModel>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  });

  Future<CotacaoConversaModel?> buscarConversaFornecedor({
    required String idCotacao,
    required String idFornecedor,
  });

  Future<void> marcarMensagensComoLidas({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
  });

  Future<void> enviarMensagem({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
    required String nomeUsuario,
    required String mensagem,
  });

  Future<String> criarCotacao({
    required String idEvento,
    required String categoriaNome,
    required String observacao,
    required double valorEstimadoTotal,
    required DateTime dataLimiteResposta,
    required List<String> fornecedoresSelecionados,
    required List<Map<String, dynamic>> servicos,
  });

  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    String? observacaoFornecedor,
  });

  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  });
}

class FirebaseCotacaoRemoteDatasource implements CotacaoRemoteDatasource {
  FirebaseCotacaoRemoteDatasource({
    required FirebaseFirestore firestore,
    required CotacaoFunctionsDatasource functions,
  })  : _db = firestore,
        _functions = functions;

  final FirebaseFirestore _db;
  final CotacaoFunctionsDatasource _functions;

  CotacaoFunctionsDatasource get _callable => _functions;

  @override
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario) {
    return _db
        .collection('cotacao')
        .where('id_usuario_solicitante', isEqualTo: idUsuario)
        .orderBy('data_envio', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final lista = <CotacaoModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final totalEstimado = await _calcularTotalEstimado(doc.reference);

        lista.add(
          CotacaoModel(
            id: doc.id,
            idEvento: data['id_evento'],
            idUsuarioSolicitante: data['id_usuario_solicitante'],
            nomeUsuarioSolicitante: data['nome_usuario_solicitante'],
            categoriaNome: data['categoria_nome'] ?? '',
            descricao: data['observacao'] ?? data['descricao'],
            dataLimiteResposta:
                (data['data_limite_resposta'] as Timestamp?)?.toDate(),
            dataCadastro:
                (data['data_envio'] as Timestamp?)?.toDate() ?? DateTime.now(),
            status: StatusCotacao.fromString(data['status']),
            valorEstimadoTotal: totalEstimado,
            fornecedores: const [],
            servicos: const [],
          ),
        );
      }

      return lista;
    });
  }

  Future<double> _calcularTotalEstimado(
    DocumentReference<Map<String, dynamic>> cotacaoRef,
  ) async {
    double totalEstimado = 0.0;
    final fornecedoresSnap = await cotacaoRef.collection('fornecedores').get();

    for (final fornecedorDoc in fornecedoresSnap.docs) {
      final servicosSnap =
          await fornecedorDoc.reference.collection('servicos').get();
      for (final servico in servicosSnap.docs) {
        final data = servico.data();
        final valor = data['valor_estimado'] ?? 0;
        final quantidade = data['quantidade'] ?? 1;
        if (valor is num && quantidade is num) {
          totalEstimado += valor.toDouble() * quantidade.toDouble();
        }
      }
    }

    return totalEstimado;
  }

  @override
  Stream<bool> observarCotacaoTemResposta(String idCotacao) {
    return _db
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.any((doc) {
        final status = doc.data()['status'];
        return status == 'respondido' || status == 'respondida';
      });
    });
  }

  @override
  Stream<List<CotacaoConversaModel>> observarConversasFornecedor(
    String idFornecedor,
  ) {
    return _db
        .collectionGroup('fornecedores')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .snapshots()
        .asyncMap((snapshot) async {
      final conversas = <CotacaoConversaModel>[];
      for (final fornecedorDoc in snapshot.docs) {
        final conversa = await _montarConversa(
          fornecedorDoc: fornecedorDoc,
          idFornecedor: idFornecedor,
        );
        if (conversa != null) conversas.add(conversa);
      }
      conversas.sort((a, b) {
        final dataA = a.ultimaMensagemEm ?? a.dataSolicitacao;
        final dataB = b.ultimaMensagemEm ?? b.dataSolicitacao;
        return dataB.compareTo(dataA);
      });
      return conversas;
    });
  }

  @override
  Stream<List<CotacaoMensagemModel>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return _mensagensRef(idCotacao, idFornecedor)
        .orderBy('enviado_em')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _mensagemFromMap(doc.data())).toList(),
        );
  }

  @override
  Stream<List<CotacaoFornecedorResumoModel>> observarFornecedoresDaCotacao(
    String idCotacao,
  ) {
    return _db
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .snapshots()
        .asyncMap((snapshot) async {
      final fornecedores = <CotacaoFornecedorResumoModel>[];
      for (final doc in snapshot.docs) {
        fornecedores.add(
          await _fornecedorResumoFromDocument(idCotacao, doc),
        );
      }
      return fornecedores;
    });
  }

  @override
  Stream<List<CotacaoServicoResumoModel>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return _servicosRef(idCotacao, idFornecedor).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => _servicoResumoFromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<CotacaoConversaModel?> buscarConversaFornecedor({
    required String idCotacao,
    required String idFornecedor,
  }) async {
    final doc = await _db
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .doc(idFornecedor)
        .get();
    if (!doc.exists) return null;
    return _montarConversa(
      fornecedorDoc: doc,
      idFornecedor: idFornecedor,
    );
  }

  @override
  Future<void> marcarMensagensComoLidas({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
  }) async {
    final snap = await _mensagensRef(idCotacao, idFornecedor)
        .where('id_usuario', isNotEqualTo: idUsuario)
        .get();

    final batch = _db.batch();
    var hasUpdates = false;
    for (final m in snap.docs) {
      final data = m.data();
      if (data['lido'] != true) {
        batch.update(m.reference, {'lido': true});
        hasUpdates = true;
      }
    }
    if (hasUpdates) await batch.commit();
  }

  @override
  Future<void> enviarMensagem({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
    required String nomeUsuario,
    required String mensagem,
  }) {
    return _mensagensRef(idCotacao, idFornecedor).add({
      'id_usuario': idUsuario,
      'nome_usuario': nomeUsuario,
      'mensagem': mensagem,
      'enviado_em': FieldValue.serverTimestamp(),
      'lido': false,
    });
  }

  @override
  Future<String> criarCotacao({
    required String idEvento,
    required String categoriaNome,
    required String observacao,
    required double valorEstimadoTotal,
    required DateTime dataLimiteResposta,
    required List<String> fornecedoresSelecionados,
    required List<Map<String, dynamic>> servicos,
  }) {
    return _callable.criarCotacao(
      idEvento: idEvento,
      categoriaNome: categoriaNome,
      observacao: observacao,
      valorEstimadoTotal: valorEstimadoTotal,
      dataLimiteResposta: dataLimiteResposta,
      fornecedoresSelecionados: fornecedoresSelecionados,
      servicos: servicos,
    );
  }

  @override
  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    String? observacaoFornecedor,
  }) {
    return _callable.responderCotacao(
      idCotacao: idCotacao,
      aceitou: aceitou,
      prazoEntrega: prazoEntrega,
      condicaoPagamento: condicaoPagamento ?? '',
      observacaoFornecedor: observacaoFornecedor ?? '',
    );
  }

  @override
  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  }) {
    return _callable.fecharCotacao(
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      nomeFornecedor: nomeFornecedor,
      nomeSolicitante: nomeSolicitante,
    );
  }

  CollectionReference<Map<String, dynamic>> _mensagensRef(
    String idCotacao,
    String idFornecedor,
  ) {
    return _db
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .doc(idFornecedor)
        .collection('mensagens');
  }

  CollectionReference<Map<String, dynamic>> _servicosRef(
    String idCotacao,
    String idFornecedor,
  ) {
    return _db
        .collection('cotacao')
        .doc(idCotacao)
        .collection('fornecedores')
        .doc(idFornecedor)
        .collection('servicos');
  }

  Future<CotacaoConversaModel?> _montarConversa({
    required DocumentSnapshot<Map<String, dynamic>> fornecedorDoc,
    required String idFornecedor,
  }) async {
    final cotacaoRef = fornecedorDoc.reference.parent.parent;
    if (cotacaoRef == null) return null;

    final fornecedorData = fornecedorDoc.data() ?? <String, dynamic>{};
    final cotacaoDoc = await cotacaoRef.get();
    final cotacaoData = cotacaoDoc.data() ?? <String, dynamic>{};
    final mensagens = await _mensagensRef(cotacaoRef.id, idFornecedor)
        .orderBy('enviado_em', descending: true)
        .get();

    final ultima =
        mensagens.docs.isNotEmpty ? mensagens.docs.first.data() : null;
    final naoLidas =
        mensagens.docs.where((m) => (m.data()['lido'] ?? false) != true).length;

    return CotacaoConversaModel(
      idCotacao: cotacaoRef.id,
      idFornecedor: idFornecedor,
      categoria: (fornecedorData['categoria_nome'] ??
              cotacaoData['categoria_nome'] ??
              'Categoria')
          .toString(),
      idEvento: (fornecedorData['id_evento'] ?? cotacaoData['id_evento'] ?? '')
          .toString(),
      nomeSolicitante:
          (cotacaoData['nome_usuario_solicitante'] ?? 'Organizador').toString(),
      dataSolicitacao: _toDateTime(cotacaoData['data_envio']) ?? DateTime.now(),
      ultimaMensagem: (ultima?['mensagem'] ?? 'Conversa iniciada').toString(),
      ultimaMensagemEm: _toDateTime(ultima?['enviado_em']),
      naoLidas: naoLidas,
    );
  }

  Future<CotacaoFornecedorResumoModel> _fornecedorResumoFromDocument(
    String idCotacao,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final idFornecedor = (data['id_fornecedor'] ?? doc.id).toString();
    final servicosSnap = await _servicosRef(idCotacao, idFornecedor).get();
    return CotacaoFornecedorResumoModel(
      idFornecedor: idFornecedor,
      status: (data['status'] ?? 'aguardando').toString().toLowerCase(),
      observacaoFornecedor: (data['observacao_fornecedor'] ?? '').toString(),
      prazoEntrega: _toDateTime(data['prazo_entrega']),
      condicaoPagamento: data['condicao_pagamento']?.toString(),
      servicos: servicosSnap.docs
          .map((servico) => _servicoResumoFromMap(servico.data()))
          .toList(),
    );
  }

  CotacaoMensagemModel _mensagemFromMap(Map<String, dynamic> data) {
    return CotacaoMensagemModel(
      idUsuario: (data['id_usuario'] ?? '').toString(),
      nomeUsuario: (data['nome_usuario'] ?? '').toString(),
      mensagem: (data['mensagem'] ?? '').toString(),
      enviadoEm: _toDateTime(data['enviado_em']) ?? DateTime.now(),
      lido: data['lido'] == true,
    );
  }

  CotacaoServicoResumoModel _servicoResumoFromMap(Map<String, dynamic> data) {
    return CotacaoServicoResumoModel(
      nome: (data['nome_produto_servico'] ?? 'Serviço').toString(),
      quantidade: (data['quantidade'] as num?) ?? 1,
      valorEstimado: (data['valor_estimado'] as num?) ?? 0,
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value.toString());
  }
}
