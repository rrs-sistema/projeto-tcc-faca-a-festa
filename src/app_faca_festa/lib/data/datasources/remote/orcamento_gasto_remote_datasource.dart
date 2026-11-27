import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../models/orcamento/orcamento_gasto_model.dart';
import 'package:app_faca_festa/core/conectividade/conectividade_service.dart';
import 'package:app_faca_festa/core/conectividade/escrita_local_primeiro.dart';
import 'package:app_faca_festa/domain/entities/orcamento_validacao_resultado.dart';
import 'package:app_faca_festa/domain/services/validar_limite_gasto.dart';

class OrcamentoGastoRemoteDatasource {
  OrcamentoGastoRemoteDatasource({
    required FirebaseFirestore firestore,
    Uuid? uuid,
  })  : _db = firestore,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _db;
  final Uuid _uuid;

  Stream<List<OrcamentoGastoModel>> observarGastos(String idOrcamento) {
    return _gastosRef(idOrcamento)
        .orderBy('data_cadastro', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrcamentoGastoModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<OrcamentoValidacaoResultado> adicionarGasto({
    required String idOrcamento,
    required String nome,
    required double custo,
    required double pago,
  }) async {
    final refOrcamento = _db.collection('orcamento').doc(idOrcamento);

    if (!custo.isFinite || !pago.isFinite || custo <= 0) {
      return OrcamentoValidacaoResultado.erro(
        'O custo do item deve ser maior que zero.',
      );
    }

    if (pago > custo) {
      return OrcamentoValidacaoResultado.erro(
        'O valor pago não pode ser maior que o custo total do item.',
      );
    }

    if (pago < 0) {
      return OrcamentoValidacaoResultado.erro(
        'O valor pago não pode ser negativo.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> orcamentoSnap;
    try {
      orcamentoSnap = await LeituraLocalPrimeiro.documento(refOrcamento);
    } on FirebaseException catch (erro) {
      if (erro.code == 'permission-denied') rethrow;
      return OrcamentoValidacaoResultado.erro(
        'Este orçamento ainda não está salvo no aparelho. Conecte-se para registrar o gasto.',
      );
    }
    if (!orcamentoSnap.exists) {
      return OrcamentoValidacaoResultado.erro('Orçamento não encontrado.');
    }

    final data = orcamentoSnap.data()!;
    final double limiteCategoria = _comoDouble(data['custo_estimado']);
    final String idEvento = data['id_evento'];

    final gastosSnap = await LeituraLocalPrimeiro.consulta(
      refOrcamento.collection('orcamento_gasto'),
    );
    final totalPagoCategoria = gastosSnap.docs.fold<double>(
      0,
      (soma, doc) => soma + _comoDouble(doc.data()['pago']),
    );

    double limiteEvento = 0;
    try {
      final eventoSnap = await LeituraLocalPrimeiro.documento(
        _db.collection('evento').doc(idEvento),
      );
      limiteEvento = _comoDouble(eventoSnap.data()?['custo_estimado']);
    } on FirebaseException catch (erro) {
      if (erro.code == 'permission-denied') rethrow;
    }

    var totalPagoEvento = 0.0;
    final orcs = await LeituraLocalPrimeiro.consulta(
      _db.collection('orcamento').where('id_evento', isEqualTo: idEvento),
    );

    for (final doc in orcs.docs) {
      final gastosCat = await LeituraLocalPrimeiro.consulta(
        doc.reference.collection('orcamento_gasto'),
      );
      for (final gasto in gastosCat.docs) {
        totalPagoEvento += _comoDouble(gasto.data()['pago']);
      }
    }

    final limite = ValidarLimiteGasto.avaliar(
      custo: custo,
      pago: pago,
      limiteCategoria: limiteCategoria,
      totalPagoCategoria: totalPagoCategoria,
      limiteEvento: limiteEvento,
      totalPagoEvento: totalPagoEvento,
    );
    if (limite != null) return limite;

    final idGasto = _uuid.v4();
    final model = OrcamentoGastoModel(
      idGasto: idGasto,
      idOrcamento: idOrcamento,
      nome: nome,
      custo: custo,
      pago: pago,
    );

    await escritaLocalPrimeiro(
      _gastosRef(idOrcamento).doc(idGasto).set(model.toMap()),
      descricao: 'gasto "$nome"',
      chave: idGasto,
    );

    return OrcamentoValidacaoResultado.ok();
  }

  Future<void> marcarComoPago({
    required String idOrcamento,
    required String idGasto,
    required double valorTotal,
  }) async {
    if (!valorTotal.isFinite || valorTotal < 0) {
      throw ArgumentError('Confira o pagamento.');
    }
    final ref = _gastosRef(idOrcamento).doc(idGasto);
    void validar(Map<String, dynamic>? data) {
      if (data == null ||
          data['id_orcamento'] != null && data['id_orcamento'] != idOrcamento) {
        throw StateError('Despesa não encontrada neste orçamento.');
      }
      final custo = _comoDouble(data['custo']),
          pago = _comoDouble(data['pago']);
      if (valorTotal < pago || valorTotal > custo) {
        throw ArgumentError('O pagamento deve respeitar o saldo da despesa.');
      }
    }

    final atualizacao = {
      'pago': valorTotal,
      'pagamento_atualizado_em': FieldValue.serverTimestamp()
    };
    // Transação não roda sem servidor. Offline, valida com o que está no
    // aparelho; as regras revalidam `pago <= custo` ao sincronizar.
    if (ConectividadeService.offlineAgora) {
      final doc = await ref.get(const GetOptions(source: Source.cache));
      validar(doc.data());
      return escritaLocalPrimeiro(
        ref.update(atualizacao),
        descricao: 'pagamento de uma despesa',
        chave: idGasto,
      );
    }
    return _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      validar(doc.data());
      tx.update(ref, atualizacao);
    });
  }

  Future<void> removerGasto({
    required String idOrcamento,
    required String idGasto,
  }) {
    return escritaLocalPrimeiro(
      _gastosRef(idOrcamento).doc(idGasto).delete(),
      descricao: 'exclusão de um gasto',
      chave: idGasto,
    );
  }

  double _comoDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  CollectionReference<Map<String, dynamic>> _gastosRef(String idOrcamento) {
    return _db
        .collection('orcamento')
        .doc(idOrcamento)
        .collection('orcamento_gasto');
  }
}
