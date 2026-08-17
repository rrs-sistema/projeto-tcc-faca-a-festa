import '../entities/cardapio.dart';
import '../entities/cardapio_item.dart';

class ResumoCardapio {
  final int totalItens;
  final int totalComidas;
  final int totalBebidas;
  final int totalSobremesas;

  const ResumoCardapio({
    required this.totalItens,
    required this.totalComidas,
    required this.totalBebidas,
    required this.totalSobremesas,
  });
}

abstract interface class CardapioRepository {
  Stream<List<Cardapio>> observarCardapios(String idEvento);

  Stream<List<CardapioItem>> observarItens(
    String idCardapio, {
    String? idEvento,
  });

  Future<void> salvarCardapio(Cardapio cardapio);

  Future<void> excluirCardapio(String idCardapio);

  Future<void> salvarItem(String idCardapio, CardapioItem item);

  Future<void> alternarConfirmado(String idCardapio, CardapioItem item);

  Future<void> excluirItem(String idCardapio, String idItem);

  Future<void> atualizarResumo(String idCardapio, ResumoCardapio resumo);
}
