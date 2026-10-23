import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:app_faca_festa/data/services/functions/callable_https_client.dart';
import 'package:app_faca_festa/data/services/functions/financeiro_callable_gateway.dart';

class CentralMediacaoRemote {
  CentralMediacaoRemote({
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

  Future<Map<String, dynamic>> consultarCentral({
    String? busca,
    String? estadoComercial,
    String? estadoExecucao,
    bool? casoAberto,
    String? idResponsavel,
    String eixoTemporal = 'data_evento',
    String? periodoInicio,
    String? periodoFim,
    bool agruparPorEvento = false,
    int offset = 0,
    int limite = 50,
  }) async {
    late final FinanceiroCallableException falha;
    try {
      return await _gateway.call('consultarCentralContratacoes', {
        if (busca != null && busca.isNotEmpty) 'busca': busca,
        if (estadoComercial != null && estadoComercial.isNotEmpty)
          'estadoComercial': estadoComercial,
        if (estadoExecucao != null && estadoExecucao.isNotEmpty)
          'estadoExecucao': estadoExecucao,
        if (casoAberto != null) 'casoAberto': casoAberto,
        if (idResponsavel != null && idResponsavel.isNotEmpty)
          'idResponsavel': idResponsavel,
        'eixoTemporal': eixoTemporal,
        if (periodoInicio != null && periodoInicio.isNotEmpty)
          'periodoInicio': periodoInicio,
        if (periodoFim != null && periodoFim.isNotEmpty) 'periodoFim': periodoFim,
        'agruparPorEvento': agruparPorEvento,
        'offset': offset,
        'limite': limite,
      });
    } on FinanceiroCallableException catch (e) {
      if (!e.podeUsarFallbackLocal || _db == null) rethrow;
      falha = e;
    } catch (e) {
      if (_db == null || !_pareceIndisponivel(e)) rethrow;
      falha = FinanceiroCallableException('unavailable', e.toString());
    }

    try {
      final local = await _consultarCentralLocal(
        busca: busca,
        estadoComercial: estadoComercial,
        estadoExecucao: estadoExecucao,
        casoAberto: casoAberto,
        offset: offset,
        limite: limite,
      );
      return {
        ...local,
        'aviso':
            'Consulta local — a function consultarCentralContratacoes ainda não está publicada neste ambiente. '
            'Os totais de intermediação podem ficar incompletos.',
        'origem': 'fallback_local',
      };
    } catch (e) {
      // Não expor 404/HTML da URL da function: devolve lista vazia com aviso acionável.
      return {
        'ok': true,
        'linhas': <Map<String, dynamic>>[],
        'paginacao': {
          'offset': offset,
          'limite': limite,
          'retornados': 0,
          'total_filtrado_amostra': 0,
          'truncado': false,
        },
        'aviso':
            'Não foi possível consultar contratações (function ausente e fallback local falhou: $e). '
            'Publique consultarCentralContratacoes em southamerica-east1.',
        'origem': 'fallback_local_vazio',
        'erro_function': falha.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> consultarDetalhe({
    required String idOrcamento,
  }) async {
    late final FinanceiroCallableException falha;
    try {
      return await _gateway.call('consultarDetalheContratacao', {
        'idOrcamento': idOrcamento,
      });
    } on FinanceiroCallableException catch (e) {
      if (!e.podeUsarFallbackLocal || _db == null) rethrow;
      falha = e;
    } catch (e) {
      if (_db == null || !_pareceIndisponivel(e)) rethrow;
      falha = FinanceiroCallableException('unavailable', e.toString());
    }

    try {
      final local = await _consultarDetalheLocal(idOrcamento);
      return {
        ...local,
        'aviso':
            'Detalhe local — function consultarDetalheContratacao ainda não publicada. '
            'Mediação e comandos exigem deploy.',
        'origem': 'fallback_local',
      };
    } catch (e) {
      throw FinanceiroCallableException(
        'unavailable',
        'Detalhe indisponível (function ausente e fallback local falhou: $e). '
        'Causa da function: ${falha.message ?? falha.code}',
      );
    }
  }

  Future<Map<String, dynamic>> abrirCaso({
    required String idEvento,
    required String idContrato,
    required String idOrcamento,
    required String motivo,
    required String chaveIdempotencia,
    String? idFornecedor,
    String? idContratante,
    String categoria = 'outro',
    String descricao = '',
    String prioridade = 'normal',
  }) {
    return _gateway.call('abrirCasoMediacao', {
      'idEvento': idEvento,
      'idContrato': idContrato,
      'idOrcamento': idOrcamento,
      'motivo': motivo,
      'chaveIdempotencia': chaveIdempotencia,
      if (idFornecedor != null) 'idFornecedor': idFornecedor,
      if (idContratante != null) 'idContratante': idContratante,
      'categoria': categoria,
      'descricao': descricao,
      'prioridade': prioridade,
    });
  }

  Future<Map<String, dynamic>> atribuirResponsavel({
    required String idCaso,
    required String idResponsavel,
  }) {
    return _gateway.call('atribuirResponsavelCaso', {
      'idCaso': idCaso,
      'idResponsavel': idResponsavel,
    });
  }

  Future<Map<String, dynamic>> registrarRegistro({
    required String idCaso,
    required String texto,
    String tipo = 'analise',
    String? visibilidade,
    String? novoEstado,
  }) {
    return _gateway.call('registrarRegistroMediacao', {
      'idCaso': idCaso,
      'texto': texto,
      'tipo': tipo,
      if (visibilidade != null) 'visibilidade': visibilidade,
      if (novoEstado != null) 'novoEstado': novoEstado,
    });
  }

  Future<Map<String, dynamic>> solicitarInformacao({
    required String idCaso,
    required String texto,
  }) {
    return _gateway.call('solicitarInformacaoCaso', {
      'idCaso': idCaso,
      'texto': texto,
    });
  }

  Future<Map<String, dynamic>> registrarDecisao({
    required String idCaso,
    required String texto,
    String tipoDecisao = 'manter',
    List<String> referenciasComandos = const [],
    bool compartilharComPartes = false,
  }) {
    return _gateway.call('registrarDecisaoCaso', {
      'idCaso': idCaso,
      'texto': texto,
      'tipoDecisao': tipoDecisao,
      'referenciasComandos': referenciasComandos,
      'compartilharComPartes': compartilharComPartes,
    });
  }

  Future<Map<String, dynamic>> fecharCaso({
    required String idCaso,
    required String conclusao,
  }) {
    return _gateway.call('fecharCasoMediacao', {
      'idCaso': idCaso,
      'conclusao': conclusao,
    });
  }

  Future<Map<String, dynamic>> recomendarBloqueio({
    required String idCaso,
    required String motivo,
  }) {
    return _gateway.call('recomendarBloqueioRevisao', {
      'idCaso': idCaso,
      'motivo': motivo,
    });
  }

  Future<Map<String, dynamic>> consultarCaso({
    required String idCaso,
    String? papelConsulta,
    String? idFornecedorOperador,
  }) {
    return _gateway.call('consultarCasoMediacao', {
      'idCaso': idCaso,
      if (papelConsulta != null) 'papelConsulta': papelConsulta,
      if (idFornecedorOperador != null)
        'idFornecedorOperador': idFornecedorOperador,
    });
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

  int _centavos(dynamic v, {required bool jaCentavos}) {
    if (v is int) return jaCentavos ? v : (v * 100);
    if (v is num) {
      return jaCentavos ? v.round() : (v * 100).round();
    }
    return 0;
  }

  Future<Map<String, dynamic>> _consultarCentralLocal({
    String? busca,
    String? estadoComercial,
    String? estadoExecucao,
    bool? casoAberto,
    int offset = 0,
    int limite = 50,
  }) async {
    final db = _db!;
    final orcSnap = await db.collection('orcamento').limit(200).get();
    final casosAbertos = <String>{};
    try {
      final casos = await db
          .collection('plataforma_mediacao_casos')
          .where('estado', whereIn: [
            'aberto',
            'em_analise',
            'aguardando_partes',
            'em_decisao',
          ])
          .limit(100)
          .get();
      for (final d in casos.docs) {
        final id =
            (d.data()['id_contrato'] ?? d.data()['id_orcamento'] ?? '').toString();
        if (id.isNotEmpty) casosAbertos.add(id);
      }
    } catch (_) {
      // Sem permissão/índice: filtro caso aberto fica incompleto.
    }

    final idsEvento = <String>{};
    final idsForn = <String>{};
    for (final doc in orcSnap.docs) {
      final d = doc.data();
      final ev = (d['id_evento'] ?? '').toString().trim();
      if (ev.isNotEmpty) idsEvento.add(ev);
      final f = (d['id_fornecedor'] ?? '').toString().trim();
      if (f.isNotEmpty) idsForn.add(f);
    }

    final eventos = <String, Map<String, dynamic>>{};
    for (final id in idsEvento) {
      try {
        final s = await db.collection('evento').doc(id).get();
        if (s.exists) eventos[id] = s.data() ?? {};
      } catch (_) {}
    }
    final fornecedores = <String, Map<String, dynamic>>{};
    for (final id in idsForn) {
      try {
        final s = await db.collection('fornecedor').doc(id).get();
        if (s.exists) fornecedores[id] = s.data() ?? {};
      } catch (_) {}
    }

    final linhas = <Map<String, dynamic>>[];
    final q = (busca ?? '').trim().toLowerCase();

    for (final doc in orcSnap.docs) {
      final d = doc.data();
      final idEvento = (d['id_evento'] ?? '').toString().trim();
      if (idEvento.isEmpty) continue;
      final status = (d['status'] ?? '').toLowerCase();
      final cf = d['contrato_financeiro'];
      final estadoComercialDoc = cf is Map
          ? (cf['estado_comercial'] ?? '').toString().toLowerCase()
          : '';
      final contratado = d['orcamento_fechado'] == true ||
          status == 'fechado' ||
          status == 'contratado' ||
          estadoComercialDoc == 'contratado';

      if (estadoComercial != null && estadoComercial.isNotEmpty) {
        if (estadoComercial == 'contratado' && !contratado) continue;
        if (estadoComercial == 'oportunidade' && contratado) continue;
      }

      final exec = (cf is Map
              ? (cf['estado_execucao'] ?? d['estado_execucao'])
              : d['estado_execucao'] ?? 'nao_iniciado')
          .toString()
          .toLowerCase();
      if (estadoExecucao != null &&
          estadoExecucao.isNotEmpty &&
          exec != estadoExecucao.toLowerCase()) {
        continue;
      }

      final idContrato = (cf is Map && (cf['id'] ?? '').toString().isNotEmpty)
          ? cf['id'].toString()
          : doc.id;
      final temCaso =
          casosAbertos.contains(idContrato) || casosAbertos.contains(doc.id);
      if (casoAberto == true && !temCaso) continue;
      if (casoAberto == false && temCaso) continue;

      final ev = eventos[idEvento];
      final idForn = (d['id_fornecedor'] ?? '').toString();
      final forn = fornecedores[idForn];
      final nomeEvento = (ev?['nome_evento'] ?? ev?['nome'] ?? '').toString();
      final nomeForn = (d['nome_fornecedor'] ??
              forn?['nome_fornecedor'] ??
              forn?['nomeFantasia'] ??
              forn?['nome'] ??
              '')
          .toString();
      final nomeSol = (d['nome_solicitante'] ?? '').toString();
      final nomeServ = (d['nome'] ?? d['nome_servico'] ?? '').toString();
      final valor = _centavos(
        d['valor_contratado_centavos'] ?? d['valor_contratado'] ?? d['valor'],
        jaCentavos: d['valor_contratado_centavos'] != null,
      );

      if (q.isNotEmpty) {
        final hay = [
          nomeEvento,
          nomeSol,
          nomeForn,
          nomeServ,
          idEvento,
          doc.id,
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) continue;
      }

      final pendencias = <String>[];
      if (nomeSol.trim().isEmpty) pendencias.add('contratante');
      if (nomeForn.trim().isEmpty) pendencias.add('fornecedor');
      if (nomeServ.trim().isEmpty) pendencias.add('servico');
      if (temCaso) pendencias.add('caso_mediacao_aberto');

      linhas.add({
        'id_contrato': idContrato,
        'id_orcamento': doc.id,
        'id_evento': idEvento,
        'nome_evento': nomeEvento.isEmpty ? null : nomeEvento,
        'nome_contratante': nomeSol.isEmpty ? null : nomeSol,
        'nome_fornecedor': nomeForn.isEmpty ? null : nomeForn,
        'nome_servico': nomeServ.isEmpty ? null : nomeServ,
        'valor_contratado_centavos': contratado ? valor : 0,
        'recebido_cliente_centavos': 0,
        'repassado_centavos': 0,
        'a_receber_cliente_centavos': contratado ? valor : 0,
        'pendente_repasse_centavos': 0,
        'estado_comercial': contratado ? 'contratado' : 'oportunidade',
        'estado_execucao': exec,
        'caso_aberto': temCaso,
        'pendencias': pendencias,
        'identidade_incompleta': pendencias
            .where((p) => p != 'caso_mediacao_aberto')
            .isNotEmpty,
      });
    }

    final total = linhas.length;
    final fatia = linhas.skip(offset).take(limite).toList();
    return {
      'ok': true,
      'linhas': fatia,
      'paginacao': {
        'offset': offset,
        'limite': limite,
        'retornados': fatia.length,
        'total_filtrado_amostra': total,
        'truncado': orcSnap.size >= 200,
        'aviso': orcSnap.size >= 200
            ? 'Amostra local limitada a 200 orçamentos.'
            : null,
      },
    };
  }

  Future<Map<String, dynamic>> _consultarDetalheLocal(String idOrcamento) async {
    final db = _db!;
    final snap = await db.collection('orcamento').doc(idOrcamento).get();
    if (!snap.exists) {
      throw const FinanceiroCallableException(
        'not-found',
        'Contratação não encontrada.',
      );
    }
    final d = snap.data()!;
    final idEvento = (d['id_evento'] ?? '').toString();
    Map<String, dynamic>? ev;
    Map<String, dynamic>? forn;
    if (idEvento.isNotEmpty) {
      final e = await db.collection('evento').doc(idEvento).get();
      if (e.exists) ev = e.data();
    }
    final idForn = (d['id_fornecedor'] ?? '').toString();
    if (idForn.isNotEmpty) {
      final f = await db.collection('fornecedor').doc(idForn).get();
      if (f.exists) forn = f.data();
    }
    final valor = _centavos(
      d['valor_contratado_centavos'] ?? d['valor_contratado'] ?? d['valor'],
      jaCentavos: d['valor_contratado_centavos'] != null,
    );
    final nomeEvento = (ev?['nome_evento'] ?? ev?['nome'] ?? '').toString();
    final nomeForn = (d['nome_fornecedor'] ??
            forn?['nome_fornecedor'] ??
            forn?['nome'] ??
            '')
        .toString();
    final nomeSol = (d['nome_solicitante'] ?? '').toString();
    final nomeServ = (d['nome'] ?? d['nome_servico'] ?? '').toString();
    final exec = (d['estado_execucao'] ?? 'nao_iniciado').toString();

    return {
      'ok': true,
      'resumo': {
        'id_orcamento': idOrcamento,
        'id_contrato': idOrcamento,
        'id_evento': idEvento,
        'nome_evento': nomeEvento,
        'nome_contratante': nomeSol,
        'nome_fornecedor': nomeForn,
        'nome_servico': nomeServ,
        'valor_contratado_centavos': valor,
        'recebido_cliente_centavos': 0,
        'repassado_centavos': 0,
        'a_receber_cliente_centavos': valor,
        'pendente_repasse_centavos': 0,
        'estado_comercial': 'contratado',
        'estado_execucao': exec,
      },
      'partes': {
        'organizador': {'nome': null},
        'contratante': {'id': d['id_solicitante'], 'nome': nomeSol},
        'pagador': {'nome': nomeSol},
        'fornecedor': {'id': idForn, 'nome': nomeForn},
      },
      'contratacao_servico': {
        'id_orcamento': idOrcamento,
        'nome_servico': nomeServ,
        'estado_execucao': exec,
        'aviso_execucao':
            'Contrato formalizado ou pagamento não comprovam serviço prestado.',
      },
      'financeiro': {
        'valorContratadoCentavos': valor,
        'aviso': 'Dimensões de intermediação exigem function publicada.',
      },
      'historico_mediacao': {'caso_aberto': null},
    };
  }
}
