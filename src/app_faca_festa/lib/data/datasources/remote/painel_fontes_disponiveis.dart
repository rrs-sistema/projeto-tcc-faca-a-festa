import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/functions/callable_sessao_gateway.dart';

/// Somente leituras já autorizadas ao próprio fornecedor. Não calcula dinheiro.
class PainelFontesDisponiveis {
  PainelFontesDisponiveis({required this.db, required this.gateway});
  final FirebaseFirestore db;
  final CallableSessaoGateway gateway;
  Future<Map<String, dynamic>> carregar(String uid) async {
    if (gateway.usuario != uid) throw StateError('Sessão alterada.');
    final resultado = <String, dynamic>{'fontes': <String, dynamic>{}};
    Future<void> fonte(String nome, Future<dynamic> Function() ler) async {
      try {
        resultado[nome] = await ler().timeout(const Duration(seconds: 12));
        (resultado['fontes'] as Map)[nome] = {'estado': 'disponivel'};
      } catch (e) {
        resultado[nome] = null;
        (resultado['fontes'] as Map)[nome] = {
          'estado': 'indisponivel',
          'codigo': e is FirebaseException ? e.code : 'consulta-incompleta'
        };
      }
    }

    await Future.wait([
      fonte('atendimentos', () async {
        final docs = await db
            .collectionGroup('fornecedores')
            .where('id_fornecedor', isEqualTo: uid)
            .get(const GetOptions(source: Source.server));
        final itens = <Map<String, dynamic>>[];
        int? naoLidas = 0;
        for (final doc in docs.docs) {
          if (doc.id != uid ||
              doc.reference.parent.parent?.parent.id != 'cotacao') {
            continue;
          }
          final cotacao = await doc.reference.parent.parent!
              .get(const GetOptions(source: Source.server));
          if (!cotacao.exists) continue;
          final dados = {
            ...doc.data(),
            'id': cotacao.id,
            'cotacao': cotacao.data()
          };
          itens.add(dados);
          dados['evidenciaCompleta'] = true;
          try {
            final mensagens = await doc.reference
                .collection('mensagens')
                .get(const GetOptions(source: Source.server));
            dados['mensagens'] = mensagens.docs.map((m) => m.data()).toList();
            final total = mensagens.docs
                .where((m) =>
                    m.data()['lido'] != true &&
                    m.data()['id_usuario'] != uid &&
                    m.data()['sistema'] != true &&
                    m.data()['id_usuario'] != 'sistema')
                .length;
            if (naoLidas != null) naoLidas += total;
          } catch (_) {
            naoLidas = null;
            dados['evidenciaCompleta'] = false;
          }
          try {
            dados['propostas'] = (await doc.reference
                    .collection('propostas')
                    .get(const GetOptions(source: Source.server)))
                .docs
                .map((p) => p.data())
                .toList();
          } catch (_) {
            dados['evidenciaCompleta'] = false;
          }
        }
        return {
          ...resumoAtendimentosDisponiveis(itens, naoLidas: naoLidas),
          'primeiraResposta':
              medirPrimeiraRespostaDisponivel(itens, uid, DateTime.now())
        };
      }),
      fonte(
          'catalogo',
          () async => (await db
                  .collection('fornecedor_servico')
                  .where('id_fornecedor', isEqualTo: uid)
                  .where('ativo', isEqualTo: true)
                  .count()
                  .get())
              .count),
      fonte('contratos', () async {
        final documentos = (await db
                .collection('orcamento')
                .where('id_fornecedor', isEqualTo: uid)
                .get(const GetOptions(source: Source.server)))
            .docs
            .map((d) => {...d.data(), 'id': d.id})
            .toList();
        return (
          total: contarContratosDisponiveis(documentos),
          proximo: proximoCompromissoDisponivel(documentos, DateTime.now()),
        );
      }),
      fonte('reputacao', () async {
        final consulta = await gateway.chamar('consultarGestaoReputacaoFn', {
          'idFornecedor': uid,
          'tipo': 'fornecedor',
          'limite': 1,
        });
        final resumo = consulta['resumo'] as Map;
        return (resumo['quantidade'] as num) > 0 ? resumo : null;
      }),
      fonte(
          'estoque',
          () async => (await db
                  .collection('fornecedor/$uid/estoque_itens')
                  .count()
                  .get())
              .count),
    ]);
    if (gateway.usuario != uid) throw StateError('Sessão alterada.');
    final contratos =
        resultado['contratos'] as ({int total, Map<String, String>? proximo})?;
    resultado['contratos'] = contratos?.total;
    resultado['proximoCompromisso'] = contratos?.proximo;
    resultado['consultadoEm'] = DateTime.now().toUtc().toIso8601String();
    return resultado;
  }
}

DateTime? instantePainel(dynamic valor) => valor is Timestamp
    ? valor.toDate()
    : valor is DateTime
        ? valor
        : DateTime.tryParse(valor?.toString() ?? '');
