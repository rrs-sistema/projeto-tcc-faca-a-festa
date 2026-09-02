import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/endereco/endereco_cep_resultado.dart';

class BuscarCepException implements Exception {
  final String mensagem;
  final int? statusCode;

  const BuscarCepException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

/// Cliente HTTP da function `buscarCepGoogle` (onRequest, southamerica-east1).
///
/// Usada no cadastro, ainda sem sessão Firebase — por isso não depende de
/// `httpsCallable`.
class BuscarCepGoogleService {
  static const String _regiao = 'southamerica-east1';
  static const String _nomeFunction = 'buscarCepGoogle';
  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;

  BuscarCepGoogleService({http.Client? client})
      : _client = client ?? http.Client();

  Uri get _uri {
    final projectId = Firebase.apps.isNotEmpty
        ? Firebase.app().options.projectId
        : 'faca-a-festa';
    return Uri.parse(
      'https://$_regiao-$projectId.cloudfunctions.net/$_nomeFunction',
    );
  }

  Future<EnderecoCepResultado> buscar({required String cep}) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');
    if (cepLimpo.length != 8) {
      throw const BuscarCepException('Informe um CEP válido com 8 dígitos.');
    }

    try {
      final response = await _client
          .post(
            _uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'cep': cepLimpo}),
          )
          .timeout(_timeout);

      final body = _decodificar(response.body);

      if (response.statusCode == 200 && body['sucesso'] == true) {
        return EnderecoCepResultado.fromMap(body);
      }

      throw BuscarCepException(
        _texto(body['mensagem']).isNotEmpty
            ? _texto(body['mensagem'])
            : 'Não foi possível consultar o CEP.',
        statusCode: response.statusCode,
      );
    } on BuscarCepException {
      rethrow;
    } catch (e, s) {
      debugPrint('[BuscarCepGoogleService] falha: $e');
      debugPrint('$s');
      throw const BuscarCepException(
        'Falha ao consultar o CEP. Tente novamente.',
      );
    }
  }

  Map<String, dynamic> _decodificar(String raw) {
    if (raw.trim().isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  String _texto(dynamic value) => (value ?? '').toString().trim();
}
