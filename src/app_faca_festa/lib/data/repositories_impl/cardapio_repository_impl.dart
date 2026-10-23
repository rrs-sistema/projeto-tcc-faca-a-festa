import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/cardapio.dart';
import 'package:app_faca_festa/domain/entities/cardapio_item.dart';
import 'package:app_faca_festa/domain/repositories/cardapio_repository.dart';
import '../datasources/remote/cardapio_remote_datasource.dart';
import '../models/cardapio/cardapio_item_model.dart';
import '../models/cardapio/cardapio_model.dart';
import '../../domain/services/criacao_cardapio_inicial_service.dart';

class CardapioRepositoryImpl
    implements CardapioRepository, CriacaoCardapioInicialRepository {
  CardapioRepositoryImpl(this.remote);

  final CardapioRemoteDatasource remote;

  @override
  Future<bool> criarCardapioInicial(CriacaoCardapioInicial proposta) =>
      UpdateOperations.run(() => remote.criarCardapioInicial(proposta));

  @override
  Stream<List<Cardapio>> observarCardapios(String idEvento) =>
      remote.observarCardapios(idEvento);

  @override
  Stream<List<CardapioItem>> observarItens(
    String idCardapio, {
    String? idEvento,
  }) =>
      remote.observarItens(idCardapio, idEvento: idEvento);

  CardapioModel _cardapioModel(Cardapio cardapio) =>
      cardapio is CardapioModel ? cardapio : CardapioModel.fromEntity(cardapio);

  CardapioItemModel _itemModel(CardapioItem item) =>
      item is CardapioItemModel ? item : CardapioItemModel.fromEntity(item);

  @override
  Future<void> salvarCardapio(Cardapio cardapio) {
    return UpdateOperations.run(() async {
      return remote.salvarCardapio(_cardapioModel(cardapio));
    });
  }

  @override
  Future<void> excluirCardapio(String idCardapio) {
    return UpdateOperations.run(() async {
      return remote.excluirCardapio(idCardapio);
    });
  }

  @override
  Future<void> salvarItem(String idCardapio, CardapioItem item) {
    return UpdateOperations.run(() async {
      return remote.salvarItem(idCardapio, _itemModel(item));
    });
  }

  @override
  Future<void> alternarConfirmado(String idCardapio, CardapioItem item) {
    return UpdateOperations.run(() async {
      return remote.alternarConfirmado(idCardapio, _itemModel(item));
    });
  }

  @override
  Future<void> excluirItem(String idCardapio, String idItem) {
    return UpdateOperations.run(() async {
      return remote.excluirItem(idCardapio, idItem);
    });
  }

  @override
  Future<void> atualizarResumo(String idCardapio, ResumoCardapio resumo) {
    return UpdateOperations.run(() async {
      return remote.atualizarResumo(idCardapio, resumo);
    });
  }
}
