import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'package:app_faca_festa/domain/entities/calculadora_item_base.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';

import '../../datasources/remote/calculadora_itens_base_remote_datasource.dart';

class CalculadoraItensBaseRepositoryImpl
    implements CalculadoraItensBaseRepositoryContract {
  CalculadoraItensBaseRepositoryImpl(this.remote);

  final CalculadoraItensBaseRemoteDatasource remote;

  @override
  Future<List<CalculadoraItemBase>> listarItensBase() {
    return remote.listarItensBase();
  }

  @override
  Future<List<CalculadoraEventoItem>> listarItensEvento() {
    return remote.listarItensEvento();
  }

  @override
  Future<List<CalculadoraItemBase>> listarItensBaseAtivos() {
    return remote.listarItensBaseAtivos();
  }

  @override
  Future<List<CalculadoraEventoItem>> listarItensEventoAtivos() {
    return remote.listarItensEventoAtivos();
  }

  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEvento({
    required String tipoEvento,
    String? perfilFesta,
  }) {
    return remote.buscarItensPorTipoEvento(
      tipoEvento: tipoEvento,
      perfilFesta: perfilFesta,
    );
  }

  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback({
    required String tipoEvento,
    String? perfilFesta,
  }) {
    return remote.buscarItensPorTipoEventoComFallback(
      tipoEvento: tipoEvento,
      perfilFesta: perfilFesta,
    );
  }

  @override
  Future<CalculadoraEventoItem?> buscarItemEventoPorId(String id) {
    return remote.buscarItemEventoPorId(id);
  }

  @override
  Future<void> salvarItemBase(CalculadoraItemBase item) {
    return remote.salvarItemBase(item);
  }

  @override
  Future<void> salvarItemEvento(CalculadoraEventoItem item) {
    return remote.salvarItemEvento(item);
  }

  @override
  Future<void> ativarDesativarItemBase(String id, bool ativo) {
    return remote.ativarDesativarItemBase(id, ativo);
  }

  @override
  Future<void> ativarDesativarItemEvento(String id, bool ativo) {
    return remote.ativarDesativarItemEvento(id, ativo);
  }
}
