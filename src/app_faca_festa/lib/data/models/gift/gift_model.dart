import 'package:cloud_firestore/cloud_firestore.dart';

import './../../../domain/entities/gift/gift.dart';

class GiftModel extends Gift {
  GiftModel({
    required super.id,
    required super.nome,
    super.descricao,
    required super.categoria,
    required super.tipo,
    super.valor,
    super.loja,
    super.link,
    super.pix,
    super.metaValor,
    super.valorArrecadado,
    super.imagem,
    required super.status,
    super.reservadoPor,
    super.reservadoUid,
    super.dataReserva,
    required super.createdAt,
  });

  /// Firestore -> Model
  factory GiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GiftModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'],
      categoria: data['categoria'] ?? 'geral',
      tipo: GiftType.values.firstWhere(
        (e) => e.name == data['tipo'],
        orElse: () => GiftType.fisico,
      ),
      valor: (data['valor'] ?? 0).toDouble(),
      loja: data['loja'],
      link: data['link'],
      pix: data['pix'],
      metaValor: (data['meta_valor'] ?? 0).toDouble(),
      valorArrecadado: (data['valor_arrecadado'] ?? 0).toDouble(),
      imagem: data['imagem'],
      status: GiftStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GiftStatus.disponivel,
      ),
      reservadoPor: data['reservado_por'],
      reservadoUid: data['reservado_uid'],
      dataReserva:
          data['data_reserva'] != null ? (data['data_reserva'] as Timestamp).toDate() : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  /// Model -> Firestore
  Map<String, dynamic> toMap() {
    return {
      "nome": nome,
      "descricao": descricao,
      "categoria": categoria,
      "tipo": tipo.name,
      "valor": valor,
      "loja": loja,
      "link": link,
      "pix": pix,
      "meta_valor": metaValor,
      "valor_arrecadado": valorArrecadado,
      "imagem": imagem,
      "status": status.name,
      "reservado_por": reservadoPor,
      "reservado_uid": reservadoUid,
      "data_reserva": dataReserva != null ? Timestamp.fromDate(dataReserva!) : null,
      "created_at": Timestamp.fromDate(createdAt),
    };
  }
}
