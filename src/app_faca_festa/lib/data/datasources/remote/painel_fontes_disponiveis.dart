import 'package:cloud_firestore/cloud_firestore.dart';

/// Somente leituras já autorizadas ao próprio fornecedor. Não calcula dinheiro.
class PainelFontesDisponiveis {
  PainelFontesDisponiveis({required this.db, required this.usuario});
  final FirebaseFirestore db;
  final String? Function() usuario;
  Future<Map<String, dynamic>> carregar(String uid) async {
    if (usuario() != uid) throw StateError('Sessão alterada.');
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
      fonte(
          'contratos',
          () async => contarContratosDisponiveis((await db
                  .collection('orcamento')
                  .where('id_fornecedor', isEqualTo: uid)
                  .get(const GetOptions(source: Source.server)))
              .docs
              .map((d) => {...d.data(), 'id': d.id})
              .toList())),
      fonte('reputacao', () async {
        final d = (await db
                .doc('fornecedor/$uid')
                .get(const GetOptions(source: Source.server)))
            .data();
        return resumoReputacaoDisponivel(d ?? {});
      }),
      fonte(
          'estoque',
          () async => (await db
                  .collection('fornecedor/$uid/estoque_itens')
                  .count()
                  .get())
              .count),
    ]);
    if (usuario() != uid) throw StateError('Sessão alterada.');
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

Map<String, dynamic>? resumoReputacaoDisponivel(Map d) {
  final r = d['reputacao_verificada'];
  if (r is Map && r['schema'] == 2) {
    final n = r['quantidade'], m = r['media'];
    if (n is num &&
        n.isFinite &&
        n % 1 == 0 &&
        n > 0 &&
        m is num &&
        m.isFinite &&
        m >= 1 &&
        m <= 5) {
      return {
        'quantidade': n.toInt(),
        'media': m.toDouble(),
        'verificada': true
      };
    }
  }
  final n = d['total_avaliacoes'] ?? d['totalAvaliacoes'],
      m = d['media_avaliacoes'] ?? d['mediaAvaliacoes'];
  if (n is num &&
      n.isFinite &&
      n % 1 == 0 &&
      n > 0 &&
      m is num &&
      m.isFinite &&
      m >= 1 &&
      m <= 5) {
    return {
      'quantidade': n.toInt(),
      'media': m.toDouble(),
      'verificada': false
    };
  }
  return null;
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
