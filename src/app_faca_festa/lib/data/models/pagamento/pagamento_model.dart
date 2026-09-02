import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Enum para status do pagamento
enum PagamentoStatus { parcial, total }

class PagamentoModel {
  final String idPagamento;
  final String idOrcamento;
  final int idTipoPagamento;
  final DateTime dataPagamento;
  final double valorPago;
  final String? observacoes;
  final PagamentoStatus statusPagamento; // 🔸 Parcial ou Total

  const PagamentoModel({
    required this.idPagamento,
    required this.idOrcamento,
    required this.idTipoPagamento,
    required this.dataPagamento,
    required this.valorPago,
    this.observacoes,
    this.statusPagamento = PagamentoStatus.parcial,
  });

  /// 🔹 Conversão para Firebase / API REST
  Map<String, dynamic> toMap() {
    return {
      'id_pagamento': idPagamento,
      'id_orcamento_orcamento': idOrcamento,
      'id_tipo_pagamento': idTipoPagamento,
      'data_pagamento': Timestamp.fromDate(dataPagamento),
      'valor_pago': valorPago,
      'observacoes': observacoes,
      'status_pagamento': statusPagamento.name, // 🔸 grava como string
    };
  }

  /// 🔹 Conversão a partir do Firestore
  factory PagamentoModel.fromMap(Map<String, dynamic> map) {
    return PagamentoModel(
      idPagamento: map['id_pagamento'] ?? '',
      idOrcamento: map['id_orcamento_orcamento'] ?? '',
      idTipoPagamento: map['id_tipo_pagamento'] is int
          ? map['id_tipo_pagamento']
          : int.tryParse(map['id_tipo_pagamento'].toString()) ?? 0,
      dataPagamento: map['data_pagamento'] is Timestamp
          ? (map['data_pagamento'] as Timestamp).toDate()
          : DateTime.tryParse(map['data_pagamento'].toString()) ??
              DateTime.now(),
      valorPago: (map['valor_pago'] as num?)?.toDouble() ?? 0.0,
      observacoes: map['observacoes'],
      statusPagamento: _parseStatus(map['status_pagamento']),
    );
  }

  /// 🔹 Atualização parcial
  PagamentoModel copyWith({
    int? idTipoPagamento,
    DateTime? dataPagamento,
    double? valorPago,
    String? observacoes,
    PagamentoStatus? statusPagamento,
  }) {
    return PagamentoModel(
      idPagamento: idPagamento,
      idOrcamento: idOrcamento,
      idTipoPagamento: idTipoPagamento ?? this.idTipoPagamento,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      valorPago: valorPago ?? this.valorPago,
      observacoes: observacoes ?? this.observacoes,
      statusPagamento: statusPagamento ?? this.statusPagamento,
    );
  }

  /// 🔹 Conversão segura de string → enum
  static PagamentoStatus _parseStatus(dynamic value) {
    if (value == null) return PagamentoStatus.parcial;
    switch (value.toString().toLowerCase()) {
      case 'total':
        return PagamentoStatus.total;
      default:
        return PagamentoStatus.parcial;
    }
  }

  /// 🔹 Texto legível
  String get statusDescricao =>
      statusPagamento == PagamentoStatus.total ? 'Total' : 'Parcial';
}
