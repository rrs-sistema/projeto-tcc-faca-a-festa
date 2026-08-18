class Usuario {
  final String idUsuario;
  final String nome;
  final String email;
  final String? tipo;
  final String? cpf;
  final String? fotoPerfilUrl;
  final String? senhaHash;
  final bool ativo;
  final bool mfaTotpAtivo;
  final DateTime? dataCadastro;
  final String? cidade;
  final String? uf;

  const Usuario({
    required this.idUsuario,
    required this.nome,
    required this.email,
    this.tipo,
    this.cpf,
    this.fotoPerfilUrl,
    this.senhaHash,
    this.ativo = true,
    this.mfaTotpAtivo = false,
    this.dataCadastro,
    this.cidade,
    this.uf,
  });

  Usuario copyWith({
    String? idUsuario,
    String? nome,
    String? email,
    String? tipo,
    String? cpf,
    String? fotoPerfilUrl,
    String? senhaHash,
    bool? ativo,
    bool? mfaTotpAtivo,
    DateTime? dataCadastro,
    String? cidade,
    String? uf,
  }) =>
      Usuario(
        idUsuario: idUsuario ?? this.idUsuario,
        nome: nome ?? this.nome,
        email: email ?? this.email,
        tipo: tipo ?? this.tipo,
        cpf: cpf ?? this.cpf,
        fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
        senhaHash: senhaHash ?? this.senhaHash,
        ativo: ativo ?? this.ativo,
        mfaTotpAtivo: mfaTotpAtivo ?? this.mfaTotpAtivo,
        dataCadastro: dataCadastro ?? this.dataCadastro,
        cidade: cidade ?? this.cidade,
        uf: uf ?? this.uf,
      );
}
