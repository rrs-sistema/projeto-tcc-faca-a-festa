import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/convidado/convidado_model.dart';
import '../../../domain/repositories/convidado_repository.dart';

class ConvidadoRemoteDatasource {
  ConvidadoRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _convidados =>
      firestore.collection('convidado');

  Future<ConvidadoModel?> buscarPorId(String idConvidado) async {
    final snapshot = await _convidados
        .where('id_convidado', isEqualTo: idConvidado)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ConvidadoModel.fromMap(snapshot.docs.first.data());
  }

  Future<ConvidadoModel?> buscarPrimeiroPorEvento(String idEvento) async {
    final snapshot = await _convidados
        .where('id_evento', isEqualTo: idEvento)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ConvidadoModel.fromMap(snapshot.docs.first.data());
  }

  Future<ConvidadoModel?> buscarPorToken(String token) async {
    final tokenLimpo = token.trim();
    if (tokenLimpo.isEmpty) return null;

    final document = await _convidados.doc(tokenLimpo).get();
    if (document.exists && document.data() != null) {
      return ConvidadoModel.fromMap(document.data()!);
    }

    for (final campo in const ['convite_token', 'token_convite', 'token']) {
      final snapshot = await _convidados
          .where(campo, isEqualTo: tokenLimpo)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return ConvidadoModel.fromMap(snapshot.docs.first.data());
      }
    }
    return null;
  }

  Stream<List<ConvidadoModel>> observarPorEvento(String idEvento) {
    return _convidados
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => ConvidadoModel.fromMap(document.data()))
              .toList(),
        );
  }

  Future<void> salvar(ConvidadoModel convidado) {
    return _convidados.doc(convidado.idConvidado).set(
          convidado.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> excluir(String idConvidado) {
    return _convidados.doc(idConvidado).delete();
  }

  Future<void> atualizarStatus(
    String idConvidado,
    StatusConvidado status,
    DateTime dataResposta,
  ) {
    return _convidados.doc(idConvidado).update({
      'status': status.firestoreValue,
      'data_resposta': Timestamp.fromDate(dataResposta),
    });
  }

  Future<MigracaoTipoConvidadoResultado> migrarTiposLegados() async {
    final snapshot = await _convidados.get();
    var batch = firestore.batch();
    var contadorBatch = 0;
    var totalAtualizados = 0;
    var totalIgnorados = 0;

    for (final document in snapshot.docs) {
      final data = document.data();
      final tipoAtual = data['tipo_convidado'];
      final jaTemTipo =
          tipoAtual != null && tipoAtual.toString().trim().isNotEmpty;

      if (jaTemTipo) {
        totalIgnorados++;
        continue;
      }

      batch.update(document.reference, {
        'tipo_convidado': data['adulto'] == false ? 'crianca' : 'adulto',
        'data_atualizacao': FieldValue.serverTimestamp(),
      });
      contadorBatch++;
      totalAtualizados++;

      if (contadorBatch == 450) {
        await batch.commit();
        batch = firestore.batch();
        contadorBatch = 0;
      }
    }

    if (contadorBatch > 0) {
      await batch.commit();
    }

    return MigracaoTipoConvidadoResultado(
      totalEncontrados: snapshot.docs.length,
      totalAtualizados: totalAtualizados,
      totalIgnorados: totalIgnorados,
    );
  }

  Future<void> garantirTokensConvite(Map<String, String> tokensPorId) async {
    if (tokensPorId.isEmpty) return;

    final batch = firestore.batch();
    var adicionou = false;
    tokensPorId.forEach((idConvidado, token) {
      final id = idConvidado.trim();
      final tokenLimpo = token.trim();
      if (id.isEmpty || tokenLimpo.isEmpty) return;

      batch.set(
        _convidados.doc(id),
        {
          'convite_token': tokenLimpo,
          'data_atualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      adicionou = true;
    });

    if (!adicionou) return;
    await batch.commit();
  }
}