Map<String, dynamic> resumoAtendimentosDisponiveis(
    List<Map<String, dynamic>> itens,
    {int? naoLidas}) {
  final pendentes = itens.where((d) {
    final q = d['cotacao'] as Map? ?? {};
    if (['cancelada', 'cancelado', 'concluida', 'fechada']
        .contains(q['status'])) {
      return false;
    }
    final estado = d['estado_comercial'] ?? d['status'];
    return ['nova_solicitacao', 'aguardando', 'pendente'].contains(estado) ||
        (estado == 'negociacao' && d['responsavel_retorno'] == 'fornecedor');
  }).toList();
  DateTime? envio(Map d) =>
      instantePainel(d['data_envio'] ?? (d['cotacao'] as Map?)?['data_envio']);
  pendentes.sort((a, b) =>
      (envio(a) ?? DateTime(9999)).compareTo(envio(b) ?? DateTime(9999)));
  return {
    'aguardando': pendentes.length,
    'mensagensNaoLidas': naoLidas,
    'total': itens.length,
    'prioridade': pendentes.isEmpty
        ? null
        : {
            'idCotacao': pendentes.first['id'],
            'enviadoEm': envio(pendentes.first)?.toUtc().toIso8601String()
          }
  };
}

Map<String, String>? proximoCompromissoDisponivel(
    List<Map<String, dynamic>> documentos, DateTime agora) {
  final limite = agora.add(const Duration(days: 7));
  DateTime? proximoInicio;
  String? servico;
  for (final d in documentos) {
    final cf = d['contrato_financeiro'] as Map?;
    final execucao = cf?['estado_execucao'] ?? d['estado_execucao'];
    if (['cancelado', 'cancelada', 'estornado'].contains(d['status']) ||
        cf?['estado_comercial'] == 'cancelado' ||
        ['aceito', 'cancelado_execucao'].contains(execucao) ||
        (cf?['estado_comercial'] != 'contratado' && d['status'] != 'fechado')) {
      continue;
    }
    final agenda = d['agenda_operacional'];
    final janelas = agenda is Map ? agenda['janelas'] : null;
    if (janelas is! List) continue;
    for (final janela in janelas.whereType<Map>()) {
      final inicio = instantePainel(janela['inicio']);
      final fim = instantePainel(janela['fim']);
      if (inicio == null ||
          fim == null ||
          !fim.isAfter(inicio) ||
          inicio.isBefore(agora) ||
          inicio.isAfter(limite) ||
          (proximoInicio != null && !inicio.isBefore(proximoInicio))) {
        continue;
      }
      proximoInicio = inicio;
      servico = (d['nome'] ??
              d['nome_servico_contratado'] ??
              d['escopo'] ??
              'Serviço contratado')
          .toString();
    }
  }
  return proximoInicio == null
      ? null
      : {
          'servico': servico!,
          'inicio': proximoInicio.toUtc().toIso8601String()
        };
}

int contarContratosDisponiveis(List<Map<String, dynamic>> documentos) {
  final identidades = <String>{};
  for (final d in documentos) {
    final cf = d['contrato_financeiro'] as Map? ?? {};
    if (['cancelado', 'cancelada', 'estornado'].contains(d['status']) ||
        cf['estado_comercial'] == 'cancelado' ||
        cf['estado_execucao'] == 'cancelado_execucao') {
      continue;
    }
    if (cf['estado_comercial'] != 'contratado' &&
        d['orcamento_fechado'] != true &&
        !['fechado', 'contratado'].contains(d['status'])) {
      continue;
    }
    identidades.add((cf['id_contrato'] ??
            (d['id_cotacao'] != null ? 'cotacao:${d['id_cotacao']}' : d['id']))
        .toString());
  }
  return identidades.length;
}

Map<String, dynamic>? medirPrimeiraRespostaDisponivel(
    List<Map<String, dynamic>> itens, String uid, DateTime agora) {
  final inicio = agora.subtract(const Duration(hours: 720));
  final horas = <double>[];
  var semResposta = 0;
  for (final item in itens) {
    final envio = instantePainel(
        item['data_envio'] ?? (item['cotacao'] as Map?)?['data_envio']);
    if (envio == null || envio.isBefore(inicio) || !envio.isBefore(agora)) {
      continue;
    }
    if (item['evidenciaCompleta'] != true) {
      return null;
    }
    final eventos = <DateTime>[];
    for (final m in item['mensagens'] ?? []) {
      final em = instantePainel(m['enviado_em']);
      if (m['id_usuario'] == uid &&
          m['sistema'] != true &&
          em != null &&
          !em.isBefore(envio) &&
          !em.isAfter(agora)) {
        eventos.add(em);
      }
    }
    for (final p in item['propostas'] ?? []) {
      final em = instantePainel(p['criado_em']);
      if (p['autor_id'] == uid &&
          em != null &&
          !em.isBefore(envio) &&
          !em.isAfter(agora)) {
        eventos.add(em);
      }
    }
    if (eventos.isEmpty) {
      semResposta++;
    } else {
      eventos.sort();
      horas.add(eventos.first.difference(envio).inMilliseconds / 3600000);
    }
  }
  return {
    'media':
        horas.isEmpty ? null : horas.reduce((a, b) => a + b) / horas.length,
    'amostra': horas.length,
    'semResposta': semResposta
  };
}
