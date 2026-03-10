import 'package:isar/isar.dart';

part 'gift_local.g.dart';

@collection
class GiftLocal {
  Id id = Isar.autoIncrement;
  @Index(name: 'fb_gift_id', unique: true, replace: true)
  late String giftId;
  late String eventoId;
  late String nome;
  String? descricao;
  String? categoria;
  late String tipo;
  double? valor;
  double valorArrecadado = 0.0;
  double? metaValor;
  String? loja;
  String? link;
  String? pix;
  String? imagem;
  String status = "disponivel";
  String? reservadoPor;
  String? reservadoUid;
  DateTime? dataReserva;
  bool deleted = false;
  bool synced = false;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
