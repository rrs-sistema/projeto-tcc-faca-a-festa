import '../../../domain/entities/gift/gift.dart';
import 'gift_local.dart';
import 'gift_model.dart';

extension GiftLocalMapper on GiftLocal {
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

extension GiftEntityToLocalMapper on Gift {
  GiftLocal toLocal({
    required String eventoId,
    GiftLocal? base,
  }) {
    final local = base ?? GiftLocal();
    local.giftId = id;
    local.eventoId = eventoId;
    local.nome = nome;
    local.descricao = descricao;
    local.categoria = categoria;
    local.tipo = tipo.name;
    local.valor = valor;
    local.valorArrecadado = valorArrecadado;
    local.loja = loja;
    local.link = link;
    local.pix = pix;
    local.metaValor = metaValor;
    local.imagem = imagem;
    local.status = status.name;
    local.reservadoPor = reservadoPor;
    local.reservadoUid = reservadoUid;
    local.dataReserva = dataReserva;
    local.synced = false;
    local.updatedAt = DateTime.now();

    if (base == null) local.createdAt = createdAt;

    return local;
  }
}
