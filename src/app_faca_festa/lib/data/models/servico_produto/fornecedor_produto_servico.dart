import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa o vínculo entre um fornecedor e um serviço/produto.
/// Cada fornecedor pode oferecer múltiplos serviços com preços próprios.
class FornecedorProdutoServicoModel {
  /// Identificador único do vínculo (documento Firestore)
  final String idFornecedorServico;

  /// ID do produto/serviço base (FK para servico_produto)
  final String idProdutoServico;

  /// ID do fornecedor (FK para fornecedor)
  final String idFornecedor;

  /// Preço padrão do serviço
  final double preco;

  /// Preço promocional (opcional)
  final double? precoPromocao;

  /// Indica se o vínculo está ativo
  final bool ativo;

  /// Data de cadastro (útil para relatórios)
  final DateTime dataCadastro;

  FornecedorProdutoServicoModel({
    required this.idFornecedorServico,
    required this.idProdutoServico,
    required this.idFornecedor,
    required this.preco,
    this.precoPromocao,
    this.ativo = true,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // ===========================================================
  // 🔹 Conversão para Firestore
  // ===========================================================
  Map<String, dynamic> toMap() {
    return {
      'id_fornecedor_servico': idFornecedorServico,
      'id_produto_servico': idProdutoServico,
      'id_fornecedor': idFornecedor,
      'preco': preco,
      'preco_promocao': precoPromocao,
      'ativo': ativo,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
    };
  }

  // ===========================================================
  // 🔹 Conversão a partir do Firestore
  // ===========================================================
  factory FornecedorProdutoServicoModel.fromMap(Map<String, dynamic> map) {
    return FornecedorProdutoServicoModel(
      idFornecedorServico: map['id_fornecedor_servico'] ?? '',
      idProdutoServico: map['id_produto_servico'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? '',
      preco: (map['preco'] as num?)?.toDouble() ?? 0.0,
      precoPromocao: (map['preco_promocao'] as num?)?.toDouble(),
      ativo: map['ativo'] ?? true,
      dataCadastro: _toDateTime(map['data_cadastro']),
    );
  }

  // ===========================================================
  // 🔹 Atualização parcial
  // ===========================================================
  FornecedorProdutoServicoModel copyWith({
    double? preco,
    double? precoPromocao,
    bool? ativo,
  }) {
    return FornecedorProdutoServicoModel(
      idFornecedorServico: idFornecedorServico,
      idProdutoServico: idProdutoServico,
      idFornecedor: idFornecedor,
      preco: preco ?? this.preco,
      precoPromocao: precoPromocao ?? this.precoPromocao,
      ativo: ativo ?? this.ativo,
      dataCadastro: dataCadastro,
    );
  }

  // ===========================================================
  // 🔹 Função auxiliar para conversão de datas
  // ===========================================================
  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
