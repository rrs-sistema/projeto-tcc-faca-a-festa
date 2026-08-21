import '../../data/models/calculadora/calculadora_evento_item_model.dart';
import '../../data/models/calculadora/calculadora_item_base_model.dart';

abstract class CalculadoraItensBaseRepositoryContract {
  Future<List<CalculadoraItemBaseModel>> listarItensBase();

  Future<List<CalculadoraEventoItemModel>> listarItensEvento();

  Future<List<CalculadoraItemBaseModel>> listarItensBaseAtivos();

  Future<List<CalculadoraEventoItemModel>> listarItensEventoAtivos();

  Future<List<CalculadoraEventoItemModel>> buscarItensPorTipoEvento({
    required String tipoEvento,
    String? perfilFesta,
  });

  Future<List<CalculadoraEventoItemModel>> buscarItensPorTipoEventoComFallback({
    required String tipoEvento,
    String? perfilFesta,
  });

  Future<CalculadoraEventoItemModel?> buscarItemEventoPorId(String id);

  Future<void> salvarItemBase(CalculadoraItemBaseModel item);

  Future<void> salvarItemEvento(CalculadoraEventoItemModel item);

  Future<void> ativarDesativarItemBase(String id, bool ativo);

  Future<void> ativarDesativarItemEvento(String id, bool ativo);
}
