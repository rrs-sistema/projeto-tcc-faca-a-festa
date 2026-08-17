import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/usuario.dart';

export '../../../domain/entities/usuario.dart';

class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.idUsuario,
    required super.nome,
    required super.email,
    super.tipo,
    super.cpf,
    super.fotoPerfilUrl,
    super.senhaHash,
    super.ativo,
    super.dataCadastro,
    super.cidade,
    super.uf,
  });

  factory UsuarioModel.fromEntity(Usuario usuario) => UsuarioModel(
        idUsuario: usuario.idUsuario,
        nome: usuario.nome,
        email: usuario.email,
        tipo: usuario.tipo,
        cpf: usuario.cpf,
        fotoPerfilUrl: usuario.fotoPerfilUrl,
        senhaHash: usuario.senhaHash,
        ativo: usuario.ativo,
        dataCadastro: usuario.dataCadastro,
        cidade: usuario.cidade,
        uf: usuario.uf,
      );

  Map<String, dynamic> toMap() => {
        'id_usuario': idUsuario,
        'nome': nome,
        'email': email,
        'tipo': tipo,
        'cpf': cpf,
        'foto_perfil_url': fotoPerfilUrl,
        'senha_hash': senhaHash,
        'ativo': ativo,
        'data_cadastro': dataCadastro == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(dataCadastro!),
        'cidade': cidade,
        'uf': uf,
      };

  factory UsuarioModel.fromMap(Map<String, dynamic> map) => UsuarioModel(
        idUsuario: map['id_usuario'] ?? '',
        nome: map['nome'] ?? '',
        email: map['email'] ?? '',
        tipo: map['tipo'],
        cpf: map['cpf'],
        fotoPerfilUrl: map['foto_perfil_url'],
        senhaHash: map['senha_hash'],
        ativo: map['ativo'] ?? true,
        dataCadastro: map['data_cadastro'] is Timestamp
            ? (map['data_cadastro'] as Timestamp).toDate()
            : null,
        cidade: map['cidade'],
        uf: map['uf'],
      );

  @override
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
  }) =>
      UsuarioModel(
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
