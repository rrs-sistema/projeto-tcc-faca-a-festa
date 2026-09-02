import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/cep_repository.dart';

class ViaCepRepositoryImpl implements CepRepository {
  ViaCepRepositoryImpl({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Map<String, dynamic>?> buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');
    if (cepLimpo.length != 8) return null;

    final url = Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/');
    final response = await _client.get(url);

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;

    final data = decoded.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    if (data['erro'] == true) return null;

    return data;
  }
}
