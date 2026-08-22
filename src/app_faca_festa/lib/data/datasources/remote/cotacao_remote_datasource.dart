import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../models/orcamento/orcamento_gasto_model.dart';
import '../../models/model.dart';

abstract interface class CotacaoRemoteDatasource {
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario);

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
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final Uuid _uuid;

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
  Future<String> confirmarFornecedorEscolhido({
    required String idCotacao,
    required String idFornecedor,
    required String nomeFornecedor,
    required String idSolicitante,
    required String nomeSolicitante,
  }) async {
    final cotacaoRef = _db.collection('cotacao').doc(idCotacao);
    final cotacaoSnap = await cotacaoRef.get();
    if (!cotacaoSnap.exists) throw Exception('Cotação não encontrada.');

    final data = cotacaoSnap.data() as Map<String, dynamic>;
    final idEvento = data['id_evento'];
    final idUsuarioSolicitante = data['id_usuario_solicitante'];
    final categoriaNome = data['categoria_nome'];

    final servicosSnap = await cotacaoRef
        .collection('fornecedores')
        .doc(idFornecedor)
        .collection('servicos')
        .get();

    String? idServicoContratado;
    String? nomeServicoContratado;
    double valorTotal = 0.0;
    for (final servico in servicosSnap.docs) {
      final item = servico.data();
      final valor = (item['valor_estimado'] ?? 0).toDouble();
      final quantidade = (item['quantidade'] ?? 1).toDouble();
      valorTotal += valor * quantidade;
      idServicoContratado ??= item['id_produto_servico'];
      nomeServicoContratado ??= item['nome_produto_servico'];
    }

    final fornecedoresSnap = await cotacaoRef.collection('fornecedores').get();
    final batch = _db.batch();

    for (final fornecedor in fornecedoresSnap.docs) {
      final id = fornecedor['id_fornecedor'];
      batch.update(fornecedor.reference, {
        'status': id == idFornecedor ? 'fechado' : 'perdeuCotacao',
      });
    }

    batch.update(cotacaoRef, {
      'status': StatusCotacao.concluida.firestoreValue,
      'data_fechamento': Timestamp.now(),
      'fechado_por': idUsuarioSolicitante,
    });

    final orcRef = _db.collection('orcamento').doc();
    final orcamento = OrcamentoModel(
      idOrcamento: orcRef.id,
      idEvento: idEvento,
      idFornecedor: idFornecedor,
      nomeFornecedor: nomeFornecedor,
      custoEstimado: valorTotal,
      idSolicitante: idSolicitante,
      nomeSolicitante: nomeSolicitante,
      anotacoes:
          'Orçamento gerado automaticamente após fechamento da cotação "$categoriaNome".',
      status: StatusOrcamento.emNegociacao,
      orcamentoFechado: false,
      idServicoFornecido: '',
    );
    batch.set(orcRef, orcamento.toMap());

    await batch.commit();

    final gastoId = _uuid.v4();
    final gastoData = OrcamentoGastoModel(
      idGasto: gastoId,
      idOrcamento: orcRef.id,
      nome: 'Serviço contratado – $categoriaNome',
      custo: valorTotal,
      pago: 0,
      idServicoContratado: idServicoContratado,
      nomeServicoContratado: nomeServicoContratado,
    ).toMap()
      ..['id_servico'] = idServicoContratado
      ..['nome_servico'] = nomeServicoContratado
      ..['data_cadastro'] = Timestamp.now();

    await _db
        .collection('orcamento')
        .doc(orcRef.id)
        .collection('orcamento_gasto')
        .doc(gastoId)
        .set(gastoData);

    return idEvento;
  }
}
