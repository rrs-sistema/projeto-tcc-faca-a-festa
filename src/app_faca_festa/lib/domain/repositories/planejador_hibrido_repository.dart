abstract interface class PlanejadorHibridoRepository {
  Future<Map<String, dynamic>> sugerirCandidatosPlanejador(
      Map<String, dynamic> entrada);
  Future<Map<String, dynamic>> confirmarPlanejador(
      Map<String, dynamic> revisao);
}
