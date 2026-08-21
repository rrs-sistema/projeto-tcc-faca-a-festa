abstract interface class CepRepository {
  Future<Map<String, dynamic>?> buscarCep(String cep);
}
