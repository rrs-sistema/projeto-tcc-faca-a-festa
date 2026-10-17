import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import 'functions/callable_https_client.dart';

class EstatisticasPublicas {
  const EstatisticasPublicas({
    required this.totalEventos,
    required this.totalAvaliacoes,
    required this.mediaFornecedores,
  });

  final int totalEventos;
  final int totalAvaliacoes;
  final double? mediaFornecedores;

  factory EstatisticasPublicas.fromMap(Map<String, dynamic> data) {
    return EstatisticasPublicas(
      totalEventos: (data['totalEventos'] as num).toInt(),
      totalAvaliacoes: (data['totalAvaliacoes'] as num).toInt(),
      mediaFornecedores: (data['mediaFornecedores'] as num?)?.toDouble(),
    );
  }
}

class EstatisticasPublicasService {
  static Future<EstatisticasPublicas?> carregar() async {
    if (Firebase.apps.isEmpty) return null;
    final httpClient = http.Client();
    try {
      final client =
          CallableHttpsClient(auth: FirebaseAuth.instance, client: httpClient);
      final data = await client.callPublic('obterEstatisticasPublicas');
      return EstatisticasPublicas.fromMap(data);
    } catch (_) {
      // Sem estatísticas confirmadas, a tela não apresenta números.
      return null;
    } finally {
      httpClient.close();
    }
  }
}
