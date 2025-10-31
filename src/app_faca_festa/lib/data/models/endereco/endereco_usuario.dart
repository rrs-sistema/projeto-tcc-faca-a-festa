import 'package:cloud_firestore/cloud_firestore.dart';

class EnderecoUsuarioModel {
  final String id;
  final String idUsuario;
  final int idCidade;
  final String cep;
  final String logradouro;
  final String numero;
  final String? complemento;
  final String? bairro;
  final String? nomeCidade;
  final String? uf;
  final bool principal;
  final DateTime? dataCadastro;

  const EnderecoUsuarioModel({
    required this.id,
    required this.idUsuario,
    required this.idCidade,
    required this.cep,
    required this.logradouro,
    required this.numero,
    this.complemento,
    this.bairro,
    this.nomeCidade,
    this.uf,
    this.principal = true,
    this.dataCadastro,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': idUsuario,
      'id_cidade': idCidade,
      'nome_cidade': nomeCidade,
      'uf': uf,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'principal': principal,
      'data_cadastro':
          dataCadastro != null ? Timestamp.fromDate(dataCadastro!) : FieldValue.serverTimestamp(),
    };
  }

  factory EnderecoUsuarioModel.fromMap(Map<String, dynamic> map) {
    return EnderecoUsuarioModel(
      id: map['id'] ?? '',
      idUsuario: map['id_usuario'] ?? '',
      idCidade: map['id_cidade'] is int
          ? map['id_cidade']
          : int.tryParse(map['id_cidade'].toString()) ?? 0,
      cep: map['cep'] ?? '',
      logradouro: map['logradouro'] ?? '',
      numero: map['numero'] ?? '',
      complemento: map['complemento'],
      bairro: map['bairro'],
      nomeCidade: map['nome_cidade'],
      uf: map['uf'],
      principal: map['principal'] ?? true,
      dataCadastro:
          map['data_cadastro'] is Timestamp ? (map['data_cadastro'] as Timestamp).toDate() : null,
    );
  }

  EnderecoUsuarioModel copyWith({
    String? id,
    String? idUsuario,
    int? idCidade,
    String? cep,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? nomeCidade,
    String? uf,
    bool? principal,
    DateTime? dataCadastro,
  }) {
    return EnderecoUsuarioModel(
      id: id ?? this.id,
      idUsuario: idUsuario ?? this.idUsuario,
      idCidade: idCidade ?? this.idCidade,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      nomeCidade: nomeCidade ?? this.nomeCidade,
      uf: uf ?? this.uf,
      principal: principal ?? this.principal,
      dataCadastro: dataCadastro ?? this.dataCadastro,
    );
  }
}
