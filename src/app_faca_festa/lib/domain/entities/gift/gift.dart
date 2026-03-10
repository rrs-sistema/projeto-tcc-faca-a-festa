import './../../../data/models/gift/gift_model.dart';

enum GiftType { fisico, pix, coletivo }

enum GiftStatus { disponivel, reservado, comprado, finalizado }

class Gift {
  
  final String id;
  final String nome;
  final String? descricao;
  final String categoria;
  final GiftType tipo;
  final double? valor;
  final double valorArrecadado;
  final double? metaValor;
  final String? loja;
  final String? link;
  final String? pix;
  final String? imagem;
  final GiftStatus status;
  final String? reservadoPor;
  final String? reservadoUid;
  final DateTime? dataReserva;
  final DateTime createdAt;

  const Gift({
    required this.id,
    required this.nome,
    this.descricao,
    required this.categoria,
    required this.tipo,
    this.valor,
    this.metaValor,
    this.valorArrecadado = 0,
    this.loja,
    this.link,
    this.pix,
    this.imagem,
    required this.status,
    this.reservadoPor,
    this.reservadoUid,
    this.dataReserva,
    required this.createdAt,
  });
}

extension GiftEntityMapper on Gift {
  GiftModel toModel() {
    return GiftModel(
      id: id,
      nome: nome,
      descricao: descricao ?? '',
      categoria: categoria,
      tipo: tipo,
      valor: valor ?? 0.0,
      valorArrecadado: valorArrecadado,
      metaValor: metaValor ?? 0.0,
      loja: loja ?? '',
      link: link ?? '',
      pix: pix ?? '',
      imagem: imagem,
      status: status,
      reservadoPor: reservadoPor,
      reservadoUid: reservadoUid,
      dataReserva: dataReserva,
      createdAt: createdAt,
    );
  }
}
