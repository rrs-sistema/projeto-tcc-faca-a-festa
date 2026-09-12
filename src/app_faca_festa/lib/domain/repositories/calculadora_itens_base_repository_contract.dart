import '../entities/calculadora_evento_item.dart';
import '../entities/calculadora_item_base.dart';

abstract class CalculadoraItensBaseRepositoryContract {
  Future<List<CalculadoraItemBase>> listarItensBase();

  Future<List<CalculadoraEventoItem>> listarItensEvento();

  Future<List<CalculadoraItemBase>> listarItensBaseAtivos();

  Future<List<CalculadoraEventoItem>> listarItensEventoAtivos();

  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEvento({
    required String tipoEvento,
    String? perfilFesta,
  });

  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback({
    required String tipoEvento,
    String? perfilFesta,
  });

  Future<CalculadoraEventoItem?> buscarItemEventoPorId(String id);

  Future<void> salvarItemBase(CalculadoraItemBase item);

  Future<void> salvarItemEvento(CalculadoraEventoItem item);

  Future<void> ativarDesativarItemBase(String id, bool ativo);

  Future<void> ativarDesativarItemEvento(String id, bool ativo);
}
