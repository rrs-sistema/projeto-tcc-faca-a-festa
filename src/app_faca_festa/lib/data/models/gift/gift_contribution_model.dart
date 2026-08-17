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

  factory GiftContributionModel.fromEntity(GiftContribution contribution) {
    return GiftContributionModel(
      id: contribution.id,
      nome: contribution.nome,
      uid: contribution.uid,
      valor: contribution.valor,
      mensagem: contribution.mensagem,
      data: contribution.data,
    );
  }

  factory GiftContributionModel.fromMap(Map<String, dynamic> map) {
    return GiftContributionModel(
      id: map['id'] ?? '',
      nome: map['nome'] ?? 'Anônimo',
      uid: map['uid'],
      valor: (map['valor'] ?? 0).toDouble(),
      mensagem: map['mensagem'],
      data: (map['data'] as Timestamp).toDate(),
    );
  }

  /// Preserves the document shape used by the existing saveContribution flow.
  Map<String, dynamic> toCreateMap() {
    return {
      'id': id,
      'nome': nome,
      'uid': uid,
      'valor': valor,
      'mensagem': mensagem,
      'data': Timestamp.fromDate(data),
      'created_at': FieldValue.serverTimestamp(),
    };
  }

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
