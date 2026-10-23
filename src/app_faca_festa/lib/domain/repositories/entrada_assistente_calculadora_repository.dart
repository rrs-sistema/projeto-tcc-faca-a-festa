abstract interface class EntradaAssistenteCalculadoraRepository {
  Future<Map<String, dynamic>> interpretarEntradaCalculadora(
      Map<String, dynamic> entrada);
  Future<Map<String, dynamic>> aplicarEntradaCalculadora(
      Map<String, dynamic> revisao);
}
