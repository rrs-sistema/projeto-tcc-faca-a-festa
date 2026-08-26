import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/auditoria_evento.dart';

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
    super.mudancas,
    super.detalhe,
    super.visivelFornecedor,
    super.plataforma,
    super.rota,
    super.origem,
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
            AuditoriaMudanca.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    Map<String, dynamic>? detalhe;
    final detalheRaw = map['detalhe'];
    if (detalheRaw is Map) {
      detalhe = Map<String, dynamic>.from(detalheRaw);
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
      mudancas: mudancas,
      detalhe: detalhe,
      visivelFornecedor: map['visivel_fornecedor'] == true ||
          map['visivelFornecedor'] == true,
      plataforma: _textoOpcional(map['plataforma']),
      rota: _textoOpcional(map['rota']),
      origem: _textoOpcional(map['origem']),
      criadoEm: _toDate(map['criado_em'] ?? map['criadoEm']),
    );
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
