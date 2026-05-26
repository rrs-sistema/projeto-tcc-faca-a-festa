import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../../data/models/cardapio/cardapio_item_model.dart';
import './../../data/models/cardapio/cardapio_model.dart';

class CardapioController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<CardapioModel> cardapios = <CardapioModel>[].obs;
  final RxMap<String, List<CardapioItemModel>> itensPorCardapio =
      <String, List<CardapioItemModel>>{}.obs;

  final RxBool carregando = false.obs;
  final RxString erro = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cardapiosSubscription;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>> _itensSubscriptions =
      {};

  Future<void> escutarCardapios(String idEvento) async {
    carregando.value = true;
    erro.value = '';

    await _cancelarEscutas();

    _cardapiosSubscription =
        _db.collection('cardapios').where('id_evento', isEqualTo: idEvento).snapshots().listen(
      (snapshot) {
        final lista = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());

          if ((data['id_cardapio'] ?? '').toString().trim().isEmpty) {
            data['id_cardapio'] = doc.id;
          }

          if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
            data['id_evento'] = idEvento;
          }

          return CardapioModel.fromMap(data);
        }).toList();

        cardapios.assignAll(lista);

        final idsAtuais = lista.map((c) => c.idCardapio).toSet();

        for (final idCardapio in _itensSubscriptions.keys.toList()) {
          if (!idsAtuais.contains(idCardapio)) {
            _itensSubscriptions[idCardapio]?.cancel();
            _itensSubscriptions.remove(idCardapio);
            itensPorCardapio.remove(idCardapio);
          }
        }

        for (final cardapio in lista) {
          _escutarItensDoCardapio(cardapio.idCardapio);
        }

        carregando.value = false;
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Não foi possível carregar os cardápios: $error';
        carregando.value = false;
      },
    );
  }

  void _escutarItensDoCardapio(String idCardapio) {
    if (_itensSubscriptions.containsKey(idCardapio)) return;

    _itensSubscriptions[idCardapio] =
        _db.collection('cardapios').doc(idCardapio).collection('itens').snapshots().listen(
      (snapshot) {
        final itens = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());

          if ((data['id_item'] ?? '').toString().trim().isEmpty) {
            data['id_item'] = doc.id;
          }

          if ((data['id_cardapio'] ?? '').toString().trim().isEmpty) {
            data['id_cardapio'] = idCardapio;
          }

          final idEvento = _idEventoPorCardapio(idCardapio);
          if (idEvento != null && (data['id_evento'] ?? '').toString().trim().isEmpty) {
            data['id_evento'] = idEvento;
          }

          return CardapioItemModel.fromMap(data);
        }).toList();

        itensPorCardapio[idCardapio] = itens;
        itensPorCardapio.refresh();

        _sincronizarResumoCardapio(idCardapio, itens);
      },
      onError: (Object error, StackTrace stackTrace) {
        erro.value = 'Não foi possível carregar os itens do cardápio: $error';
      },
    );
  }

  Future<void> adicionarCardapio(CardapioModel cardapio) async {
    final data = Map<String, dynamic>.from(cardapio.toMap());

    data['id_cardapio'] = cardapio.idCardapio;
    data['id_evento'] = cardapio.idEvento;

    await _db.collection('cardapios').doc(cardapio.idCardapio).set(data, SetOptions(merge: true));
  }

  Future<void> atualizarCardapio(CardapioModel cardapio) async {
    final data = <String, dynamic>{
      'id_cardapio': cardapio.idCardapio,
      'id_evento': cardapio.idEvento,
      'titulo': cardapio.titulo,
      'publico_alvo': cardapio.publicoAlvo.firestoreValue,
      'icone': cardapio.icone,
      'cor_hex': cardapio.corHex,
      'total_itens': cardapio.totalItens,
      'total_comidas': cardapio.totalComidas,
      'total_bebidas': cardapio.totalBebidas,
      'total_sobremesas': cardapio.totalSobremesas,
      'ativo': cardapio.ativo,
    };

    data.removeWhere((key, value) => value == null);

    await _db.collection('cardapios').doc(cardapio.idCardapio).set(data, SetOptions(merge: true));
  }

  Future<void> excluirCardapio(String idCardapio) async {
    final cardapioRef = _db.collection('cardapios').doc(idCardapio);
    final itensSnapshot = await cardapioRef.collection('itens').get();

    final batch = _db.batch();

    for (final item in itensSnapshot.docs) {
      batch.delete(item.reference);
    }

    batch.delete(cardapioRef);
    await batch.commit();

    _itensSubscriptions[idCardapio]?.cancel();
    _itensSubscriptions.remove(idCardapio);
    itensPorCardapio.remove(idCardapio);
    itensPorCardapio.refresh();
  }

  Future<void> addItem(String idCardapio, CardapioItemModel item) async {
    final itemId = item.idItem.trim().isNotEmpty
        ? item.idItem
        : _db.collection('cardapios').doc(idCardapio).collection('itens').doc().id;

    final doc = _db.collection('cardapios').doc(idCardapio).collection('itens').doc(itemId);

    final data = Map<String, dynamic>.from(item.toMap());

    data['id_item'] = itemId;
    data['id_cardapio'] = idCardapio;

    final idEvento =
        item.idEvento.trim().isNotEmpty ? item.idEvento : _idEventoPorCardapio(idCardapio);

    if (idEvento != null && idEvento.trim().isNotEmpty) {
      data['id_evento'] = idEvento;
    }

    await doc.set(data, SetOptions(merge: true));
  }

  Future<void> atualizarItem(String idCardapio, CardapioItemModel item) async {
    await _db
        .collection('cardapios')
        .doc(idCardapio)
        .collection('itens')
        .doc(item.idItem)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> toggleConfirmado(
    String idCardapio,
    CardapioItemModel item,
  ) async {
    await _db
        .collection('cardapios')
        .doc(idCardapio)
        .collection('itens')
        .doc(item.idItem)
        .update({'confirmado': !item.confirmado});
  }

  Future<void> excluirItem(String idCardapio, String idItem) async {
    await _db.collection('cardapios').doc(idCardapio).collection('itens').doc(idItem).delete();
  }

  List<CardapioItemModel> itensDoCardapio(String idCardapio) {
    return List.unmodifiable(itensPorCardapio[idCardapio] ?? const []);
  }

  int totalItensDoCardapio(String idCardapio) {
    final itens = itensPorCardapio[idCardapio];
    if (itens != null) return itens.length;

    final cardapio = cardapioPorId(idCardapio);
    return cardapio?.totalItens ?? 0;
  }

  int totalComidasDoCardapio(String idCardapio) {
    final itens = itensPorCardapio[idCardapio];
    if (itens != null) {
      return itens.where((i) => _tipoEhComida(i.tipo)).length;
    }

    final cardapio = cardapioPorId(idCardapio);
    return cardapio?.totalComidas ?? 0;
  }

  bool _tipoEhComida(dynamic tipo) {
    final normalizado = _normalizarTexto(_valorEnumOuTexto(tipo));

    return normalizado == 'comida' || normalizado == 'bolo';
  }

  int totalBebidasDoCardapio(String idCardapio) {
    final itens = itensPorCardapio[idCardapio];
    if (itens != null) {
      return itens.where((i) => _tipoEh(i.tipo, 'bebida')).length;
    }

    final cardapio = cardapioPorId(idCardapio);
    return cardapio?.totalBebidas ?? 0;
  }

  int totalSobremesasDoCardapio(String idCardapio) {
    final itens = itensPorCardapio[idCardapio];
    if (itens != null) {
      return itens.where((i) => _tipoEh(i.tipo, 'sobremesa')).length;
    }

    final cardapio = cardapioPorId(idCardapio);
    return cardapio?.totalSobremesas ?? 0;
  }

  int get totalCardapios => cardapios.length;

  int get totalItens {
    if (itensPorCardapio.isNotEmpty) {
      return itensPorCardapio.values.fold(0, (soma, itens) => soma + itens.length);
    }

    return cardapios.fold(0, (soma, cardapio) => soma + cardapio.totalItens);
  }

  int get totalComidas {
    if (itensPorCardapio.isNotEmpty) {
      return itensPorCardapio.values.fold(
        0,
        (soma, itens) => soma + itens.where((i) => _tipoEhComida(i.tipo)).length,
      );
    }

    return cardapios.fold(0, (soma, cardapio) => soma + cardapio.totalComidas);
  }

  int get totalBebidas {
    if (itensPorCardapio.isNotEmpty) {
      return itensPorCardapio.values.fold(
        0,
        (soma, itens) => soma + itens.where((i) => _tipoEh(i.tipo, 'bebida')).length,
      );
    }

    return cardapios.fold(0, (soma, cardapio) => soma + cardapio.totalBebidas);
  }

  int get totalSobremesas {
    if (itensPorCardapio.isNotEmpty) {
      return itensPorCardapio.values.fold(
        0,
        (soma, itens) => soma + itens.where((i) => _tipoEh(i.tipo, 'sobremesa')).length,
      );
    }

    return cardapios.fold(0, (soma, cardapio) => soma + cardapio.totalSobremesas);
  }

  Future<void> _sincronizarResumoCardapio(
    String idCardapio,
    List<CardapioItemModel> itens,
  ) async {
    final totalItens = itens.length;
    final totalComidas = itens.where((i) => _tipoEhComida(i.tipo)).length;
    final totalBebidas = itens.where((i) => _tipoEh(i.tipo, 'bebida')).length;
    final totalSobremesas = itens.where((i) => _tipoEh(i.tipo, 'sobremesa')).length;

    final atual = cardapioPorId(idCardapio);

    final resumoJaEstaAtualizado = atual != null &&
        atual.totalItens == totalItens &&
        atual.totalComidas == totalComidas &&
        atual.totalBebidas == totalBebidas &&
        atual.totalSobremesas == totalSobremesas;

    if (resumoJaEstaAtualizado) return;

    await _db.collection('cardapios').doc(idCardapio).set(
      {
        'total_itens': totalItens,
        'total_comidas': totalComidas,
        'total_bebidas': totalBebidas,
        'total_sobremesas': totalSobremesas,
      },
      SetOptions(merge: true),
    );
  }

  CardapioModel? cardapioPorId(String idCardapio) {
    for (final cardapio in cardapios) {
      if (cardapio.idCardapio == idCardapio) return cardapio;
    }

    return null;
  }

  String? _idEventoPorCardapio(String idCardapio) {
    return cardapioPorId(idCardapio)?.idEvento;
  }

  bool _tipoEh(dynamic tipo, String esperado) {
    return _normalizarTexto(_valorEnumOuTexto(tipo)) == _normalizarTexto(esperado);
  }

  String _valorEnumOuTexto(dynamic value) {
    if (value == null) return '';

    try {
      final dynamic dynamicValue = value;
      final firestoreValue = dynamicValue.firestoreValue;

      if (firestoreValue != null) {
        return firestoreValue.toString();
      }
    } catch (_) {
      // Mantém compatibilidade com String ou enum simples.
    }

    try {
      final dynamic dynamicValue = value;
      final enumName = dynamicValue.name;

      if (enumName != null) {
        return enumName.toString();
      }
    } catch (_) {
      // Mantém compatibilidade com String.
    }

    final text = value.toString();
    return text.contains('.') ? text.split('.').last : text;
  }

  String _normalizarTexto(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  Future<void> _cancelarEscutas() async {
    await _cardapiosSubscription?.cancel();
    _cardapiosSubscription = null;

    for (final subscription in _itensSubscriptions.values) {
      await subscription.cancel();
    }

    _itensSubscriptions.clear();
  }

  @override
  void onClose() {
    _cardapiosSubscription?.cancel();

    for (final subscription in _itensSubscriptions.values) {
      subscription.cancel();
    }

    _itensSubscriptions.clear();
    super.onClose();
  }
}
