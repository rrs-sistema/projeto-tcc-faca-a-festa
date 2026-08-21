import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CallableHttpsException implements Exception {
  const CallableHttpsException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => message?.trim().isNotEmpty == true
      ? '$code: $message'
      : code;
}

/// Chamada `onCall` por HTTP. No Windows o plugin `cloud_functions` falha
/// (`CloudFunctionsHostApi.call`); este cliente usa a URL da function v2.
class CallableHttpsClient {
  CallableHttpsClient({
    http.Client? client,
    this.regiao = 'southamerica-east1',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String regiao;
  static const Duration _timeout = Duration(seconds: 30);

  static bool get necessarioNaPlataformaAtual {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows;
  }

  Future<Map<String, dynamic>> call(
    String nomeFunction, [
    Map<String, dynamic>? data,
    Duration? timeout,
  ]) async {
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) {
      throw const CallableHttpsException(
        'unauthenticated',
        'Faça login para continuar.',
      );
    }

    final token = await usuario.getIdToken();
    if (token == null || token.isEmpty) {
      throw const CallableHttpsException(
        'unauthenticated',
        'Faça login para continuar.',
      );
    }

    final projectId = Firebase.apps.isNotEmpty
        ? Firebase.app().options.projectId
        : 'faca-a-festa';
    final uri = Uri.parse(
      'https://$regiao-$projectId.cloudfunctions.net/$nomeFunction',
    );

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'data': data ?? <String, dynamic>{}}),
        )
        .timeout(timeout ?? _timeout);

    final body = _decodificar(response.body);
    final error = body['error'];
    if (error is Map) {
      throw CallableHttpsException(
        _codigoDeStatus(error['status']?.toString()),
        error['message']?.toString(),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CallableHttpsException(
        response.statusCode == 401 ? 'unauthenticated' : 'internal',
        'Não foi possível concluir a verificação.',
      );
    }

    final result = body['result'];
    if (result is Map<String, dynamic>) return result;
    if (result is Map) {
      return result.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
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

  String _codigoDeStatus(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'UNAUTHENTICATED':
        return 'unauthenticated';
      case 'INVALID_ARGUMENT':
        return 'invalid-argument';
      case 'PERMISSION_DENIED':
        return 'permission-denied';
      case 'RESOURCE_EXHAUSTED':
        return 'resource-exhausted';
      case 'DEADLINE_EXCEEDED':
        return 'deadline-exceeded';
      case 'FAILED_PRECONDITION':
        return 'failed-precondition';
      case 'NOT_FOUND':
        return 'not-found';
      default:
        return 'internal';
    }
  }
}
