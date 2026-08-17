import 'package:app_faca_festa/data/models/gift/gift_model.dart';
import 'package:app_faca_festa/domain/entities/gift/gift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftModel characterization', () {
    test('fromEntity preserves every domain value', () {
      final createdAt = DateTime(2026, 8, 13, 10, 30);
      final reservedAt = DateTime(2026, 8, 14, 9);
      final gift = Gift(
        id: 'gift-1',
        nome: 'Fotografia',
        descricao: 'Ensaio do evento',
        categoria: 'servicos',
        tipo: GiftType.coletivo,
        valor: 500,
        valorArrecadado: 125,
        metaValor: 1000,
        loja: 'Fornecedor A',
        link: 'https://example.com',
        pix: 'chave-pix',
        imagem: 'https://example.com/image.jpg',
        status: GiftStatus.reservado,
        reservadoPor: 'Convidado',
        reservadoUid: 'uid-1',
        dataReserva: reservedAt,
        createdAt: createdAt,
      );

      final model = GiftModel.fromEntity(gift);

      expect(model.id, gift.id);
      expect(model.nome, gift.nome);
      expect(model.descricao, gift.descricao);
      expect(model.categoria, gift.categoria);
      expect(model.tipo, gift.tipo);
      expect(model.valor, gift.valor);
      expect(model.valorArrecadado, gift.valorArrecadado);
      expect(model.metaValor, gift.metaValor);
      expect(model.loja, gift.loja);
      expect(model.link, gift.link);
      expect(model.pix, gift.pix);
      expect(model.imagem, gift.imagem);
      expect(model.status, gift.status);
      expect(model.reservadoPor, gift.reservadoPor);
      expect(model.reservadoUid, gift.reservadoUid);
      expect(model.dataReserva, gift.dataReserva);
      expect(model.createdAt, gift.createdAt);
    });

    test('toMap keeps the current Firestore field names', () {
      final createdAt = DateTime(2026, 8, 13, 10, 30);
      final gift = GiftModel(
        id: 'gift-1',
        nome: 'Fotografia',
        descricao: 'Ensaio do evento',
        categoria: 'servicos',
        tipo: GiftType.fisico,
        valor: 500,
        status: GiftStatus.disponivel,
        createdAt: createdAt,
      );

      final map = gift.toMap();

      expect(
        map.keys.toSet(),
        {
          'nome',
          'descricao',
          'categoria',
          'tipo',
          'valor',
          'loja',
          'link',
          'pix',
          'meta_valor',
          'valor_arrecadado',
          'imagem',
          'status',
          'reservado_por',
          'reservado_uid',
          'data_reserva',
          'created_at',
        },
      );
      expect(map['tipo'], 'fisico');
      expect(map['status'], 'disponivel');
      expect((map['created_at'] as Timestamp).toDate(), createdAt);
    });
  });
}
