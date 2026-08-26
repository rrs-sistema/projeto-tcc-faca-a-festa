import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../models/model.dart';
import 'cotacao_functions_datasource.dart';

abstract interface class CotacaoRemoteDatasource {
  Stream<List<CotacaoModel>> observarMinhasCotacoes(String idUsuario);

  Stream<bool> observarCotacaoTemResposta(String idCotacao);

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
    CotacaoFunctionsDatasource? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions;

  final FirebaseFirestore _db;
  final CotacaoFunctionsDatasource? _functions;

  CotacaoFunctionsDatasource get _callable {
    if (_functions != null) return _functions;
    if (Get.isRegistered<CotacaoFunctionsDatasource>()) {
      return Get.find<CotacaoFunctionsDatasource>();
    }
    return Get.put(CotacaoFunctionsDatasource(), permanent: true);
  }

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
}
