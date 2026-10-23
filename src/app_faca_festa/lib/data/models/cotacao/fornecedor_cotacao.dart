import 'package:cloud_firestore/cloud_firestore.dart';

// ===========================================================
// 🔹 Enum de Status do Fornecedor na Cotação
// ===========================================================
enum StatusFornecedorCotacao {
  aguardando,
  respondido,
  recusado,
  cancelada,
  fechado,
  perdeuCotacao;

  String get label {
    switch (this) {
      case StatusFornecedorCotacao.aguardando:
        return 'Aguardando preço';
      case StatusFornecedorCotacao.respondido:
        return 'Preço recebido';
      case StatusFornecedorCotacao.recusado:
        return 'Recusado';
      case StatusFornecedorCotacao.cancelada:
        return 'Cancelado';
      case StatusFornecedorCotacao.fechado:
        return 'Contratado';
      case StatusFornecedorCotacao.perdeuCotacao:
        return 'Não ficou com este';
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
      case StatusFornecedorCotacao.cancelada:
        return 'cancelada';
      case StatusFornecedorCotacao.fechado:
        return 'fechado';
      case StatusFornecedorCotacao.perdeuCotacao:
        return 'perdeuCotacao';
    }
  }

  /// Chat ainda aceita novas mensagens do cliente.
  bool get chatAberto {
    switch (this) {
      case StatusFornecedorCotacao.cancelada:
      case StatusFornecedorCotacao.recusado:
      case StatusFornecedorCotacao.perdeuCotacao:
        return false;
      case StatusFornecedorCotacao.aguardando:
      case StatusFornecedorCotacao.respondido:
      case StatusFornecedorCotacao.fechado:
        return true;
    }
  }

  static StatusFornecedorCotacao fromString(String? value) {
    if (value == null) return StatusFornecedorCotacao.aguardando;
    switch (value.trim().toLowerCase()) {
      case 'respondido':
      case 'respondida':
        return StatusFornecedorCotacao.respondido;
      case 'recusado':
        return StatusFornecedorCotacao.recusado;
      case 'cancelada':
      case 'cancelado':
        return StatusFornecedorCotacao.cancelada;
      case 'fechado':
        return StatusFornecedorCotacao.fechado;
      case 'perdeucotacao':
        return StatusFornecedorCotacao.perdeuCotacao;
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
  final String nomeFornecedor;
  final DateTime? prazoEntrega;
  final String? condicaoPagamento;
  final StatusFornecedorCotacao status;
  final String? observacaoFornecedor;
  final DateTime? dataResposta;
  final double? valorCotado;

  const FornecedorCotacaoModel({
    required this.id,
    required this.idCotacao,
    required this.idFornecedor,
    required this.nomeFornecedor,
    this.prazoEntrega,
    this.condicaoPagamento,
    this.status = StatusFornecedorCotacao.aguardando,
    this.observacaoFornecedor,
    this.dataResposta,
    this.valorCotado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_cotacao': idCotacao,
      'id_fornecedor': idFornecedor,
      'nome_fornecedor': nomeFornecedor,
      'prazo_entrega':
          prazoEntrega != null ? Timestamp.fromDate(prazoEntrega!) : null,
      'condicao_pagamento': condicaoPagamento,
      'status': status.firestoreValue,
      'observacao_fornecedor': observacaoFornecedor,
      'data_resposta':
          dataResposta != null ? Timestamp.fromDate(dataResposta!) : null,
      if (valorCotado != null) 'valor_cotado': valorCotado,
    };
  }

  factory FornecedorCotacaoModel.fromMap(Map<String, dynamic> map) {
    return FornecedorCotacaoModel(
      id: map['id']?.toString() ?? '',
      idCotacao: map['id_cotacao']?.toString() ?? '',
      idFornecedor: map['id_fornecedor']?.toString() ?? '',
      nomeFornecedor: map['nome_fornecedor']?.toString() ?? '',
      prazoEntrega: map['prazo_entrega'] is Timestamp
          ? (map['prazo_entrega'] as Timestamp).toDate()
          : DateTime.tryParse(map['prazo_entrega']?.toString() ?? ''),
      condicaoPagamento: map['condicao_pagamento'],
      status: StatusFornecedorCotacao.fromString(map['status']),
      observacaoFornecedor: map['observacao_fornecedor'],
      dataResposta: map['data_resposta'] is Timestamp
          ? (map['data_resposta'] as Timestamp).toDate()
          : DateTime.tryParse(map['data_resposta']?.toString() ?? ''),
      valorCotado: (map['valor_cotado'] as num?)?.toDouble(),
    );
  }

  FornecedorCotacaoModel copyWith({
    String? idFornecedor,
    String? nomeFornecedor,
    DateTime? prazoEntrega,
    String? condicaoPagamento,
    StatusFornecedorCotacao? status,
    String? observacaoFornecedor,
    DateTime? dataResposta,
    double? valorCotado,
  }) {
    return FornecedorCotacaoModel(
      id: id,
      idCotacao: idCotacao,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      prazoEntrega: prazoEntrega ?? this.prazoEntrega,
      condicaoPagamento: condicaoPagamento ?? this.condicaoPagamento,
      status: status ?? this.status,
      observacaoFornecedor: observacaoFornecedor ?? this.observacaoFornecedor,
      dataResposta: dataResposta ?? this.dataResposta,
      valorCotado: valorCotado ?? this.valorCotado,
    );
  }
}
