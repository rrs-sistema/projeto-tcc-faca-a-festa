import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa o vínculo entre um fornecedor e um serviço/produto.
/// Cada fornecedor pode oferecer múltiplos serviços com preços próprios.
class FornecedorProdutoServicoModel {
  /// Identificador único do vínculo (documento Firestore)
  final String id;

  /// ID do produto/serviço base (FK para servico_produto)
  final String idProdutoServico;

  /// ID do fornecedor (FK para fornecedor)
  final String idFornecedor;

  /// ID da subcategoria (FK para subcategoria_servico)
  final String? idSubcategoria; // 🔹 novo campo

  /// Preço padrão do serviço
  final double preco;

  /// Preço promocional (opcional)
  final double? precoPromocao;

  /// Indica se o vínculo está ativo
  final bool ativo;

  /// Data de cadastro (útil para relatórios)
  final DateTime dataCadastro;

  final double? mediaServico;
  final int? totalAvaliacoesServico;

  FornecedorProdutoServicoModel({
    required this.id,
    required this.idProdutoServico,
    required this.idFornecedor,
    required this.preco,
    this.idSubcategoria,
    this.mediaServico,
    this.totalAvaliacoesServico,
    this.precoPromocao,
    this.ativo = true,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // ===========================================================
  // 🔹 Conversão para Firestore
  // ===========================================================
  Map<String, dynamic> toMap() {
    return {
      'id_fornecedor_servico': id,
      'id_produto_servico': idProdutoServico,
      'id_fornecedor': idFornecedor,
      'id_subcategoria': idSubcategoria, // ✅ novo
      'preco': preco,
      'preco_promocao': precoPromocao,
      'ativo': ativo,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
      'media_servico': mediaServico,
      'total_avaliacoes_servico': totalAvaliacoesServico,
    };
  }

  // ===========================================================
  // 🔹 Conversão a partir do Firestore
  // ===========================================================

  factory FornecedorProdutoServicoModel.fromMap(Map<String, dynamic> map) {
    return FornecedorProdutoServicoModel(
      id: map['id_fornecedor_servico'] ?? map['id'] ?? '',
      idProdutoServico:
          map['id_produto_servico'] ?? map['idProdutoServico'] ?? '',
      idFornecedor: map['id_fornecedor'] ?? map['idFornecedor'] ?? '',
      idSubcategoria: map['id_subcategoria'] ?? map['idSubcategoria'],
      preco: (map['preco'] as num?)?.toDouble() ?? 0.0,
      precoPromocao: (map['preco_promocao'] as num?)?.toDouble(),
      ativo: map['ativo'] ?? true,
      dataCadastro: _toDateTime(map['data_cadastro']),
      mediaServico: (map['media_servico'] as num?)?.toDouble(),
      totalAvaliacoesServico: map['total_avaliacoes_servico'],
    );
  }

  // ===========================================================
  // 🔹 Atualização parcial
  // ===========================================================
  FornecedorProdutoServicoModel copyWith({
    double? preco,
    double? precoPromocao,
    bool? ativo,
    String? idSubcategoria,
  }) {
    return FornecedorProdutoServicoModel(
      id: id,
      idProdutoServico: idProdutoServico,
      idFornecedor: idFornecedor,
      preco: preco ?? this.preco,
      precoPromocao: precoPromocao ?? this.precoPromocao,
      ativo: ativo ?? this.ativo,
      idSubcategoria: idSubcategoria ?? this.idSubcategoria,
      dataCadastro: dataCadastro,
    );
  }

  // ===========================================================
  // 🔹 Conversão de datas
  // ===========================================================
  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
