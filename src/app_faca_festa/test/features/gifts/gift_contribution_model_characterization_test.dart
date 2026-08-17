import 'package:app_faca_festa/data/models/gift/gift_contribution_model.dart';
import 'package:app_faca_festa/domain/entities/gift/gift_contribution.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('contribution create map preserves the existing Firestore contract', () {
    final date = DateTime(2026, 8, 13, 11, 45);
    final contribution = GiftContribution(
      id: 'contribution-1',
      nome: 'Maria',
      uid: 'uid-1',
      valor: 75.5,
      mensagem: 'Parabéns!',
      data: date,
    );

    final map = GiftContributionModel.fromEntity(contribution).toCreateMap();

    expect(map['id'], 'contribution-1');
    expect(map['nome'], 'Maria');
    expect(map['uid'], 'uid-1');
    expect(map['valor'], 75.5);
    expect(map['mensagem'], 'Parabéns!');
    expect((map['data'] as Timestamp).toDate(), date);
    expect(map['created_at'], isA<FieldValue>());
  });
}
