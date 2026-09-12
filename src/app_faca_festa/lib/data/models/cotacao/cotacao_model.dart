import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/cotacao.dart';

export 'package:app_faca_festa/domain/entities/cotacao.dart'
    show Cotacao, StatusCotacao;

class CotacaoModel extends Cotacao {
  CotacaoModel({
    required super.id,
    required super.idEvento,
    required super.idUsuarioSolicitante,
    required super.nomeUsuarioSolicitante,
    super.descricao,
    super.categoriaNome,
    super.dataLimiteResposta,
    required super.dataCadastro,
    required super.status,
    required super.fornecedores,
    required super.servicos,
    super.valorEstimadoTotal,
  });

  @override
  CotacaoModel copyWith({
    double? valorEstimadoTotal,
    StatusCotacao? status,
  }) {
    return CotacaoModel(
      id: id,
      idEvento: idEvento,
      idUsuarioSolicitante: idUsuarioSolicitante,
      nomeUsuarioSolicitante: nomeUsuarioSolicitante,
      descricao: descricao,
      categoriaNome: categoriaNome,
      dataLimiteResposta: dataLimiteResposta,
      dataCadastro: dataCadastro,
      status: status ?? this.status,
      fornecedores: fornecedores,
      servicos: servicos,
      valorEstimadoTotal: valorEstimadoTotal ?? this.valorEstimadoTotal,
    );
  }

  factory CotacaoModel.fromMap(Map<String, dynamic> map, String id) {
    return CotacaoModel(
      id: id,
      idEvento: map['id_evento'] ?? '',
      idUsuarioSolicitante: map['id_usuario_solicitante'] ?? '',
      descricao: map['observacao'],
      categoriaNome: map['categoria_nome'], // ✅ novo
      nomeUsuarioSolicitante: map['nome_usuario_solicitante'], // ✅ novo
      valorEstimadoTotal:
          (map['valor_estimado_total'] as num?)?.toDouble() ?? 0.0,

      dataLimiteResposta: map['data_limite_resposta'] is Timestamp
          ? (map['data_limite_resposta'] as Timestamp).toDate()
          : null,
      dataCadastro: map['data_envio'] is Timestamp
          ? (map['data_envio'] as Timestamp).toDate()
          : DateTime.now(),
      status: StatusCotacao.fromString(map['status']),
      fornecedores: [map['id_fornecedor'] ?? ''],
      servicos: [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id_evento': idEvento,
        'id_usuario_solicitante': idUsuarioSolicitante,
        'descricao': descricao,
        'categoria_nome': categoriaNome, // ✅ novo
        'data_limite_resposta': dataLimiteResposta != null
            ? Timestamp.fromDate(dataLimiteResposta!)
            : null,
        'data_envio': Timestamp.fromDate(dataCadastro),
        'status': status.firestoreValue,
        'fornecedores': fornecedores,
        'servicos': servicos,
      };
}
