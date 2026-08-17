import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cardapio/cardapio_item_model.dart';
import '../../models/cardapio/cardapio_model.dart';
import '../../../domain/repositories/cardapio_repository.dart';

class CardapioRemoteDatasource {
  CardapioRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _cardapios =>
      firestore.collection('cardapios');

  Stream<List<CardapioModel>> observarCardapios(String idEvento) {
    return _cardapios
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        final data = Map<String, dynamic>.from(document.data());
        if ((data['id_cardapio'] ?? '').toString().trim().isEmpty) {
          data['id_cardapio'] = document.id;
        }
        if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
          data['id_evento'] = idEvento;
        }
        return CardapioModel.fromMap(data);
      }).toList();
    });
  }

  Stream<List<CardapioItemModel>> observarItens(
    String idCardapio, {
    String? idEvento,
  }) {
    return _cardapios
        .doc(idCardapio)
        .collection('itens')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        final data = Map<String, dynamic>.from(document.data());
        if ((data['id_item'] ?? '').toString().trim().isEmpty) {
          data['id_item'] = document.id;
        }
        if ((data['id_cardapio'] ?? '').toString().trim().isEmpty) {
          data['id_cardapio'] = idCardapio;
        }
        if (idEvento != null &&
            (data['id_evento'] ?? '').toString().trim().isEmpty) {
          data['id_evento'] = idEvento;
        }
        return CardapioItemModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> salvarCardapio(CardapioModel cardapio) {
    final data = Map<String, dynamic>.from(cardapio.toMap())
      ..['id_cardapio'] = cardapio.idCardapio
      ..['id_evento'] = cardapio.idEvento
      ..removeWhere((key, value) => value == null);
    return _cardapios
        .doc(cardapio.idCardapio)
        .set(data, SetOptions(merge: true));
  }

  Future<void> excluirCardapio(String idCardapio) async {
    final reference = _cardapios.doc(idCardapio);
    final itens = await reference.collection('itens').get();
    final batch = firestore.batch();
    for (final item in itens.docs) {
      batch.delete(item.reference);
    }
    batch.delete(reference);
    await batch.commit();
  }

  Future<void> salvarItem(
    String idCardapio,
    CardapioItemModel item,
  ) {
    final collection = _cardapios.doc(idCardapio).collection('itens');
    final idItem =
        item.idItem.trim().isNotEmpty ? item.idItem : collection.doc().id;
    final data = Map<String, dynamic>.from(item.toMap())
      ..['id_item'] = idItem
      ..['id_cardapio'] = idCardapio;
    return collection.doc(idItem).set(data, SetOptions(merge: true));
  }

  Future<void> alternarConfirmado(
    String idCardapio,
    CardapioItemModel item,
  ) {
    return _cardapios
        .doc(idCardapio)
        .collection('itens')
        .doc(item.idItem)
        .update({'confirmado': !item.confirmado});
  }

  Future<void> excluirItem(String idCardapio, String idItem) {
    return _cardapios.doc(idCardapio).collection('itens').doc(idItem).delete();
  }

  Future<void> atualizarResumo(
    String idCardapio,
    ResumoCardapio resumo,
  ) {
    return _cardapios.doc(idCardapio).set({
      'total_itens': resumo.totalItens,
      'total_comidas': resumo.totalComidas,
      'total_bebidas': resumo.totalBebidas,
      'total_sobremesas': resumo.totalSobremesas,
    }, SetOptions(merge: true));
  }
}
