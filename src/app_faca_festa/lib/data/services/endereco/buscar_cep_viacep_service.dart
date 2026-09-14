import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'package:app_faca_festa/data/models/endereco/endereco_cep_resultado.dart';
import 'package:app_faca_festa/domain/entities/endereco_cep_resultado.dart';
import 'package:app_faca_festa/domain/services/buscar_cep_service.dart';

/// Adapter HTTP de `viacep.com.br`. Não entra no DI de produção — o cadastro
/// e o perfil usam [BuscarCepGoogleService] (function com cache Maps).
class BuscarCepViaCepService implements BuscarCepService {
  BuscarCepViaCepService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<EnderecoCepResultado> buscar({required String cep}) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');
    if (cepLimpo.length != 8) {
      throw const BuscarCepException('Informe um CEP válido com 8 dígitos.');
    }

    try {
      final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
      final response = await _client.get(url);

      if (response.statusCode != 200) {
        throw BuscarCepException(
          'Não foi possível consultar o CEP.',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const BuscarCepException('Não foi possível consultar o CEP.');
      }

      final data = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      if (data['erro'] == true) {
        throw const BuscarCepException('CEP não encontrado.');
      }

      return EnderecoCepResultadoModel.fromViaCep({
        ...data,
        'cep': data['cep'] ?? cepLimpo,
      });
    } on BuscarCepException {
      rethrow;
    } catch (e, s) {
      developer.log(
        'Falha ao consultar CEP',
        name: 'BuscarCepViaCepService',
        error: e,
        stackTrace: s,
      );
      throw const BuscarCepException(
        'Falha ao consultar o CEP. Tente novamente.',
      );
    }
  }
}
