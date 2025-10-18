import 'package:cloud_firestore/cloud_firestore.dart';

class OrcamentoModel {
  final String idOrcamento;
  final String idEvento;
  final String idProdutoServico; // FK para fornecedor_produto_servico
  final double? custoEstimado;
  final bool orcamentoFechado;
  final String? anotacoes;
  final DateTime dataCadastro;

  OrcamentoModel({
    required this.idOrcamento,
    required this.idEvento,
    required this.idProdutoServico,
    this.custoEstimado,
    this.orcamentoFechado = false,
    this.anotacoes,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  /// 🔹 Conversão para Firebase / API
  Map<String, dynamic> toMap() {
    return {
      'id_orcamento': idOrcamento,
      'id_evento_evento': idEvento,
      'id_produto_servico': idProdutoServico,
      'custo_estimado': custoEstimado,
      'orcamento_fechado': orcamentoFechado,
      'anotacoes': anotacoes,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
    };
  }

  /// 🔹 Conversão a partir do Firestore
  factory OrcamentoModel.fromMap(Map<String, dynamic> map) {
    return OrcamentoModel(
      idOrcamento: map['id_orcamento'] ?? '',
      idEvento: map['id_evento_evento'] ?? '',
      idProdutoServico: map['id_produto_servico'] ?? '',
      custoEstimado:
          map['custo_estimado'] != null ? (map['custo_estimado'] as num).toDouble() : null,
      orcamentoFechado: map['orcamento_fechado'] ?? false,
      anotacoes: map['anotacoes'],
      dataCadastro: map['data_cadastro'] is Timestamp
          ? (map['data_cadastro'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// 🔹 Atualização parcial
  OrcamentoModel copyWith({
    double? custoEstimado,
    bool? orcamentoFechado,
    String? anotacoes,
  }) {
    return OrcamentoModel(
      idOrcamento: idOrcamento,
      idEvento: idEvento,
      idProdutoServico: idProdutoServico,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      orcamentoFechado: orcamentoFechado ?? this.orcamentoFechado,
      anotacoes: anotacoes ?? this.anotacoes,
      dataCadastro: dataCadastro,
    );
  }
}
