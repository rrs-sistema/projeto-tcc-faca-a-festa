import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/usuario.dart';


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
    super.mfaTotpAtivo,
    super.mfaEmailAtivo,
    super.mfaMetodo,
    super.dataCadastro,
    super.cidade,
    super.uf,
    super.aceitePrivacidadeEm,
    super.versaoPoliticaPrivacidade,
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
        mfaTotpAtivo: usuario.mfaTotpAtivo,
        mfaEmailAtivo: usuario.mfaEmailAtivo,
        mfaMetodo: usuario.mfaMetodo,
        dataCadastro: usuario.dataCadastro,
        cidade: usuario.cidade,
        uf: usuario.uf,
        aceitePrivacidadeEm: usuario.aceitePrivacidadeEm,
        versaoPoliticaPrivacidade: usuario.versaoPoliticaPrivacidade,
      );

  Map<String, dynamic> toMap() => {
        'id_usuario': idUsuario,
        'nome': nome,
        'email': email,
        'tipo': tipo,
        'cpf': cpf,
        'foto_perfil_url': fotoPerfilUrl,
        'ativo': ativo,
        'mfa_totp_ativo': mfaTotpAtivo,
        'mfa_email_ativo': mfaEmailAtivo,
        'mfa_metodo': mfaMetodo,
        'data_cadastro': dataCadastro == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(dataCadastro!),
        'cidade': cidade,
        'uf': uf,
        'aceite_privacidade_em': aceitePrivacidadeEm == null
            ? null
            : Timestamp.fromDate(aceitePrivacidadeEm!),
        'versao_politica_privacidade': versaoPoliticaPrivacidade,
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
        mfaTotpAtivo: map['mfa_totp_ativo'] == true,
        mfaEmailAtivo: map['mfa_email_ativo'] == true,
        mfaMetodo: (map['mfa_metodo'] ?? '').toString(),
        dataCadastro: _data(map['data_cadastro']),
        cidade: map['cidade'],
        uf: map['uf'],
        aceitePrivacidadeEm: _data(map['aceite_privacidade_em']),
        versaoPoliticaPrivacidade:
            map['versao_politica_privacidade']?.toString(),
      );

  static DateTime? _data(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

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
    bool? mfaTotpAtivo,
    bool? mfaEmailAtivo,
    String? mfaMetodo,
    DateTime? dataCadastro,
    String? cidade,
    String? uf,
    DateTime? aceitePrivacidadeEm,
    String? versaoPoliticaPrivacidade,
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
        mfaTotpAtivo: mfaTotpAtivo ?? this.mfaTotpAtivo,
        mfaEmailAtivo: mfaEmailAtivo ?? this.mfaEmailAtivo,
        mfaMetodo: mfaMetodo ?? this.mfaMetodo,
        dataCadastro: dataCadastro ?? this.dataCadastro,
        cidade: cidade ?? this.cidade,
        uf: uf ?? this.uf,
        aceitePrivacidadeEm: aceitePrivacidadeEm ?? this.aceitePrivacidadeEm,
        versaoPoliticaPrivacidade:
            versaoPoliticaPrivacidade ?? this.versaoPoliticaPrivacidade,
      );
}
