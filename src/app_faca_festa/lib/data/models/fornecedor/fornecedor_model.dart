import 'package:cloud_firestore/cloud_firestore.dart';

class FornecedorModel {
  final String idFornecedor;
  final String idUsuario;
  final String razaoSocial;
  final String? cnpj;
  final String telefone;
  final String email;
  final String? descricao;
  final bool aptoParaOperar;
  final bool ativo;
  final DateTime dataCadastro;

  /// 🔹 Novo campo
  final String? bannerUrl;

  /// 🔹 Lista de categorias e subcategorias
  /// Cada item contém:
  /// { idCategoria, nomeCategoria, idSubcategoria, nomeSubcategoria }
  final List<Map<String, dynamic>> categorias;

  FornecedorModel({
    required this.idFornecedor,
    required this.idUsuario,
    required this.razaoSocial,
    required this.telefone,
    required this.email,
    this.cnpj,
    this.descricao,
    this.aptoParaOperar = false,
    this.ativo = true,
    DateTime? dataCadastro,
    this.bannerUrl,
    this.categorias = const [],
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  // =======================================================
  // 🔹 Conversão para Firestore
  // =======================================================
  Map<String, dynamic> toMap() {
    final categoriasLimpa = categorias.map((c) {
      final map = Map<String, dynamic>.from(c);

      // 🔹 Converte DateTime → Timestamp
      if (map['dataCadastro'] is DateTime) {
        map['dataCadastro'] = Timestamp.fromDate(map['dataCadastro']);
      }

      // 🔹 Remove serverTimestamp() que Firestore não aceita em arrays
      if (map['dataCadastro'] is FieldValue) {
        map.remove('dataCadastro');
      }

      return map;
    }).toList();

    return {
      'id_fornecedor': idFornecedor,
      'id_usuario': idUsuario,
      'cnpj': cnpj,
      'razao_social': razaoSocial,
      'telefone': telefone,
      'email': email,
      'descricao': descricao,
      'apto_para_operar': aptoParaOperar,
      'ativo': ativo,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
      'banner_url': bannerUrl,
      'categorias': categoriasLimpa,
    };
  }

  // =======================================================
  // 🔹 Conversão de Firestore → Model
  // =======================================================
  factory FornecedorModel.fromMap(Map<String, dynamic> map) {
    final data = map['data_cadastro'];
    DateTime parsedDate;

    if (data is Timestamp) {
      parsedDate = data.toDate();
    } else if (data is DateTime) {
      parsedDate = data;
    } else {
      parsedDate = DateTime.now();
    }

    return FornecedorModel(
      idFornecedor: map['id_fornecedor'] ?? '',
      idUsuario: map['id_usuario'] ?? '',
      razaoSocial: map['razao_social'] ?? '',
      telefone: map['telefone'] ?? '',
      email: map['email'] ?? '',
      cnpj: map['cnpj'],
      descricao: map['descricao'],
      aptoParaOperar: map['apto_para_operar'] ?? false,
      ativo: map['ativo'] ?? true,
      dataCadastro: parsedDate,
      bannerUrl: map['banner_url'],
      categorias:
          map['categorias'] != null ? List<Map<String, dynamic>>.from(map['categorias']) : [],
    );
  }

  // =======================================================
  // 🔹 Atualização parcial (copyWith)
  // =======================================================
  FornecedorModel copyWith({
    String? razaoSocial,
    String? telefone,
    String? email,
    String? descricao,
    bool? aptoParaOperar,
    bool? ativo,
    String? bannerUrl,
    List<Map<String, dynamic>>? categorias, // ✅ novo parâmetro
  }) {
    return FornecedorModel(
      idFornecedor: idFornecedor,
      idUsuario: idUsuario,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      descricao: descricao ?? this.descricao,
      aptoParaOperar: aptoParaOperar ?? this.aptoParaOperar,
      ativo: ativo ?? this.ativo,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      categorias: categorias ?? this.categorias,
    );
  }
}
