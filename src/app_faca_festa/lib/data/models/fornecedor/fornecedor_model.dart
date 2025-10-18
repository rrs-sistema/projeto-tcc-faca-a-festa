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
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  Map<String, dynamic> toMap() {
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
    };
  }

  factory FornecedorModel.fromMap(Map<String, dynamic> map) {
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
      dataCadastro: map['data_cadastro'] is Timestamp
          ? (map['data_cadastro'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  FornecedorModel copyWith({
    String? razaoSocial,
    String? telefone,
    String? email,
    String? descricao,
    bool? aptoParaOperar,
    bool? ativo,
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
    );
  }
}
