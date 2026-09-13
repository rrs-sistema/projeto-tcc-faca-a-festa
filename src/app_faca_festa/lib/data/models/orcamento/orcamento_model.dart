import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/orcamento.dart';


/// ===========================================================
/// 🔹 Modelo OrcamentoModel completo com melhorias
/// ===========================================================
class OrcamentoModel extends Orcamento {
  /// ===========================================================
  /// 🔸 Construtor principal
  /// ===========================================================
  OrcamentoModel({
    required super.idOrcamento,
    required super.idEvento,
    required super.idServicoFornecido,
    super.idFornecedor,
    super.nomeFornecedor,
    super.idSolicitante,
    super.nomeSolicitante,
    super.idCategoria,
    super.idTipoPagamento,
    super.custoEstimado,
    super.orcamentoFechado = false,
    super.anotacoes,
    super.status = StatusOrcamento.pendente,
    super.dataCadastro,
    super.dataFechamento,
    super.fechadoPor,
  });

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

  factory OrcamentoModel.fromEntity(Orcamento entity) {
    if (entity is OrcamentoModel) return entity;

    return OrcamentoModel(
      idOrcamento: entity.idOrcamento,
      idEvento: entity.idEvento,
      idServicoFornecido: entity.idServicoFornecido,
      idFornecedor: entity.idFornecedor,
      nomeFornecedor: entity.nomeFornecedor,
      idSolicitante: entity.idSolicitante,
      nomeSolicitante: entity.nomeSolicitante,
      idCategoria: entity.idCategoria,
      idTipoPagamento: entity.idTipoPagamento,
      custoEstimado: entity.custoEstimado,
      orcamentoFechado: entity.orcamentoFechado,
      anotacoes: entity.anotacoes,
      status: entity.status,
      dataCadastro: entity.dataCadastro,
      dataFechamento: entity.dataFechamento,
      fechadoPor: entity.fechadoPor,
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
  @override
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
