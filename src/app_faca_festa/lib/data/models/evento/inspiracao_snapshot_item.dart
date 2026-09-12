import 'inspiracao_model.dart';

import 'package:app_faca_festa/domain/entities/inspiracao_snapshot.dart';

export 'package:app_faca_festa/domain/entities/inspiracao_snapshot.dart';

class InspiracaoSnapshotItem extends InspiracaoSnapshot {
  const InspiracaoSnapshotItem({
    required InspiracaoModel inspiracao,
    required super.data,
  }) : super(inspiracao: inspiracao);

  factory InspiracaoSnapshotItem.fromEntity(InspiracaoSnapshot entity) {
    if (entity is InspiracaoSnapshotItem) return entity;

    return InspiracaoSnapshotItem(
      inspiracao: InspiracaoModel.fromEntity(entity.inspiracao),
      data: Map<String, dynamic>.from(entity.data),
    );
  }
}
