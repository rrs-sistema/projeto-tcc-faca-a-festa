import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';
import 'package:app_faca_festa/domain/entities/financeiro/dashboard_financeiro_admin.dart';
import 'package:app_faca_festa/domain/services/dashboard_financeiro_admin_service.dart';

class DashboardFinanceiroAdminRemote {
  DashboardFinanceiroAdminRemote({
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

  Future<Map<String, dynamic>> consultar({
    String eixoTemporal = 'data_evento',
    String? periodoInicio,
    String? periodoFim,
    String? idFornecedor,
    String? estado,
    int? despesasPlataformaCentavos,
  }) async {
    late final FinanceiroCallableException falhaCallable;
    try {
      return await _gateway.call('consultarDashboardFinanceiroAdmin', {
        'eixoTemporal': eixoTemporal,
        if (periodoInicio != null) 'periodoInicio': periodoInicio,
        if (periodoFim != null) 'periodoFim': periodoFim,
        if (idFornecedor != null && idFornecedor.isNotEmpty)
          'idFornecedor': idFornecedor,
        if (estado != null && estado.isNotEmpty) 'estado': estado,
        if (despesasPlataformaCentavos != null)
          'despesasPlataformaCentavos': despesasPlataformaCentavos,
      });
    } on FinanceiroCallableException catch (e) {
      if (!e.podeUsarFallbackLocal || _db == null) rethrow;
      falhaCallable = e;
    } catch (e) {
      // Plugin/web às vezes empacota 404/HTML fora do tipo tipado.
      if (_db == null || !_pareceIndisponivel(e)) rethrow;
      falhaCallable = FinanceiroCallableException(
        'unavailable',
        e.toString(),
      );
    }

    try {
      final local = await _consultarLocal(
        eixoTemporal: eixoTemporal,
        idFornecedor: idFornecedor,
        estado: estado,
        despesasPlataformaCentavos: despesasPlataformaCentavos,
      );
      final msg = (falhaCallable.message ?? '').trim();
      return {
        ...local,
        'aviso': msg.isNotEmpty
            ? msg
            : 'Consulta via function indisponível; dados locais.',
      };
    } catch (_) {
      // Preferir o erro da function (causa raiz) se o fallback também falhar.
      throw falhaCallable;
    }
  }

  static bool _pareceIndisponivel(Object e) {
    final t = e.toString().toLowerCase();
    return t.contains('not-found') ||
        t.contains('unavailable') ||
        t.contains('404') ||
        t.contains('html') ||
        t.contains('formatexception') ||
        t.contains('não-json') ||
        t.contains('nao-json');
  }

  /// Agregado local sem custos privados de fornecedor (mesmo contrato do backend).
  Future<Map<String, dynamic>> _consultarLocal({
    required String eixoTemporal,
    String? idFornecedor,
    String? estado,
    int? despesasPlataformaCentavos,
  }) async {
    final db = _db!;
    final orcSnap = await db.collection('orcamento').limit(500).get();
    final fatos = <FatoComercialAdmin>[];
    final linhasContratacao = <Map<String, dynamic>>[];
    for (final doc in orcSnap.docs) {
      final d = doc.data();
      final idEvento = (d['id_evento'] ?? '').toString().trim();
      if (idEvento.isEmpty) continue;
      final forn = (d['id_fornecedor'] ?? '').toString();
      if (idFornecedor != null &&
          idFornecedor.isNotEmpty &&
          forn != idFornecedor) {
        continue;
      }
      final status = (d['status'] ?? '').toString().toLowerCase();
      final contratado = d['orcamento_fechado'] == true ||
          status == 'fechado' ||
          status == 'contratado';
      if (estado != null && estado.isNotEmpty) {
        final e = estado.toLowerCase();
        if (e == 'contratado' && !contratado) continue;
        if (e == 'oportunidade' && contratado) continue;
      }
      final valorContratado = _paraCentavos(
        d['valor_contratado_centavos'] ??
            d['valor_contratado'] ??
            d['custo_estimado'],
        jaCentavos: d['valor_contratado_centavos'] != null,
      );
      final pago = _paraCentavos(
        d['pago_liquido_centavos'] ?? d['pago'],
        jaCentavos: d['pago_liquido_centavos'] != null,
      );
      fatos.add(FatoComercialAdmin(
        idEvento: idEvento,
        idOrcamento: doc.id,
        idNecessidade: (d['id_necessidade'] ?? d['id_cotacao'])?.toString(),
        idFornecedor: forn.isEmpty ? null : forn,
        contratado: contratado,
        valorContratadoCentavos: contratado ? valorContratado : 0,
        valorOportunidadeCentavos: contratado ? 0 : valorContratado,
        pagoCentavos: contratado ? pago : 0,
        statusEvento: status.isEmpty ? null : status,
        consultaPagamentoCompleta:
            d['pago_liquido_centavos'] != null || d['pago'] is num,
      ));

      final nomeForn = (d['nome_fornecedor'] ?? '').toString().trim();
      final nomeSol = (d['nome_solicitante'] ?? '').toString().trim();
      final nomeServ =
          (d['nome'] ?? d['nome_servico'] ?? '').toString().trim();
      final pendencias = <String>[];
      if (nomeSol.isEmpty) pendencias.add('contratante');
      if (contratado && (forn.isEmpty || nomeForn.isEmpty)) {
        pendencias.add('fornecedor');
      }
      if (contratado && nomeServ.isEmpty) pendencias.add('servico');
      linhasContratacao.add({
        'id_contrato': doc.id,
        'id_orcamento': doc.id,
        'id_evento': idEvento,
        'nome_contratante': nomeSol.isEmpty ? null : nomeSol,
        'nome_fornecedor': nomeForn.isEmpty ? null : nomeForn,
        'nome_servico': nomeServ.isEmpty ? null : nomeServ,
        'contratado': contratado,
        'estado_comercial': contratado ? 'Contratado' : 'Oportunidade',
        'estado_execucao':
            (d['estado_execucao'] ?? 'nao_iniciado').toString(),
        'valor_contratado_centavos': contratado ? valorContratado : 0,
        'pago_centavos': contratado ? pago : 0,
        'pendencias_identificacao': pendencias,
        'identidade_incompleta': pendencias.isNotEmpty,
        'origem_identidade': 'documento',
      });
    }

    final comissoes = await _lerComissoes(db);
    final politicaAtiva = await _politicaAtiva(db);

    final dash = DashboardFinanceiroAdminService.agregar(
      fatos: fatos,
      comissoes: comissoes,
      politicaComissaoAtiva: politicaAtiva || comissoes.isNotEmpty,
      despesasPlataformaCentavos: despesasPlataformaCentavos,
      eixoTemporal: eixoTemporal,
    );

    return {
      'ok': true,
      'origem': 'fallback_local',
      'qtdEventos': dash.qtdEventos,
      'qtdContratos': dash.qtdContratos,
      'qtdOportunidades': dash.qtdOportunidades,
      'volumeContratadoCentavos': dash.volumeContratadoCentavos,
      'pagamentosEventosCentavos': dash.pagamentosEventosCentavos,
      'receitaPlataformaCentavos': dash.receitaPlataformaCentavos,
      'completo': dash.completo,
      'eixoTemporal': dash.eixoTemporal,
      'formulaAbrangencia': dash.formulaAbrangencia,
      'comissao': {
        'configurada': dash.comissao.configurada,
        'previstasCentavos': dash.comissao.previstasCentavos,
        'geradasCentavos': dash.comissao.geradasCentavos,
        'aReceberCentavos': dash.comissao.aReceberCentavos,
        'vencidasCentavos': dash.comissao.vencidasCentavos,
        'recebidasCentavos': dash.comissao.recebidasCentavos,
        'ajustadasCentavos': dash.comissao.ajustadasCentavos,
      },
      // Campos flat usados pela UI premium.
      'comissaoConfigurada': dash.comissao.configurada,
      'comissaoGeradasCentavos': dash.comissao.geradasCentavos,
      'comissaoRecebidasCentavos': dash.comissao.recebidasCentavos,
      'comissaoAReceberCentavos': dash.comissao.aReceberCentavos,
      'linhasEvento': dash.linhasEvento
          .map((l) => {
                'idEvento': l.idEvento,
                'id_evento': l.idEvento,
                'dataEvento': l.dataEvento?.toIso8601String(),
                'status': l.status,
                'qtdServicos': l.qtdServicos,
                'qtdContratos': l.qtdContratos,
                'contratadoCentavos': l.contratadoCentavos,
                'pagoCentavos': l.pagoCentavos,
                'saldoCentavos': l.saldoCentavos,
                'previsaoDisponivelCentavos': l.previsaoDisponivelCentavos,
                'comissaoCentavos': l.comissaoCentavos,
                'contratacoes': linhasContratacao
                    .where((c) => c['id_evento'] == l.idEvento)
                    .toList(),
              })
          .toList(),
      'linhasContratacao': linhasContratacao,
      'linhas_contratacao': linhasContratacao,
      'qtdIdentidadeIncompleta':
          linhasContratacao.where((c) => c['identidade_incompleta'] == true).length,
      'paginacao': {
        'limite': 500,
        'retornados': orcSnap.size,
        'truncado': orcSnap.size >= 500,
      },
    };
  }

  Future<List<FatoComissaoAdmin>> _lerComissoes(FirebaseFirestore db) async {
    try {
      final comSnap =
          await db.collection('plataforma_comissao_obrigacoes').limit(200).get();
      return comSnap.docs.map((d) {
        final m = d.data();
        return FatoComissaoAdmin(
          id: d.id,
          status: (m['status'] ?? 'gerada').toString(),
          valorOriginalCentavos:
              (m['valor_original_centavos'] as num?)?.toInt() ??
                  (m['valorOriginalCentavos'] as num?)?.toInt() ??
                  0,
          valorAjustesCentavos:
              (m['valor_ajustes_centavos'] as num?)?.toInt() ?? 0,
          valorLiquidadoCentavos:
              (m['valor_liquidado_centavos'] as num?)?.toInt() ?? 0,
          idEvento: m['id_evento']?.toString(),
        );
      }).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const [];
      rethrow;
    }
  }

  Future<bool> _politicaAtiva(FirebaseFirestore db) async {
    try {
      final polSnap =
          await db.collection('plataforma_comissao_politicas').limit(5).get();
      return polSnap.docs.any((d) => d.data()['ativa'] == true);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }

  int _paraCentavos(dynamic v, {required bool jaCentavos}) {
    if (v is! num || !v.isFinite) return 0;
    if (jaCentavos) return v.round();
    return (v * 100).round();
  }
}
