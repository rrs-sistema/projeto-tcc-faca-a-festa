import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/calculadora_evento_item.dart';
import 'package:app_faca_festa/domain/entities/calculadora_item_base.dart';
import 'package:app_faca_festa/domain/repositories/calculadora_itens_base_repository_contract.dart';
import 'package:app_faca_festa/domain/repositories/catalogo_contextual_repository.dart';
import 'package:app_faca_festa/domain/entities/referencia_contextual.dart';

import '../../datasources/remote/calculadora_itens_base_remote_datasource.dart';

class CalculadoraItensBaseRepositoryImpl
    implements
        CalculadoraItensBaseRepositoryContract,
        CatalogoContextualRepository,
        GovernancaCatalogoRepository {
  CalculadoraItensBaseRepositoryImpl(this.remote);

  final CalculadoraItensBaseRemoteDatasource remote;

  @override
  Future<CatalogoContextual> carregarCatalogoContextual() =>
      remote.carregarCatalogoContextual();
  @override
  Future<ReferenciaContextual?> carregarReferencia(String id) =>
      remote.carregarReferencia(id);
  @override
  Future<void> salvarRascunhoReferencia(
      ReferenciaContextual r, int esperada) async {
    await remote.editarReferencia(r, esperada, 'rascunho');
  }

  @override
  Future<ReferenciaContextual> publicarReferencia(
          ReferenciaContextual r, int esperada, String pedido) =>
      _aprovarPublicar(r, esperada, pedido);

  Future<ReferenciaContextual> _aprovarPublicar(
      ReferenciaContextual r, int esperada, String pedido) async {
    // Compatibilidade da ação antiga "publicar versão aprovada": ambas as
    // confirmações são remotas e auditadas; nunca basta mutação em memória.
    final usuario = remote.usuarioAtual;
    await aprovarReferencia(r, esperada, '${pedido}_aprovar');
    if (usuario == null || usuario != remote.usuarioAtual) {
      throw StateError('A sessão mudou. Reabra a revisão editorial.');
    }
    return remote.editarReferencia(r, esperada, 'publicar', pedido: pedido);
  }

  @override
  Future<void> aprovarReferencia(
      ReferenciaContextual r, int esperada, String pedido) async {
    await remote.editarReferencia(r, esperada, 'aprovar', pedido: pedido);
  }

  @override
  Future<void> selecionarVersao(
          String id, int esperada, int? alvo, String pedido) =>
      remote.selecionarVersao(id, esperada, alvo, pedido);

  @override
  Future<List<CalculadoraItemBase>> listarItensBase() {
    return UpdateOperations.run(() async {
      return remote.listarItensBase();
    });
  }

  @override
  Future<List<CalculadoraEventoItem>> listarItensEvento() {
    return UpdateOperations.run(() async {
      return remote.listarItensEvento();
    });
  }

  @override
  Future<List<CalculadoraItemBase>> listarItensBaseAtivos() {
    return UpdateOperations.run(() async {
      return remote.listarItensBaseAtivos();
    });
  }

  @override
  Future<List<CalculadoraEventoItem>> listarItensEventoAtivos() {
    return UpdateOperations.run(() async {
      return remote.listarItensEventoAtivos();
    });
  }

  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEvento({
    required String tipoEvento,
    String? perfilFesta,
  }) {
    return UpdateOperations.run(() async {
      return remote.buscarItensPorTipoEvento(
        tipoEvento: tipoEvento,
        perfilFesta: perfilFesta,
      );
    });
  }

  @override
  Future<List<CalculadoraEventoItem>> buscarItensPorTipoEventoComFallback({
    required String tipoEvento,
    String? perfilFesta,
  }) {
    return UpdateOperations.run(() async {
      return remote.buscarItensPorTipoEventoComFallback(
        tipoEvento: tipoEvento,
        perfilFesta: perfilFesta,
      );
    });
  }

  @override
  Future<CalculadoraEventoItem?> buscarItemEventoPorId(String id) {
    return UpdateOperations.run(() async {
      return remote.buscarItemEventoPorId(id);
    });
  }

  @override
  Future<void> salvarItemBase(CalculadoraItemBase item) {
    return UpdateOperations.run(() async {
      return remote.salvarItemBase(item);
    });
  }

  @override
  Future<void> salvarItemEvento(CalculadoraEventoItem item) {
    return UpdateOperations.run(() async {
      return remote.salvarItemEvento(item);
    });
  }

  @override
  Future<void> ativarDesativarItemBase(String id, bool ativo) {
    return UpdateOperations.run(() async {
      return remote.ativarDesativarItemBase(id, ativo);
    });
  }

  @override
  Future<void> ativarDesativarItemEvento(String id, bool ativo) {
    return UpdateOperations.run(() async {
      return remote.ativarDesativarItemEvento(id, ativo);
    });
  }
}
