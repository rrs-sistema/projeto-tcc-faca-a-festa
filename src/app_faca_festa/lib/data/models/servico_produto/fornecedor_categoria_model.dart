import 'package:cloud_firestore/cloud_firestore.dart';

class FornecedorCategoriaModel {
  final String idFornecedor;
  final String idCategoria;
  final String? nomeCategoria;
  final List<Map<String, dynamic>> subcategorias;
  final DateTime? dataCadastro;

  FornecedorCategoriaModel({
    required this.idFornecedor,
    required this.idCategoria,
    this.nomeCategoria,
    this.subcategorias = const [],
    this.dataCadastro,
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
      dataCadastro:
          map['data_cadastro'] is Timestamp ? (map['data_cadastro'] as Timestamp).toDate() : null,
    );
  }

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
}
