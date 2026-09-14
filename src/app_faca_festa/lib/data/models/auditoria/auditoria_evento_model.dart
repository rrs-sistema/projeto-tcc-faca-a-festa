import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';

class AuditoriaEventoModel extends AuditoriaEvento {
  const AuditoriaEventoModel({
    required super.id,
    required super.acao,
    required super.area,
    required super.nivel,
    required super.resumo,
    super.entidadeTipo,
    super.entidadeId,
    super.entidadeNome,
    super.idFornecedor,
    super.idEvento,
    super.idServico,
    super.idCotacao,
    super.idOrcamento,
    super.atorUid,
    super.atorNome,
    super.atorEmail,
    super.atorTipo,
    super.atorAuthType,
    super.mudancas,
    super.detalhe,
    super.visivelFornecedor,
    super.plataforma,
    super.rota,
    super.origem,
    super.operacao,
    super.documentPath,
    super.sourceEventId,
    super.algoritmoHash,
    super.hashIntegridade,
    super.criadoEm,
  });

  factory AuditoriaEventoModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    final mudancasRaw = map['mudancas'];
    final mudancas = <AuditoriaMudanca>[];
    if (mudancasRaw is List) {
      for (final item in mudancasRaw) {
        if (item is Map) {
          mudancas.add(
            AuditoriaEventoModel.mudancaFromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    AuditoriaDetalhe? detalhe;
    final detalheRaw = map['detalhe'];
    if (detalheRaw is Map) {
      detalhe = detalheFromMap(Map<String, dynamic>.from(detalheRaw));
    }

    return AuditoriaEventoModel(
      id: id,
      acao: (map['acao'] ?? '').toString(),
      area: (map['area'] ?? 'SISTEMA').toString(),
      nivel: (map['nivel'] ?? 'INFO').toString(),
      resumo: (map['resumo'] ?? '').toString(),
      entidadeTipo: _textoOpcional(map['entidade_tipo'] ?? map['entidadeTipo']),
      entidadeId: _textoOpcional(map['entidade_id'] ?? map['entidadeId']),
      entidadeNome: _textoOpcional(map['entidade_nome'] ?? map['entidadeNome']),
      idFornecedor: _textoOpcional(map['id_fornecedor'] ?? map['idFornecedor']),
      idEvento: _textoOpcional(map['id_evento'] ?? map['idEvento']),
      idServico: _textoOpcional(map['id_servico'] ?? map['idServico']),
      idCotacao: _textoOpcional(map['id_cotacao'] ?? map['idCotacao']),
      idOrcamento: _textoOpcional(map['id_orcamento'] ?? map['idOrcamento']),
      atorUid: _textoOpcional(map['ator_uid'] ?? map['atorUid']),
      atorNome: _textoOpcional(map['ator_nome'] ?? map['atorNome']),
      atorEmail: _textoOpcional(map['ator_email'] ?? map['atorEmail']),
      atorTipo: _textoOpcional(map['ator_tipo'] ?? map['atorTipo']),
      atorAuthType:
          _textoOpcional(map['ator_auth_type'] ?? map['atorAuthType']),
      mudancas: mudancas,
      detalhe: detalhe,
      visivelFornecedor:
          map['visivel_fornecedor'] == true || map['visivelFornecedor'] == true,
      plataforma: _textoOpcional(map['plataforma']),
      rota: _textoOpcional(map['rota']),
      origem: _textoOpcional(map['origem']),
      operacao: _textoOpcional(map['operacao']),
      documentPath: _textoOpcional(map['document_path'] ?? map['documentPath']),
      sourceEventId:
          _textoOpcional(map['source_event_id'] ?? map['sourceEventId']),
      algoritmoHash:
          _textoOpcional(map['algoritmo_hash'] ?? map['algoritmoHash']),
      hashIntegridade:
          _textoOpcional(map['hash_integridade'] ?? map['hashIntegridade']),
      criadoEm: _toDate(map['criado_em'] ?? map['criadoEm']),
    );
  }

  static AuditoriaMudanca mudancaFromMap(Map<String, dynamic> map) {
    return AuditoriaMudanca(
      campo: (map['campo'] ?? '').toString(),
      de: (map['de'] ?? '').toString(),
      para: (map['para'] ?? '').toString(),
    );
  }

  static Map<String, dynamic> mudancaToMap(AuditoriaMudanca mudanca) {
    return {
      'campo': mudanca.campo,
      'de': mudanca.de,
      'para': mudanca.para,
    };
  }

  static AuditoriaDetalhe detalheFromMap(Map<String, dynamic> map) {
    final dados = <String, Object?>{};
    final dadosRaw = map['dados'];
    if (dadosRaw is Map) {
      dados.addAll(
        dadosRaw.map(
          (key, value) => MapEntry(key.toString(), _asObject(value)),
        ),
      );
    }
    const conhecidas = {
      'tipo',
      'document_path',
      'documentPath',
      'metodo',
      'email',
      'dados',
    };
    for (final entry in map.entries) {
      if (conhecidas.contains(entry.key)) continue;
      dados[entry.key] = _asObject(entry.value);
    }
    return AuditoriaDetalhe(
      tipo: _textoOpcional(map['tipo']),
      documentPath: _textoOpcional(map['document_path'] ?? map['documentPath']),
      metodo: _textoOpcional(map['metodo']),
      email: _textoOpcional(map['email']),
      dados: dados,
    );
  }

  static Map<String, dynamic> detalheToMap(AuditoriaDetalhe detalhe) {
    if (detalhe.tipo == 'snapshot') {
      return {
        'tipo': 'snapshot',
        if ((detalhe.documentPath ?? '').isNotEmpty)
          'document_path': detalhe.documentPath,
        if (detalhe.dados.isNotEmpty) 'dados': detalhe.dados,
      };
    }
    return {
      if ((detalhe.tipo ?? '').isNotEmpty) 'tipo': detalhe.tipo,
      if ((detalhe.documentPath ?? '').isNotEmpty)
        'document_path': detalhe.documentPath,
      if ((detalhe.metodo ?? '').isNotEmpty) 'metodo': detalhe.metodo,
      if ((detalhe.email ?? '').isNotEmpty) 'email': detalhe.email,
      ...detalhe.dados,
    };
  }

  static Object? _asObject(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _asObject(item)),
      );
    }
    if (value is Iterable) {
      return value.map(_asObject).toList();
    }
    return value.toString();
  }

  static String? _textoOpcional(dynamic value) {
    final texto = (value ?? '').toString().trim();
    return texto.isEmpty ? null : texto;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
