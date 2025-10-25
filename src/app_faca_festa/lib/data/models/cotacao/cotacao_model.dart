import 'package:cloud_firestore/cloud_firestore.dart';

enum StatusCotacao {
  pendente,
  respondida,
  parcial,
  concluida,
  cancelada;

  /// 🔹 Rótulo legível para a UI
  String get label {
    switch (this) {
      case StatusCotacao.respondida:
        return 'Respondida';
      case StatusCotacao.parcial:
        return 'Parcial';
      case StatusCotacao.concluida:
        return 'Concluída';
      case StatusCotacao.cancelada:
        return 'Cancelada';
      default:
        return 'Pendente';
    }
  }

  /// 🔹 Valor usado no Firestore
  String get firestoreValue {
    switch (this) {
      case StatusCotacao.respondida:
        return 'respondida';
      case StatusCotacao.parcial:
        return 'parcial';
      case StatusCotacao.concluida:
        return 'concluida';
      case StatusCotacao.cancelada:
        return 'cancelada';
      default:
        return 'pendente';
    }
  }

  /// 🔹 Converte uma string Firestore → enum
  static StatusCotacao fromString(String? value) {
    if (value == null) return StatusCotacao.pendente;

    switch (value.toLowerCase()) {
      case 'respondida':
        return StatusCotacao.respondida;
      case 'parcial':
        return StatusCotacao.parcial;
      case 'concluida':
        return StatusCotacao.concluida;
      case 'cancelada':
        return StatusCotacao.cancelada;
      default:
        return StatusCotacao.pendente;
    }
  }
}

class CotacaoModel {
  final String id;
  final String idEvento;
  final String idUsuarioSolicitante;
  final String? descricao;
  final String? categoriaNome; // 🔹 Novo campo
  final DateTime? dataLimiteResposta;
  final DateTime dataCadastro;
  final StatusCotacao status;
  final List<String> fornecedores;
  final List<String> servicos;

  CotacaoModel({
    required this.id,
    required this.idEvento,
    required this.idUsuarioSolicitante,
    this.descricao,
    this.categoriaNome, // ✅ novo
    this.dataLimiteResposta,
    required this.dataCadastro,
    required this.status,
    required this.fornecedores,
    required this.servicos,
  });

  factory CotacaoModel.fromMap(Map<String, dynamic> map, String id) {
    return CotacaoModel(
      id: id,
      idEvento: map['id_evento'] ?? '',
      idUsuarioSolicitante: map['id_usuario_solicitante'] ?? '',
      descricao: map['observacao'],
      categoriaNome: map['categoria_nome'], // ✅ novo
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
        'data_limite_resposta':
            dataLimiteResposta != null ? Timestamp.fromDate(dataLimiteResposta!) : null,
        'data_envio': Timestamp.fromDate(dataCadastro),
        'status': status.firestoreValue,
        'fornecedores': fornecedores,
        'servicos': servicos,
      };

  CotacaoModel copyWith({
    String? descricao,
    String? categoriaNome, // ✅ novo
    DateTime? dataLimiteResposta,
    StatusCotacao? status,
    List<String>? fornecedores,
    List<String>? servicos,
  }) {
    return CotacaoModel(
      id: id,
      idEvento: idEvento,
      idUsuarioSolicitante: idUsuarioSolicitante,
      descricao: descricao ?? this.descricao,
      categoriaNome: categoriaNome ?? this.categoriaNome, // ✅ novo
      dataLimiteResposta: dataLimiteResposta ?? this.dataLimiteResposta,
      dataCadastro: dataCadastro,
      status: status ?? this.status,
      fornecedores: fornecedores ?? this.fornecedores,
      servicos: servicos ?? this.servicos,
    );
  }
}
