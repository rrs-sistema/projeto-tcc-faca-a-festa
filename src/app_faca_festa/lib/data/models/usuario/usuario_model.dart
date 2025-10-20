import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String idUsuario;
  final String nome;
  final String email;
  final String? tipo; // Ex: organizador, fornecedor, convidado, admin
  final String? cpf;
  final String? fotoPerfilUrl;
  final String? senhaHash;
  final bool ativo;
  final DateTime? dataCadastro;
  final String? cidade;
  final String? uf;

  const UsuarioModel({
    required this.idUsuario,
    required this.nome,
    required this.email,
    this.tipo,
    this.cpf,
    this.fotoPerfilUrl,
    this.senhaHash,
    this.ativo = true,
    this.dataCadastro,
    this.cidade,
    this.uf,
  });

  // =======================================================
  // 🔹 Conversão para Map (Firestore)
  // =======================================================
  Map<String, dynamic> toMap() {
    return {
      'id_usuario': idUsuario,
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'cpf': cpf,
      'foto_perfil_url': fotoPerfilUrl,
      'senha_hash': senhaHash,
      'ativo': ativo,
      'data_cadastro':
          dataCadastro != null ? Timestamp.fromDate(dataCadastro!) : FieldValue.serverTimestamp(),
      'cidade': cidade,
      'uf': uf,
    };
  }

  // =======================================================
  // 🔹 Conversão de Map (Firestore → Model)
  // =======================================================
  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      idUsuario: map['id_usuario'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      tipo: map['tipo'],
      cpf: map['cpf'],
      fotoPerfilUrl: map['foto_perfil_url'],
      senhaHash: map['senha_hash'],
      ativo: map['ativo'] ?? true,
      dataCadastro:
          map['data_cadastro'] is Timestamp ? (map['data_cadastro'] as Timestamp).toDate() : null,
      cidade: map['cidade'],
      uf: map['uf'],
    );
  }

  // =======================================================
  // 🔹 Atualização parcial (copyWith)
  // =======================================================
  UsuarioModel copyWith({
    String? idUsuario,
    String? nome,
    String? email,
    String? tipo,
    String? cpf,
    String? fotoPerfilUrl,
    String? senhaHash,
    bool? ativo,
    bool? isAdmin,
    DateTime? dataCadastro,
    String? cidade,
    String? uf,
  }) {
    return UsuarioModel(
      idUsuario: idUsuario ?? this.idUsuario,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tipo: tipo ?? this.tipo,
      cpf: cpf ?? this.cpf,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      senhaHash: senhaHash ?? this.senhaHash,
      ativo: ativo ?? this.ativo,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      cidade: cidade ?? this.cidade,
      uf: uf ?? this.uf,
    );
  }
}
