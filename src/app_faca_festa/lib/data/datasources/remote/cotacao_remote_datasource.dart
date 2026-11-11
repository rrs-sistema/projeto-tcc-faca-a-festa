import 'package:firebase_auth/firebase_auth.dart';
import '../../services/stream_da_sessao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cotacao/cotacao_chat_model.dart';
import '../../models/cotacao/cotacao_model.dart';
import 'cotacao_functions_datasource.dart';
import 'package:app_faca_festa/domain/entities/cotacao.dart';

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
    required List<ItemServicoCotacao> servicos,
  });

  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    String? observacaoFornecedor,
    double? valorProposto,
  });

  Future<Map<String, dynamic>> confirmarFornecedorEscolhido({
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
    // Sem orderBy no servidor: evita índice composto obrigatório
    // (id_usuario_solicitante + data_envio). Ordenação fica no cliente.
    return streamDaSessao(
      identidade: FirebaseAuth.instance.currentUser?.uid,
      sessoes: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
      vazio: [],
      fonte: _db
          .collection('cotacao')
          .where('id_usuario_solicitante', isEqualTo: idUsuario)
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) => !snapshot.metadata.isFromCache)
          .asyncMap((snapshot) async {
        final lista = <CotacaoModel>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final fornecedores = (await doc.reference
                  .collection('fornecedores')
                  .get(const GetOptions(source: Source.server)))
              .docs;
          final (itens, totalEstimado) =
              await _carregarServicosCotacao(fornecedores);
          final statusPai =
              StatusCotacao.fromString(data['status']?.toString());
          final status =
              _statusEfetivoDaCotacao(fornecedores, statusPai);

          lista.add(
            CotacaoModel(
              id: doc.id,
              idEvento: (data['id_evento'] ?? '').toString(),
              idUsuarioSolicitante:
                  (data['id_usuario_solicitante'] ?? idUsuario).toString(),
              nomeUsuarioSolicitante:
                  (data['nome_usuario_solicitante'] ?? '').toString(),
              categoriaNome: (data['categoria_nome'] ?? '').toString(),
              descricao: (data['observacao'] ?? data['descricao'])?.toString(),
              dataLimiteResposta:
                  (data['data_limite_resposta'] as Timestamp?)?.toDate(),
              dataCadastro: (data['data_envio'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              status: status,
              valorEstimadoTotal: totalEstimado,
              fornecedores: const [],
              servicos: itens.isNotEmpty
                  ? itens
                  : CotacaoModel.parseServicos(data['servicos'])
                      .where((item) => item.nome.trim().isNotEmpty)
                      .toList(),
            ),
          );
        }

        lista.sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
        return lista;
      }),
    );
  }

  /// Se o pai ficou preso em `pendente` mas já há resposta nos fornecedores,
  /// deriva o status efetivo para a UI do organizador.
  StatusCotacao _statusEfetivoDaCotacao(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> fornecedores,
    StatusCotacao statusPai,
  ) {
    if (statusPai == StatusCotacao.concluida ||
        statusPai == StatusCotacao.cancelada ||
        statusPai == StatusCotacao.respondida ||
        statusPai == StatusCotacao.parcial) {
      return statusPai;
    }

    if (fornecedores.isEmpty) return statusPai;

    final statuses = fornecedores
        .map((d) => (d.data()['status'] ?? '').toString().toLowerCase())
        .toList();
    final finalizados = statuses.every(
      (s) =>
          s == 'respondido' ||
          s == 'respondida' ||
          s == 'recusado' ||
          s == 'cancelada' ||
          s == 'fechado' ||
          s == 'perdeucotacao',
    );
    final algumPreco =
        statuses.any((s) => s == 'respondido' || s == 'respondida');
    final soRecusas =
        statuses.every((s) => s == 'recusado' || s == 'cancelada');

    if (soRecusas) return StatusCotacao.cancelada;
    if (finalizados && algumPreco) return StatusCotacao.respondida;
    if (algumPreco) return StatusCotacao.parcial;
    return statusPai;
  }

  Future<(List<CotacaoServicoResumoModel>, double)> _carregarServicosCotacao(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> fornecedores,
  ) async {
    var totalEstimado = 0.0;
    final itens = <(String, num), CotacaoServicoResumoModel>{};

    for (final fornecedorDoc in fornecedores) {
      final servicosSnap = await fornecedorDoc.reference
          .collection('servicos')
          .get(const GetOptions(source: Source.server));
      for (final servico in servicosSnap.docs) {
        final data = servico.data();
        final valor = data['valor_estimado'] ?? 0;
        final quantidade = data['quantidade'] ?? 1;
        if (valor is num && quantidade is num) {
          totalEstimado += valor.toDouble() * quantidade.toDouble();
        }
        final item = _servicoResumoFromMap(data);
        final nome = item.nome.trim().toLowerCase();
        if (nome.isEmpty) continue;
        final id = data['id_produto_servico']?.toString().trim();
        itens.putIfAbsent(
            (id == null || id.isEmpty ? nome : id, item.quantidade), () => item);
      }
    }

    return (itens.values.toList(), totalEstimado);
  }

  @override
  Stream<bool> observarCotacaoTemResposta(String idCotacao) {
    return streamDaSessao(
      identidade: FirebaseAuth.instance.currentUser?.uid,
      sessoes: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
      vazio: false,
      fonte: _db
          .collection('cotacao')
          .doc(idCotacao)
          .collection('fornecedores')
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) => !snapshot.metadata.isFromCache)
          .map((snapshot) {
        return snapshot.docs.any((doc) {
          final status = doc.data()['status'];
          return status == 'respondido' || status == 'respondida';
        });
      }),
    );
  }

  @override
  Stream<List<CotacaoConversaModel>> observarConversasFornecedor(
    String idFornecedor,
  ) {
    return streamDaSessao(
      identidade: FirebaseAuth.instance.currentUser?.uid,
      sessoes: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
      vazio: [],
      fonte: _db
          .collectionGroup('fornecedores')
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) => !snapshot.metadata.isFromCache)
          .asyncMap((snapshot) async {
        final conversas = <CotacaoConversaModel>[];
        for (final fornecedorDoc in snapshot.docs) {
          if (fornecedorDoc.reference.parent.parent?.parent.id != 'cotacao') {
            continue;
          }
          final conversa = await _montarConversa(
            fornecedorDoc: fornecedorDoc,
            idFornecedor: idFornecedor,
          );
          if (conversa != null) conversas.add(conversa);
        }
        conversas.sort((a, b) {
          if ((a.naoLidas > 0) != (b.naoLidas > 0)) {
            return a.naoLidas > 0 ? -1 : 1;
          }
          final dataA = a.ultimaMensagemEm ?? a.dataSolicitacao;
          final dataB = b.ultimaMensagemEm ?? b.dataSolicitacao;
          return (dataB?.millisecondsSinceEpoch ?? 0)
              .compareTo(dataA?.millisecondsSinceEpoch ?? 0);
        });
        return conversas;
      }),
    );
  }

  @override
  Stream<List<CotacaoMensagemModel>> observarMensagens({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return streamDaSessao(
      identidade: FirebaseAuth.instance.currentUser?.uid,
      sessoes: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
      vazio: [],
      fonte: _mensagensRef(idCotacao, idFornecedor)
          .orderBy('enviado_em')
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) => !snapshot.metadata.isFromCache)
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => _mensagemFromMap(doc.data()))
                .toList(),
          ),
    );
  }

  @override
  Stream<List<CotacaoFornecedorResumoModel>> observarFornecedoresDaCotacao(
    String idCotacao,
  ) {
    return streamDaSessao(
      identidade: FirebaseAuth.instance.currentUser?.uid,
      sessoes: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
      vazio: [],
      fonte: _db
          .collection('cotacao')
          .doc(idCotacao)
          .collection('fornecedores')
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) => !snapshot.metadata.isFromCache)
          .asyncMap((snapshot) async {
        final fornecedores = <CotacaoFornecedorResumoModel>[];
        for (final doc in snapshot.docs) {
          fornecedores.add(
            await _fornecedorResumoFromDocument(idCotacao, doc),
          );
        }
        return fornecedores;
      }),
    );
  }

  @override
  Stream<List<CotacaoServicoResumoModel>> observarServicosFornecedorCotacao({
    required String idCotacao,
    required String idFornecedor,
  }) {
    return streamDaSessao(
      identidade: FirebaseAuth.instance.currentUser?.uid,
      sessoes: FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
      vazio: [],
      fonte: _servicosRef(idCotacao, idFornecedor)
          .snapshots(includeMetadataChanges: true)
          .where((snapshot) => !snapshot.metadata.isFromCache)
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => _servicoResumoFromMap(doc.data()))
                .toList(),
          ),
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
        .get(const GetOptions(source: Source.server));
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
    if (FirebaseAuth.instance.currentUser?.uid != idUsuario) {
      throw StateError('Sessão alterada.');
    }
    final snap = await _mensagensRef(idCotacao, idFornecedor)
        .where('id_usuario', isNotEqualTo: idUsuario)
        .get(const GetOptions(source: Source.server));

    final pendentes = snap.docs.where((m) => m.data()['lido'] != true).toList();
    for (var inicio = 0; inicio < pendentes.length; inicio += 400) {
      if (FirebaseAuth.instance.currentUser?.uid != idUsuario) {
        throw StateError('Sessão alterada.');
      }
      final batch = _db.batch();
      for (final m in pendentes.skip(inicio).take(400)) {
        batch.update(m.reference, {'lido': true});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> enviarMensagem({
    required String idCotacao,
    required String idFornecedor,
    required String idUsuario,
    required String nomeUsuario,
    required String mensagem,
  }) {
    if (FirebaseAuth.instance.currentUser?.uid != idUsuario) {
      throw StateError('Sessão alterada.');
    }
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
    required List<ItemServicoCotacao> servicos,
  }) {
    return _callable.criarCotacao(
      idEvento: idEvento,
      categoriaNome: categoriaNome,
      observacao: observacao,
      valorEstimadoTotal: valorEstimadoTotal,
      dataLimiteResposta: dataLimiteResposta,
      fornecedoresSelecionados: fornecedoresSelecionados,
      servicos: servicos
          .map(
            (s) => {
              'idFornecedor': s.idFornecedor,
              'idProdutoServico': s.idProdutoServico,
              'quantidade': s.quantidade,
            },
          )
          .toList(),
    );
  }

  @override
  Future<void> responderCotacao({
    required String idCotacao,
    required bool aceitou,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    String? observacaoFornecedor,
    double? valorProposto,
  }) {
    return _callable.responderCotacao(
      idCotacao: idCotacao,
      aceitou: aceitou,
      prazoEntrega: prazoEntrega,
      condicaoPagamento: condicaoPagamento ?? '',
      observacaoFornecedor: observacaoFornecedor ?? '',
      valorProposto: valorProposto,
    );
  }

  @override
  Future<Map<String, dynamic>> confirmarFornecedorEscolhido({
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
    final cotacaoDoc =
        await cotacaoRef.get(const GetOptions(source: Source.server));
    final cotacaoData = cotacaoDoc.data();
    if (cotacaoData == null) return null;
    final nomeSolicitante =
        (cotacaoData['nome_usuario_solicitante'] ?? '').toString().trim();
    final observacao = (cotacaoData['observacao'] ?? '').toString().trim();
    final mensagens = await _mensagensRef(cotacaoRef.id, idFornecedor)
        .orderBy('enviado_em', descending: true)
        .get(const GetOptions(source: Source.server));

    final ultima =
        mensagens.docs.isNotEmpty ? mensagens.docs.first.data() : null;
    // Badge: mensagens de terceiros (não próprias, não sistema) ainda não lidas.
    final naoLidas = mensagens.docs.where((m) {
      final data = m.data();
      final autor = (data['id_usuario'] ?? '').toString();
      if (data['sistema'] == true ||
          autor.isEmpty ||
          autor == 'sistema' ||
          autor == idFornecedor) {
        return false;
      }
      return data['lido'] != true;
    }).length;

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
          nomeSolicitante.isEmpty ? 'Cliente não identificado' : nomeSolicitante,
      dataSolicitacao: _toDateTime(cotacaoData['data_envio']) ??
          _toDateTime(fornecedorData['data_envio']),
      observacaoPedido: observacao.isNotEmpty
          ? observacao
          : cotacaoData['descricao']?.toString().trim(),
      ultimaMensagem:
          (ultima?['mensagem'] ?? 'Nenhuma mensagem ainda').toString(),
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
    final servicosSnap = await _servicosRef(idCotacao, idFornecedor)
        .get(const GetOptions(source: Source.server));
    return CotacaoFornecedorResumoModel(
      idFornecedor: idFornecedor,
      nomeFornecedor: data['nome_fornecedor']?.toString().trim(),
      status: (data['status'] ?? 'aguardando').toString().toLowerCase(),
      observacaoFornecedor: (data['observacao_fornecedor'] ?? '').toString(),
      prazoEntrega: _toDateTime(data['prazo_entrega']),
      condicaoPagamento: data['condicao_pagamento']?.toString(),
      valorCotado: (data['valor_cotado'] as num?)?.toDouble(),
      servicos: servicosSnap.docs
          .map((servico) => _servicoResumoFromMap(servico.data()))
          .toList(),
    );
  }

  CotacaoMensagemModel _mensagemFromMap(Map<String, dynamic> data) {
    final idUsuario = (data['id_usuario'] ?? '').toString();
    return CotacaoMensagemModel(
      idUsuario: idUsuario,
      nomeUsuario: (data['nome_usuario'] ?? '').toString(),
      mensagem: (data['mensagem'] ?? '').toString(),
      enviadoEm: _toDateTime(data['enviado_em']) ?? DateTime.now(),
      lido: data['lido'] == true,
      sistema: data['sistema'] == true || idUsuario == 'sistema',
    );
  }

  CotacaoServicoResumoModel _servicoResumoFromMap(Map<String, dynamic> data) {
    final quantidade = data['quantidade'];
    final valor = data['valor_estimado'];
    return CotacaoServicoResumoModel(
      nome: (data['nome_produto_servico'] ?? 'Serviço').toString(),
      quantidade: quantidade is num ? quantidade : 1,
      valorEstimado: valor is num ? valor : 0,
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value.toString());
  }
}
