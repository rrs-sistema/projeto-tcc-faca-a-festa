import 'package:isar/isar.dart';

part 'gift_contribution_local.g.dart';

@Name("ContributionLocal") // 🔥 O TRUQUE ESTÁ AQUI! Isso vai mudar o cálculo do ID.
@collection
class GiftContributionLocal {
  Id id = Isar.autoIncrement;
  late String contributionId;
  late String eventoId;
  late String giftId;
  late String nome;
  String? uid;
  double valor = 0.0;
  String? mensagem;
  late DateTime createdAt;
  bool synced = false;
}
