import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa um orçamento vinculado a um evento e a um serviço de fornecedor.
///
/// Cada orçamento indica o interesse de um cliente (evento)
/// em contratar um serviço específico de um fornecedor.// ===========================================================
// 🔹 Enum de Status do Orçamento
// ===========================================================
enum StatusOrcamento {
  pendente,
  emNegociacao,
  fechado,
  cancelado;

  /// Retorna uma string legível para exibir na UI
  String get label {
    switch (this) {
      case StatusOrcamento.pendente:
        return 'Pendente';
      case StatusOrcamento.emNegociacao:
        return 'Em negociação';
      case StatusOrcamento.fechado:
        return 'Fechado';
      case StatusOrcamento.cancelado:
        return 'Cancelado';
    }
  }

  /// Retorna o nome usado no Firestore
  String get firestoreValue {
    switch (this) {
      case StatusOrcamento.pendente:
        return 'pendente';
      case StatusOrcamento.emNegociacao:
        return 'em_negociacao';
      case StatusOrcamento.fechado:
        return 'fechado';
      case StatusOrcamento.cancelado:
        return 'cancelado';
    }
  }

  /// Converte uma string do Firestore em enum
  /// Converte uma string do Firestore em enum
  static StatusOrcamento fromString(String? value) {
    if (value == null) return StatusOrcamento.pendente;

    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'em_negociacao':
      case 'em negociação':
        return StatusOrcamento.emNegociacao;

      case 'fechado':
      case 'concluido':
      case 'contratado':
        return StatusOrcamento.fechado;

      case 'cancelado':
      case 'cancelada':
        return StatusOrcamento.cancelado;

      case 'pendente':
      default:
        return StatusOrcamento.pendente;
    }
  }
}

// ===========================================================
// 🔹 Modelo OrcamentoModel com enum aplicado
// ===========================================================
class OrcamentoModel {
  final String idOrcamento;
  final String idEvento;
  final String? idServicoFornecido;
  final String? idCategoria;
  final String? idTipoPagamento;
  final double? custoEstimado;
  final bool orcamentoFechado;
  final String? anotacoes;
  final DateTime dataCadastro;
  final StatusOrcamento status; // ✅ Agora é ENUM
  final DateTime? dataFechamento;
  final String? fechadoPor;

  OrcamentoModel({
    required this.idOrcamento,
    required this.idEvento,
    required this.idServicoFornecido,
    this.idCategoria,
    this.idTipoPagamento,
    this.custoEstimado,
    this.orcamentoFechado = false,
    this.anotacoes,
    this.status = StatusOrcamento.pendente, // ✅ Valor padrão
    this.dataFechamento,
    this.fechadoPor,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // ===========================================================
  // 🔹 Conversão para Firestore
  // ===========================================================
  Map<String, dynamic> toMap() {
    return {
      'id_orcamento': idOrcamento,
      'id_evento': idEvento,
      'id_servico_fornecido': idServicoFornecido,
      'id_categoria': idCategoria,
      'id_tipo_pagamento': idTipoPagamento,
      'custo_estimado': custoEstimado,
      'orcamento_fechado': orcamentoFechado,
      'anotacoes': anotacoes,
      'status': status.firestoreValue, // ✅ salva como string no Firestore
      'data_cadastro': Timestamp.fromDate(dataCadastro),
      'data_fechamento': dataFechamento != null ? Timestamp.fromDate(dataFechamento!) : null,
      'fechado_por': fechadoPor,
    };
  }

// ===========================================================
// 🔹 Conversão a partir do Firestore
// ===========================================================
  factory OrcamentoModel.fromMap(Map<String, dynamic> map) {
    return OrcamentoModel(
      idOrcamento: map['id_orcamento'] ?? '',
      idEvento: map['id_evento'] ?? '',
      idServicoFornecido: map['id_servico_fornecido'],
      idCategoria: map['id_categoria'],
      idTipoPagamento: map['id_tipo_pagamento'],
      custoEstimado:
          (map['custo_estimado'] is num) ? (map['custo_estimado'] as num).toDouble() : null,
      orcamentoFechado: map['orcamento_fechado'] ?? false,
      anotacoes: map['anotacoes'],
      status: StatusOrcamento.fromString(map['status']),
      dataCadastro: _toDateTimeOrNow(map['data_cadastro']), // nunca deve ser nula
      dataFechamento: _toNullableDate(map['data_fechamento']), // pode ser nula
      fechadoPor: map['fechado_por'],
    );
  }

// ===========================================================
// 🔹 Converte Firestore Timestamp/String → DateTime
// ===========================================================
  static DateTime _toDateTimeOrNow(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

// ===========================================================
// 🔹 Converte para DateTime?, retornando null se for nula
// ===========================================================
  static DateTime? _toNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ===========================================================
  // 🔹 Atualização parcial (para Firestore .update())
  // ===========================================================
  OrcamentoModel copyWith({
    String? idFornecedor,
    String? idCategoria,
    String? idTipoPagamento,
    double? custoEstimado,
    bool? orcamentoFechado,
    String? anotacoes,
    StatusOrcamento? status,
    DateTime? dataFechamento,
    String? fechadoPor,
    String? idServicoFornecido,
  }) {
    return OrcamentoModel(
      idOrcamento: idOrcamento,
      idEvento: idEvento,
      idServicoFornecido: idServicoFornecido,
      idCategoria: idCategoria ?? this.idCategoria,
      idTipoPagamento: idTipoPagamento ?? this.idTipoPagamento,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      orcamentoFechado: orcamentoFechado ?? this.orcamentoFechado,
      anotacoes: anotacoes ?? this.anotacoes,
      status: status ?? this.status,
      dataFechamento: dataFechamento ?? this.dataFechamento,
      fechadoPor: fechadoPor ?? this.fechadoPor,
      dataCadastro: dataCadastro,
    );
  }
}
