import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/gift/gift_contribution.dart';

class GiftContributionModel extends GiftContribution {
  const GiftContributionModel({
    required super.id,
    required super.nome,
    super.uid,
    required super.valor,
    super.mensagem,
    required super.data,
  });

  /// Firestore -> Model
  factory GiftContributionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GiftContributionModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      uid: data['uid'],
      valor: (data['valor'] ?? 0).toDouble(),
      mensagem: data['mensagem'],
      data: (data['data'] as Timestamp).toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      "nome": nome,
      "uid": uid,
      "valor": valor,
      "mensagem": mensagem,
      "data": Timestamp.fromDate(data),
    };
  }
}
