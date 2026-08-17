import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/endereco_usuario.dart';

export '../../../domain/entities/endereco_usuario.dart';

class EnderecoUsuarioModel extends EnderecoUsuario {
  const EnderecoUsuarioModel({
    required super.id,
    required super.idUsuario,
    required super.idCidade,
    required super.cep,
    required super.logradouro,
    required super.numero,
    super.complemento,
    super.bairro,
    super.nomeCidade,
    super.uf,
    super.principal,
    super.dataCadastro,
  });

  factory EnderecoUsuarioModel.fromEntity(EnderecoUsuario endereco) =>
      EnderecoUsuarioModel(
        id: endereco.id,
        idUsuario: endereco.idUsuario,
        idCidade: endereco.idCidade,
        cep: endereco.cep,
        logradouro: endereco.logradouro,
        numero: endereco.numero,
        complemento: endereco.complemento,
        bairro: endereco.bairro,
        nomeCidade: endereco.nomeCidade,
        uf: endereco.uf,
        principal: endereco.principal,
        dataCadastro: endereco.dataCadastro,
      );

  Map<String, dynamic> toMap() => {
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
        'data_cadastro': dataCadastro == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(dataCadastro!),
      };

  factory EnderecoUsuarioModel.fromMap(Map<String, dynamic> map) =>
      EnderecoUsuarioModel(
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
        dataCadastro: map['data_cadastro'] is Timestamp
            ? (map['data_cadastro'] as Timestamp).toDate()
            : null,
      );

  @override
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
  }) =>
      EnderecoUsuarioModel(
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
