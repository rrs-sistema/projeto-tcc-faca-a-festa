import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './../../models/gift/gift_contribution_model.dart';
import './../../models/gift/gift_model.dart';

class GiftRemoteDatasource {
  final FirebaseFirestore firestore;

  GiftRemoteDatasource(this.firestore);

  CollectionReference<Map<String, dynamic>> _ref(String eventoId) {
    return firestore.collection('evento').doc(eventoId).collection('presentes');
  }

  // ======================================================
  // STREAM REMOTO
  // ======================================================
  Stream<List<GiftModel>> watchRemote(String eventoId) {
    return _ref(eventoId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => GiftModel.fromFirestore(doc)).toList(),
        );
  }

  // ======================================================
  // CRIAR
  // ======================================================
  Future<void> createGift(
    String eventoId,
    GiftModel model,
  ) async {
    await _ref(eventoId).doc(model.id).set(model.toMap());
  }

// ======================================================
  // SAVE CONTRIBUTION (REMOTO)
  // ======================================================
  Future<void> saveContribution(
    String eventoId,
    String giftId,
    GiftContribution contribution,
  ) async {
    final presenteRef = _ref(eventoId).doc(giftId);

    // Cria uma referência para um novo documento com ID automático na sub-coleção
    final contribRef = presenteRef.collection('contributions').doc();

    // Usamos transaction para garantir que o valor_arrecadado seja atualizado com precisão
    return firestore.runTransaction((transaction) async {
      final snap = await transaction.get(presenteRef);

      if (!snap.exists) {
        throw Exception("Presente não encontrado no servidor.");
      }

      final atualArrecadado =
          (snap.data()?["valor_arrecadado"] ?? 0).toDouble();

      // 1. Salva o registro da contribuição
      transaction.set(
        contribRef,
        GiftContributionModel.fromEntity(contribution).toCreateMap(),
      );

      // 2. Atualiza o valor acumulado no presente (Incremento)
      transaction.update(
        presenteRef,
        {
          "valor_arrecadado": atualArrecadado + contribution.valor,
          "updated_at": FieldValue.serverTimestamp(),
        },
      );
    });
  }

  // ======================================================
  // ATUALIZAR
  // ======================================================
  Future<void> updateGift(
    String eventoId,
    GiftModel model,
  ) async {
    await _ref(eventoId).doc(model.id).update(model.toMap());
  }

  // ======================================================
  // DELETE
  // ======================================================
  Future<void> deleteGift(
    String eventoId,
    String giftId,
  ) async {
    await _ref(eventoId).doc(giftId).delete();
  }

  // ======================================================
  // RESERVAR
  // ======================================================
  Future<bool> reservarGift(
    String eventoId,
    String giftId,
    String nome,
    String uid,
  ) async {
    final ref = _ref(eventoId).doc(giftId);

    return firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);

      final data = snap.data();

      if (data == null) return false;

      if (data["status"] != "disponivel") {
        return false;
      }

      transaction.update(ref, {
        "status": "reservado",
        "reservado_por": nome,
        "reservado_uid": uid,
        "data_reserva": Timestamp.now(),
      });

      return true;
    });
  }

  // ======================================================
  // CONTRIBUIÇÃO PIX
  // ======================================================
  Future<void> contribuirPix(
    String eventoId,
    String giftId,
    GiftContributionModel contribution,
  ) async {
    final presenteRef = _ref(eventoId).doc(giftId);

    final contribRef = presenteRef.collection('contributions').doc();

    await firestore.runTransaction((transaction) async {
      final snap = await transaction.get(presenteRef);

      final atual = (snap["valor_arrecadado"] ?? 0).toDouble();

      transaction.set(
        contribRef,
        contribution.toMap(),
      );

      transaction.update(
        presenteRef,
        {
          "valor_arrecadado": atual + contribution.valor,
        },
      );
    });
  }
}
