import 'inspiracao_model.dart';

class InspiracaoSnapshotItem {
  const InspiracaoSnapshotItem({
    required this.inspiracao,
    required this.data,
  });

  final InspiracaoModel inspiracao;
  final Map<String, dynamic> data;
}
