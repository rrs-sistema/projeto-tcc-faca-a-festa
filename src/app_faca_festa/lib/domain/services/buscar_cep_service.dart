import '../entities/endereco_cep_resultado.dart';

class BuscarCepException implements Exception {
  final String mensagem;
  final int? statusCode;

  const BuscarCepException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

abstract class BuscarCepService {
  Future<EnderecoCepResultado> buscar({required String cep});
}
