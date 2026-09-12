import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';

export 'package:app_faca_festa/domain/entities/fornecedor_produto_servico.dart';

/// Representa o vínculo entre um fornecedor e um serviço/produto.
/// Cada fornecedor pode oferecer múltiplos serviços com preços próprios.
class FornecedorProdutoServicoModel extends FornecedorProdutoServico {
  FornecedorProdutoServicoModel({
    required super.id,
    required super.idProdutoServico,
    required super.idFornecedor,
    required super.preco,
    super.idSubcategoria,
    super.mediaServico,
    super.totalAvaliacoesServico,
    super.precoPromocao,
    super.ativo = true,
    super.dataCadastro,
  });

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
  @override
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
      mediaServico: mediaServico,
      totalAvaliacoesServico: totalAvaliacoesServico,
    );
  }

  factory FornecedorProdutoServicoModel.fromEntity(
    FornecedorProdutoServico vinculo,
  ) {
    return FornecedorProdutoServicoModel(
      id: vinculo.id,
      idProdutoServico: vinculo.idProdutoServico,
      idFornecedor: vinculo.idFornecedor,
      idSubcategoria: vinculo.idSubcategoria,
      preco: vinculo.preco,
      precoPromocao: vinculo.precoPromocao,
      ativo: vinculo.ativo,
      dataCadastro: vinculo.dataCadastro,
      mediaServico: vinculo.mediaServico,
      totalAvaliacoesServico: vinculo.totalAvaliacoesServico,
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
