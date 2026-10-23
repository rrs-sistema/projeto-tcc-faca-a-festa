import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/cardapio/cardapio_item_model.dart';
import '../../models/cardapio/cardapio_model.dart';
import 'package:app_faca_festa/domain/repositories/cardapio_repository.dart';
import '../../../domain/services/criacao_cardapio_inicial_service.dart';
import '../../models/evento/calculadora_festa_model.dart';
import '../../models/evento/calculadora_festa_item_model.dart';

class CardapioRemoteDatasource {
  CardapioRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _cardapios =>
      firestore.collection('cardapios');

  Future<bool> criarCardapioInicial(CriacaoCardapioInicial proposta) async {
    final menu = proposta.cardapio;
    if (menu.idCardapio !=
            CriacaoCardapioInicialService.identidade(menu.idEvento) ||
        proposta.calculo.idCalculo != menu.idCardapio ||
        proposta.calculo.idEvento != menu.idEvento ||
        proposta.itens.isEmpty ||
        proposta.itens.length > 40 ||
        proposta.calculo.idUsuario == null ||
        proposta.calculo.idUsuario!.isEmpty ||
        proposta.resultados.length != proposta.itens.length ||
        proposta.resultados.any((r) =>
            r.idEvento != menu.idEvento ||
            r.idCardapio != menu.idCardapio ||
            r.idCalculo != proposta.calculo.idCalculo ||
            !r.adicionadoAoCardapio ||
            r.adicionadoAoOrcamento) ||
        proposta.itens.any((i) =>
            i.idEvento != menu.idEvento ||
            i.idCardapio != menu.idCardapio ||
            i.quantidadeFinal != 0 ||
            i.confirmado ||
            i.disponibilidade != null)) {
      throw StateError('A criação inicial contém dados incompatíveis.');
    }
    final parent = _cardapios.doc(menu.idCardapio);
    final simulacao = firestore
        .collection('calculadora_festa')
        .doc(proposta.calculo.idCalculo);
    return firestore.runTransaction<bool>((tx) async {
      final evento =
          await tx.get(firestore.collection('evento').doc(menu.idEvento));
      final anterior = await tx.get(parent);
      final historico = await tx.get(simulacao);
      if (!evento.exists) throw StateError('O evento não existe mais.');
      if (anterior.exists) {
        final dados = anterior.data()!;
        if (dados['id_evento'] != menu.idEvento ||
            dados['origem_plano_inicial'] != 1 ||
            !historico.exists ||
            historico.data()?['id_evento'] != menu.idEvento ||
            historico.data()?['id_usuario'] != proposta.calculo.idUsuario) {
          throw StateError(
              'Já existem dados nesse destino. Nenhum registro foi substituído.');
        }
        return false;
      }
      if (historico.exists) {
        throw StateError(
            'Há uma simulação anterior sem cardápio. Confira o histórico antes de criar novamente.');
      }
      for (final item in proposta.itens) {
        if ((await tx.get(parent.collection('itens').doc(item.idItem)))
            .exists) {
          throw StateError(
              'Há itens anteriores sem cardápio. Confira os dados antes de criar.');
        }
      }
      tx.set(parent, {
        ...CardapioModel.fromEntity(menu).toMap(),
        'origem_plano_inicial': 1
      });
      for (final item in proposta.itens) {
        tx.set(parent.collection('itens').doc(item.idItem),
            CardapioItemModel.fromEntity(item).toMap());
      }
      tx.set(simulacao,
          CalculadoraFestaModel.fromEntity(proposta.calculo).toMap());
      for (final resultado in proposta.resultados) {
        tx.set(simulacao.collection('itens').doc(resultado.idItemResultado),
            CalculadoraFestaItemModel.fromEntity(resultado).toMap());
      }
      return true;
    });
  }

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
