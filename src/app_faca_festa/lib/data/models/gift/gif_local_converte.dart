import 'package:drift/drift.dart';

import './../../../core/database/app_database.dart';
import './../../../domain/entities/gift/gift.dart';
import './gift_model.dart';

extension GiftRowMapper on GiftLocal {
  GiftModel toModel() {
    return GiftModel(
      id: giftId,
      nome: nome,
      descricao: descricao ?? '',
      categoria: categoria ?? 'geral',
      tipo: GiftType.values.firstWhere(
        (e) => e.name == tipo,
        orElse: () => GiftType.fisico,
      ),
      valor: valor ?? 0.0,
      valorArrecadado: valorArrecadado,
      metaValor: metaValor ?? 0.0,
      loja: loja ?? '',
      link: link ?? '',
      pix: pix ?? '',
      imagem: imagem,
      status: GiftStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => GiftStatus.disponivel,
      ),
      reservadoPor: reservadoPor,
      reservadoUid: reservadoUid,
      dataReserva: dataReserva,
      createdAt: createdAt,
    );
  }

  Gift toEntity() {
    return Gift(
      id: giftId,
      nome: nome,
      descricao: descricao,
      categoria: categoria ?? 'geral',
      tipo: GiftType.values.firstWhere(
        (e) => e.name == tipo,
        orElse: () => GiftType.fisico,
      ),
      valor: valor,
      valorArrecadado: valorArrecadado,
      metaValor: metaValor,
      loja: loja,
      link: link,
      pix: pix,
      imagem: imagem,
      status: GiftStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => GiftStatus.disponivel,
      ),
      reservadoPor: reservadoPor,
      reservadoUid: reservadoUid,
      dataReserva: dataReserva,
      createdAt: createdAt,
    );
  }
}

extension GiftEntityToCompanionMapper on Gift {
  GiftLocalsCompanion toCompanion({
    required String eventoId,
    bool synced = false,
    bool deleted = false,
    DateTime? updatedAtOverride,
  }) {
    final now = updatedAtOverride ?? DateTime.now();

    return GiftLocalsCompanion(
      giftId: Value(id),
      eventoId: Value(eventoId),
      nome: Value(nome),
      descricao: Value(descricao),
      categoria: Value(categoria),
      tipo: Value(tipo.name),
      valor: Value(valor),
      valorArrecadado: Value(valorArrecadado),
      metaValor: Value(metaValor),
      loja: Value(loja),
      link: Value(link),
      pix: Value(pix),
      imagem: Value(imagem),
      status: Value(status.name),
      reservadoPor: Value(reservadoPor),
      reservadoUid: Value(reservadoUid),
      dataReserva: Value(dataReserva),
      deleted: Value(deleted),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(now),
    );
  }
}
