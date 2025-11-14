import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/cardapio/cardapio_item_model.dart';
import './../../data/models/cardapio/cardapio_model.dart';

class CardapioController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<CardapioModel> cardapios = <CardapioModel>[].obs;
  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  Future<void> escutarCardapios(String idEvento) async {
    carregando.value = true;

    _db.collection('cardapios').where('id_evento', isEqualTo: idEvento).snapshots().listen(
        (snapshot) async {
      final lista = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();

        final cardapio = CardapioModel.fromMap(data);

        // Carrega itens da subcoleção
        final itensSnapshot =
            await _db.collection('cardapios').doc(cardapio.idCardapio).collection('itens').get();

        final itens = itensSnapshot.docs.map((i) => CardapioItemModel.fromMap(i.data())).toList();

        return cardapio.copyWith(itens: itens);
      }));

      cardapios.assignAll(lista);
      carregando.value = false;
    }, onError: (e) {
      erro.value = 'Erro ao carregar cardápios: $e';
      carregando.value = false;
    });
  }

  Future<void> adicionarCardapio(CardapioModel cardapio) async {
    await _db.collection('cardapios').doc(cardapio.idCardapio).set(cardapio.toMap());
  }

  Future<void> excluirCardapio(String idCardapio) async {
    await _db.collection('cardapios').doc(idCardapio).delete();
  }

  Future<void> toggleConfirmado(String idCardapio, CardapioItemModel item) async {
    await _db
        .collection('cardapios')
        .doc(idCardapio)
        .collection('itens')
        .doc(item.idItem)
        .update({"confirmado": !item.confirmado});
  }

  Future<void> addItem(String idCardapio, CardapioItemModel item) async {
    final doc = _db.collection('cardapios').doc(idCardapio).collection('itens').doc();

    await doc.set({
      ...item.toMap(),
      'id_item': doc.id,
    });
  }

  Future<void> excluirItem(String idCardapio, String idItem) async {
    await _db.collection('cardapios').doc(idCardapio).collection('itens').doc(idItem).delete();
  }

  int get totalCardapios => cardapios.length;
  int get totalItens => cardapios.fold(0, (soma, c) => soma + c.totalItens);
  int get totalComidas => cardapios.fold(0, (soma, c) => soma + c.totalComidas);
  int get totalBebidas => cardapios.fold(0, (soma, c) => soma + c.totalBebidas);
  int get totalSobremesas => cardapios.fold(0, (soma, c) => soma + c.totalSobremesas);
}
