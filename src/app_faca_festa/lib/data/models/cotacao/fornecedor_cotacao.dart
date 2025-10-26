import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================
// 🔹 Enum de Status do Fornecedor na Cotação
// ===========================================================
enum StatusFornecedorCotacao {
  aguardando,
  respondido,
  recusado,
  fechado;

  String get label {
    switch (this) {
      case StatusFornecedorCotacao.aguardando:
        return 'Aguardando resposta';
      case StatusFornecedorCotacao.respondido:
        return 'Respondido';
      case StatusFornecedorCotacao.recusado:
        return 'Recusado';
      case StatusFornecedorCotacao.fechado:
        return 'Fechado';
    }
  }

  String get firestoreValue {
    switch (this) {
      case StatusFornecedorCotacao.aguardando:
        return 'aguardando';
      case StatusFornecedorCotacao.respondido:
        return 'respondido';
      case StatusFornecedorCotacao.recusado:
        return 'recusado';
      case StatusFornecedorCotacao.fechado:
        return 'fechado';
    }
  }

  static StatusFornecedorCotacao fromString(String? value) {
    if (value == null) return StatusFornecedorCotacao.aguardando;
    switch (value.trim().toLowerCase()) {
      case 'respondido':
        return StatusFornecedorCotacao.respondido;
      case 'recusado':
        return StatusFornecedorCotacao.recusado;
      case 'fechado':
        return StatusFornecedorCotacao.fechado;
      default:
        return StatusFornecedorCotacao.aguardando;
    }
  }
}

// ===========================================================
// 🔹 Modelo FornecedorCotacaoModel
// ===========================================================
class FornecedorCotacaoModel {
  final String id;
  final String idCotacao;
  final String idFornecedor;
  final DateTime? prazoEntrega; // ✅ Alterado para DateTime
  final String? condicaoPagamento;
  final StatusFornecedorCotacao status;
  final String? observacaoFornecedor;
  final DateTime? dataResposta;

  const FornecedorCotacaoModel({
    required this.id,
    required this.idCotacao,
    required this.idFornecedor,
    this.prazoEntrega,
    this.condicaoPagamento,
    this.status = StatusFornecedorCotacao.aguardando,
    this.observacaoFornecedor,
    this.dataResposta,
  });

  // ===========================================================
  // 🔹 Converter para Firestore
  // ===========================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_cotacao': idCotacao,
      'id_fornecedor': idFornecedor,
      'prazo_entrega': prazoEntrega != null ? Timestamp.fromDate(prazoEntrega!) : null,
      'condicao_pagamento': condicaoPagamento,
      'status': status.firestoreValue,
      'observacao_fornecedor': observacaoFornecedor,
      'data_resposta': dataResposta != null ? Timestamp.fromDate(dataResposta!) : null,
    };
  }

  // ===========================================================
  // 🔹 Converter do Firestore para Model
  // ===========================================================
  factory FornecedorCotacaoModel.fromMap(Map<String, dynamic> map) {
    return FornecedorCotacaoModel(
      id: map['id']?.toString() ?? '',
      idCotacao: map['id_cotacao']?.toString() ?? '',
      idFornecedor: map['id_fornecedor']?.toString() ?? '',
      prazoEntrega: map['prazo_entrega'] is Timestamp
          ? (map['prazo_entrega'] as Timestamp).toDate()
          : DateTime.tryParse(map['prazo_entrega']?.toString() ?? ''),
      condicaoPagamento: map['condicao_pagamento'],
      status: StatusFornecedorCotacao.fromString(map['status']),
      observacaoFornecedor: map['observacao_fornecedor'],
      dataResposta: map['data_resposta'] is Timestamp
          ? (map['data_resposta'] as Timestamp).toDate()
          : DateTime.tryParse(map['data_resposta']?.toString() ?? ''),
    );
  }

  // ===========================================================
  // 🔹 Atualização parcial
  // ===========================================================
  FornecedorCotacaoModel copyWith({
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    StatusFornecedorCotacao? status,
    String? observacaoFornecedor,
    DateTime? dataResposta,
  }) {
    return FornecedorCotacaoModel(
      id: id,
      idCotacao: idCotacao,
      idFornecedor: idFornecedor,
      prazoEntrega: prazoEntrega ?? this.prazoEntrega,
      condicaoPagamento: condicaoPagamento ?? this.condicaoPagamento,
      status: status ?? this.status,
      observacaoFornecedor: observacaoFornecedor ?? this.observacaoFornecedor,
      dataResposta: dataResposta ?? this.dataResposta,
    );
  }
}
