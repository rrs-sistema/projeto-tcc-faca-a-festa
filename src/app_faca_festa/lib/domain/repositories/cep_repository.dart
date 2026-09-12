import '../entities/endereco_cep_resultado.dart';

abstract interface class CepRepository {
  Future<EnderecoCepResultado?> buscarCep(String cep);
}
