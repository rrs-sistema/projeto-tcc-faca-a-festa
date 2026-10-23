import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';

class ComissaoPlataformaRemoteDatasource {
  ComissaoPlataformaRemoteDatasource({
    required FirebaseFunctions functions,
    CallableHttpsClient? httpsClient,
    FirebaseFirestore? firestore,
    FinanceiroCallableGateway? gateway,
  })  : _gateway = gateway ??
            FinanceiroCallableGateway(
              functions: functions,
              httpsClient: httpsClient,
            ),
        _db = firestore;

  final FinanceiroCallableGateway _gateway;
  final FirebaseFirestore? _db;

  Future<Map<String, dynamic>> salvarPolitica({
    required int percentualBps,
    bool ativa = false,
    String? idPolitica,
    String pagador = 'fornecedor',
    String reversao = 'proporcional',
    int diasVencimento = 30,
  }) {
    return _gateway.call('salvarPoliticaComissao', {
      if (idPolitica != null) 'idPolitica': idPolitica,
      'percentualBps': percentualBps,
      'ativa': ativa,
      'pagador': pagador,
      'reversao': reversao,
      'diasVencimentoAposGeracao': diasVencimento,
      'baseElegivel': 'servicos_contratados_plataforma',
      'gatilhoGeracao': 'contratacao_confirmada',
    });
  }

  Future<Map<String, dynamic>> ativarPolitica(String idPolitica) {
    return _gateway.call('ativarPoliticaComissao', {'idPolitica': idPolitica});
  }

  Future<Map<String, dynamic>> simular({
    int? percentualBps,
    String? idPolitica,
    required int baseBrutaCentavos,
    bool ativa = true,
  }) {
    return _gateway.call('simularComissaoPlataforma', {
      if (idPolitica != null) 'idPolitica': idPolitica,
      if (percentualBps != null) 'percentualBps': percentualBps,
      'baseBrutaCentavos': baseBrutaCentavos,
      'ativa': ativa,
    });
  }

  Future<Map<String, dynamic>> gerarObrigacao({
    required String idEvento,
    required String idContrato,
    required int baseBrutaCentavos,
    String? idPagador,
    String? idFornecedor,
  }) {
    return _gateway.call('gerarObrigacaoComissao', {
      'idEvento': idEvento,
      'idContrato': idContrato,
      'baseBrutaCentavos': baseBrutaCentavos,
      if (idPagador != null) 'idPagador': idPagador,
      if (idFornecedor != null) 'idFornecedor': idFornecedor,
    });
  }

  Future<Map<String, dynamic>> liquidarManual({
    required String idObrigacao,
    required int valorCentavos,
    String? motivo,
  }) {
    return _gateway.call('liquidarComissaoManual', {
      'idObrigacao': idObrigacao,
      'valorCentavos': valorCentavos,
      if (motivo != null) 'motivo': motivo,
    });
  }

  Future<Map<String, dynamic>> registrarAjuste({
    required String idObrigacao,
    required int reducaoBaseCentavos,
    String? motivo,
  }) {
    return _gateway.call('registrarAjusteComissao', {
      'idObrigacao': idObrigacao,
      'reducaoBaseCentavos': reducaoBaseCentavos,
      if (motivo != null) 'motivo': motivo,
    });
  }

  /// Extrato via callable; se indisponível, lê Firestore autorizado (fallback).
  Future<Map<String, dynamic>> consultarExtrato({
    String? idEvento,
    String? idPagador,
    bool ehAdmin = false,
  }) async {
    try {
      return await _gateway.call('consultarExtratoComissao', {
        if (idEvento != null && idEvento.isNotEmpty) 'idEvento': idEvento,
        if (idPagador != null && idPagador.isNotEmpty) 'idPagador': idPagador,
      });
    } on FinanceiroCallableException catch (e) {
      if (!e.podeUsarFallbackLocal || _db == null) rethrow;
      return _extratoLocal(
        idEvento: idEvento,
        idPagador: idPagador,
        ehAdmin: ehAdmin,
      );
    }
  }

  Future<Map<String, dynamic>> _extratoLocal({
    String? idEvento,
    String? idPagador,
    bool ehAdmin = false,
  }) async {
    final db = _db!;
    Query<Map<String, dynamic>> q =
        db.collection('plataforma_comissao_obrigacoes');
    if (!ehAdmin) {
      final pagador = (idPagador ?? '').trim();
      if (pagador.isEmpty) {
        return {
          'ok': true,
          'modo': 'pagador',
          'obrigacoes': <Map<String, dynamic>>[],
          'politicas': <Map<String, dynamic>>[],
          'origem': 'fallback_local',
        };
      }
      q = q.where('id_pagador', isEqualTo: pagador);
    }
    if (idEvento != null && idEvento.isNotEmpty) {
      q = q.where('id_evento', isEqualTo: idEvento);
    }
    final obrSnap = await q.limit(100).get();
    final politicas = <Map<String, dynamic>>[];
    if (ehAdmin) {
      final polSnap =
          await db.collection('plataforma_comissao_politicas').limit(20).get();
      for (final d in polSnap.docs) {
        politicas.add({'id': d.id, ...d.data()});
      }
    }
    return {
      'ok': true,
      'modo': ehAdmin ? 'admin' : 'pagador',
      'obrigacoes': obrSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      'politicas': politicas,
      'origem': 'fallback_local',
    };
  }
}
