import 'package:cloud_firestore/cloud_firestore.dart';

/// ===========================================================
/// 🔹 Enum de Status do Orçamento
/// ===========================================================
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

/// ===========================================================
/// 🔹 Modelo OrcamentoModel completo com melhorias
/// ===========================================================
class OrcamentoModel {
  final String idOrcamento;
  final String idEvento;
  final String? idFornecedor;
  final String? nomeFornecedor;
  final String? idSolicitante;
  final String? nomeSolicitante;
  final String? idServicoFornecido;
  final String? idCategoria;
  final String? idTipoPagamento;
  final double? custoEstimado;
  final bool orcamentoFechado;
  final String? anotacoes;
  final StatusOrcamento status;
  final DateTime dataCadastro;
  final DateTime? dataFechamento;
  final String? fechadoPor;

  /// ===========================================================
  /// 🔸 Construtor principal
  /// ===========================================================
  OrcamentoModel({
    required this.idOrcamento,
    required this.idEvento,
    required this.idServicoFornecido,
    this.idFornecedor,
    this.nomeFornecedor,
    this.idSolicitante,
    this.nomeSolicitante,
    this.idCategoria,
    this.idTipoPagamento,
    this.custoEstimado,
    this.orcamentoFechado = false,
    this.anotacoes,
    this.status = StatusOrcamento.pendente,
    DateTime? dataCadastro,
    this.dataFechamento,
    this.fechadoPor,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  /// ===========================================================
  /// 🔸 Helpers de negócio
  /// ===========================================================
  bool get isFechado => status == StatusOrcamento.fechado;

  /// Usa dataFechamento se existir; senão, dataCadastro
  DateTime get dataEfetivaFechamento => dataFechamento ?? dataCadastro;

  /// ===========================================================
  /// 🔸 Conversão para Firestore
  /// ===========================================================
  Map<String, dynamic> toMap() {
    return {
      'id_orcamento': idOrcamento,
      'id_evento': idEvento,
      'id_servico_fornecido': idServicoFornecido,
      'id_categoria': idCategoria,
      'id_fornecedor': idFornecedor,
      'nome_fornecedor': nomeFornecedor,
      'id_solicitante': idSolicitante,
      'nome_solicitante': nomeSolicitante,
      'id_tipo_pagamento': idTipoPagamento,
      'custo_estimado': custoEstimado,
      'orcamento_fechado': orcamentoFechado,
      'anotacoes': anotacoes,
      'status': status.firestoreValue,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
      'data_fechamento':
          dataFechamento != null ? Timestamp.fromDate(dataFechamento!) : null,
      'fechado_por': fechadoPor,
    };
  }

  /// ===========================================================
  /// 🔸 Conversão a partir do Firestore
  /// ===========================================================
  factory OrcamentoModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return OrcamentoModel(
      idOrcamento: map['id_orcamento'] ?? docId ?? '',
      idEvento: map['id_evento'] ?? '',
      idServicoFornecido: map['id_servico_fornecido'],
      idFornecedor: map['id_fornecedor'],
      nomeFornecedor: map['nome_fornecedor'],
      idSolicitante: map['id_solicitante'],
      nomeSolicitante: map['nome_solicitante'],
      idCategoria: map['id_categoria'],
      idTipoPagamento: map['id_tipo_pagamento'],
      custoEstimado: (map['custo_estimado'] is num)
          ? (map['custo_estimado'] as num).toDouble()
          : null,
      orcamentoFechado: map['orcamento_fechado'] ?? false,
      anotacoes: map['anotacoes'],
      status: StatusOrcamento.fromString(map['status']),
      dataCadastro: _toDateTimeOrNow(map['data_cadastro']),
      dataFechamento: _toNullableDate(map['data_fechamento']),
      fechadoPor: map['fechado_por'],
    );
  }

  /// ===========================================================
  /// 🔸 Conversores de data (Timestamp / String)
  /// ===========================================================
  static DateTime _toDateTimeOrNow(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _toNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// ===========================================================
  /// 🔸 Atualização parcial (para update no Firestore)
  /// ===========================================================
  OrcamentoModel copyWith({
    String? idFornecedor,
    String? nomeFornecedor,
    String? idSolicitante,
    String? nomeSolicitante,
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
      idServicoFornecido: idServicoFornecido ?? this.idServicoFornecido,
      idFornecedor: idFornecedor ?? this.idFornecedor,
      nomeFornecedor: nomeFornecedor ?? this.nomeFornecedor,
      idSolicitante: idSolicitante ?? this.idSolicitante,
      nomeSolicitante: nomeSolicitante ?? this.nomeSolicitante,
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
