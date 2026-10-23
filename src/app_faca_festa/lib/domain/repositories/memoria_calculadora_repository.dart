abstract interface class MemoriaCalculadoraRepository {
  Future<List<Map<String, dynamic>>> lerMemoriaCalculadora();
  Future<void> gravarMemoriaCalculadora(List<Map<String, dynamic>> receitas,
      {required List<Map<String, dynamic>> anteriores});
}
