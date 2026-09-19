import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/fornecedor_categoria.dart';
import 'package:app_faca_festa/domain/entities/fornecedor_categoria_resumo.dart';


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
      'subcategorias': subcategorias.map(_subcategoriaToMap).toList(),
      // ✅ grava data local (evita erro de timestamp em array)
      'data_cadastro': dataCadastro != null
          ? Timestamp.fromDate(dataCadastro!)
          : Timestamp.fromDate(DateTime.now()),
    };
  }

  factory FornecedorCategoriaModel.fromMap(Map<String, dynamic> map) {
    return FornecedorCategoriaModel(
      idFornecedor: (map['id_fornecedor'] ?? '').toString().trim(),
      idCategoria: (map['id_categoria'] ?? '').toString().trim(),
      nomeCategoria: map['nome_categoria']?.toString(),
      subcategorias: _readSubcategorias(map['subcategorias']),
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
    List<FornecedorSubcategoriaResumo>? subcategorias,
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
      subcategorias: List<FornecedorSubcategoriaResumo>.from(
        categoria.subcategorias,
      ),
      dataCadastro: categoria.dataCadastro,
    );
  }

  static List<FornecedorSubcategoriaResumo> _readSubcategorias(dynamic value) {
    if (value is! List) return const <FornecedorSubcategoriaResumo>[];

    return value
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          return FornecedorSubcategoriaResumo(
            idSubcategoria: (map['idSubcategoria'] ??
                    map['id_subcategoria'] ??
                    '')
                .toString()
                .trim(),
            nomeSubcategoria: (map['nomeSubcategoria'] ??
                    map['nome_subcategoria'] ??
                    map['subcategoria'] ??
                    map['nome'] ??
                    '')
                .toString()
                .trim(),
          );
        })
        .where(
          (sub) =>
              sub.idSubcategoria.isNotEmpty || sub.nomeSubcategoria.isNotEmpty,
        )
        .toList();
  }

  static Map<String, dynamic> _subcategoriaToMap(
    FornecedorSubcategoriaResumo subcategoria,
  ) {
    return {
      'idSubcategoria': subcategoria.idSubcategoria,
      'nomeSubcategoria': subcategoria.nomeSubcategoria,
    };
  }
}
