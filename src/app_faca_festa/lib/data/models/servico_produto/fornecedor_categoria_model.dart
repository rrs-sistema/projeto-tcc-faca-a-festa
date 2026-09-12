import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';

export 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';

class FornecedorCategoriaModel extends FornecedorCategoria {
  FornecedorCategoriaModel({
    required super.idFornecedor,
    required super.idCategoria,
    super.nomeCategoria,
    super.subcategorias = const [],
    super.dataCadastro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_fornecedor': idFornecedor,
      'id_categoria': idCategoria,
      'nome_categoria': nomeCategoria,
      'subcategorias': subcategorias,
      // ✅ grava data local (evita erro de timestamp em array)
      'data_cadastro': dataCadastro != null
          ? Timestamp.fromDate(dataCadastro!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  factory FornecedorCategoriaModel.fromMap(Map<String, dynamic> map) {
    return FornecedorCategoriaModel(
      idFornecedor: map['id_fornecedor'] ?? '',
      idCategoria: map['id_categoria'] ?? '',
      nomeCategoria: map['nome_categoria'],
      subcategorias: (map['subcategorias'] != null)
          ? List<Map<String, dynamic>>.from(map['subcategorias'])
          : [],
      dataCadastro: map['data_cadastro'] is Timestamp
          ? (map['data_cadastro'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  FornecedorCategoriaModel copyWith({
    String? idFornecedor,
    String? idCategoria,
    String? nomeCategoria,
    List<Map<String, dynamic>>? subcategorias,
    DateTime? dataCadastro,
  }) {
    return FornecedorCategoriaModel(
      idFornecedor: idFornecedor ?? this.idFornecedor,
      idCategoria: idCategoria ?? this.idCategoria,
      nomeCategoria: nomeCategoria ?? this.nomeCategoria,
      subcategorias: subcategorias ?? this.subcategorias,
      dataCadastro: dataCadastro ?? this.dataCadastro,
    );
  }

  factory FornecedorCategoriaModel.fromEntity(FornecedorCategoria categoria) {
    return FornecedorCategoriaModel(
      idFornecedor: categoria.idFornecedor,
      idCategoria: categoria.idCategoria,
      nomeCategoria: categoria.nomeCategoria,
      subcategorias: categoria.subcategorias,
      dataCadastro: categoria.dataCadastro,
    );
  }
}
