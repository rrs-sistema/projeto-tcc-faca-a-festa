import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

    _db
        .collection('cardapios')
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .listen((snapshot) async {
      final List<CardapioModel> listaTemp = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final cardapio = CardapioModel.fromMap(data);

        // 👉 Agora escutamos a SUBCOLEÇÃO DE VERDADE
        _db
            .collection('cardapios')
            .doc(cardapio.idCardapio)
            .collection('itens')
            .snapshots()
            .listen((sub) {
          final itens = sub.docs.map((i) => CardapioItemModel.fromMap(i.data())).toList();

          final atualizado = cardapio.copyWith(itens: itens);

          // Atualiza a lista reativa: substitui apenas o cardápio alterado
          final idx = listaTemp.indexWhere((c) => c.idCardapio == atualizado.idCardapio);
          if (idx >= 0) {
            listaTemp[idx] = atualizado;
          } else {
            listaTemp.add(atualizado);
          }

          // Atualiza a lista na UI
          cardapios.assignAll(listaTemp);
        });
      }

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

  Future<void> atualizarCardapio(CardapioModel c) async {
    final corHex = _colorToHex(c.cor ?? Colors.purple);

    await _db.collection("cardapios").doc(c.idCardapio).update({
      "titulo": c.titulo,
      "icone": c.icone?.codePoint,
      "cor_hex": corHex,
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

  String _colorToHex(Color color) {
    final a = color.a.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final r = color.r.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = color.g.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = color.b.toInt().toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$a$r$g$b';
  }
}
