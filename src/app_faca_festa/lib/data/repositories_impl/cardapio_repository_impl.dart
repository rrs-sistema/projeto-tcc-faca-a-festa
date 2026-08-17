import '../../domain/entities/cardapio.dart';
import '../../domain/entities/cardapio_item.dart';
import '../../domain/repositories/cardapio_repository.dart';
import '../datasources/remote/cardapio_remote_datasource.dart';
import '../models/cardapio/cardapio_item_model.dart' hide CardapioItem;
import '../models/cardapio/cardapio_model.dart' hide Cardapio;

class CardapioRepositoryImpl implements CardapioRepository {
  CardapioRepositoryImpl(this.remote);

  final CardapioRemoteDatasource remote;

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
  Future<void> salvarCardapio(Cardapio cardapio) =>
      remote.salvarCardapio(_cardapioModel(cardapio));

  @override
  Future<void> excluirCardapio(String idCardapio) =>
      remote.excluirCardapio(idCardapio);

  @override
  Future<void> salvarItem(String idCardapio, CardapioItem item) =>
      remote.salvarItem(idCardapio, _itemModel(item));

  @override
  Future<void> alternarConfirmado(String idCardapio, CardapioItem item) =>
      remote.alternarConfirmado(idCardapio, _itemModel(item));

  @override
  Future<void> excluirItem(String idCardapio, String idItem) =>
      remote.excluirItem(idCardapio, idItem);

  @override
  Future<void> atualizarResumo(String idCardapio, ResumoCardapio resumo) =>
      remote.atualizarResumo(idCardapio, resumo);
}
