import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../models/auditoria/auditoria_evento_model.dart';
import '../../services/functions/callable_https_client.dart';
import '../../../domain/entities/auditoria_evento.dart';

class AuditoriaRemoteDatasource {
  AuditoriaRemoteDatasource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    CallableHttpsClient? httpsClient,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
        _https = httpsClient ?? CallableHttpsClient();

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final CallableHttpsClient _https;

  Future<String> registrar(RegistroAuditoria registro) async {
    final payload = <String, dynamic>{
      'acao': registro.acao,
      'resumo': registro.resumo,
      'entidadeTipo': registro.entidadeTipo,
      'entidadeId': registro.entidadeId,
      'entidadeNome': registro.entidadeNome,
      'idFornecedor': registro.idFornecedor,
      'idEvento': registro.idEvento,
      'idServico': registro.idServico,
      'idCotacao': registro.idCotacao,
      'idOrcamento': registro.idOrcamento,
      'mudancas': registro.mudancas.map((m) => m.toMap()).toList(),
      'detalhe': registro.detalhe,
      'plataforma': registro.plataforma ?? _plataformaAtual(),
      'rota': registro.rota,
      'criadoEmLocal': DateTime.now().toUtc().toIso8601String(),
    };

    final data = await _chamarFunction('registrarAuditoria', payload);
    return (data['id'] ?? '').toString();
  }

  Future<List<AuditoriaEventoModel>> listar(AuditoriaConsulta consulta) async {
    Query<Map<String, dynamic>> query = _db.collection('auditoria_eventos');

    if (!consulta.escopoAdmin) {
      final idFornecedor = (consulta.idFornecedor ?? '').trim();
      if (idFornecedor.isEmpty) return const [];
      query = query
          .where('id_fornecedor', isEqualTo: idFornecedor)
          .where('visivel_fornecedor', isEqualTo: true);
    }

    final snapshot = await query
        .orderBy('criado_em', descending: true)
        .limit(consulta.limite)
        .get();

    return snapshot.docs
        .map((doc) => AuditoriaEventoModel.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<Map<String, dynamic>> _chamarFunction(
    String nome,
    Map<String, dynamic> data,
  ) async {
    if (CallableHttpsClient.necessarioNaPlataformaAtual) {
      return _https.call(nome, data);
    }

    final callable = _functions.httpsCallable(
      nome,
      options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
    );
    final resultado = await callable.call(data);
    final payload = resultado.data;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  String _plataformaAtual() {
    if (kIsWeb) return 'WEB';
    return defaultTargetPlatform.name.toUpperCase();
  }
}
