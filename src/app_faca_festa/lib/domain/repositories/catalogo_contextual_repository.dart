import '../entities/referencia_contextual.dart';

/// Extensão do repositório do catálogo atual, sem uma coleção concorrente.
abstract class CatalogoContextualRepository {
  Future<CatalogoContextual> carregarCatalogoContextual();
  Future<ReferenciaContextual?> carregarReferencia(String id);
  Future<void> salvarRascunhoReferencia(
      ReferenciaContextual referencia, int revisaoEsperada);
  Future<ReferenciaContextual> publicarReferencia(
      ReferenciaContextual referencia, int versaoEsperada, String pedido);
}

abstract class GovernancaCatalogoRepository {
  Future<void> aprovarReferencia(
      ReferenciaContextual referencia, int versaoEsperada, String pedido);
  Future<void> selecionarVersao(
      String id, int versaoEsperada, int? versaoAlvo, String pedido);
}
