enum StatusConvidado {
  pendente,
  confirmado,
  recusado;

  String get label {
    switch (this) {
      case StatusConvidado.pendente:
        return 'Pendente';
      case StatusConvidado.confirmado:
        return 'Confirmado';
      case StatusConvidado.recusado:
        return 'Recusado';
    }
  }

  static StatusConvidado fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'confirmado':
      case 'c':
        return StatusConvidado.confirmado;
      case 'recusado':
      case 'r':
        return StatusConvidado.recusado;
      default:
        return StatusConvidado.pendente;
    }
  }
}

enum TipoConvidado {
  adulto,
  crianca,
  bebe;

  String get label {
    switch (this) {
      case TipoConvidado.adulto:
        return 'Adulto';
      case TipoConvidado.crianca:
        return 'Criança';
      case TipoConvidado.bebe:
        return 'Bebê';
    }
  }

  static TipoConvidado fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'crianca':
      case 'criança':
        return TipoConvidado.crianca;
      case 'bebe':
      case 'bebê':
        return TipoConvidado.bebe;
      default:
        return TipoConvidado.adulto;
    }
  }

  static TipoConvidado fromLegacyAdulto(bool? adulto) {
    return adulto == false ? TipoConvidado.crianca : TipoConvidado.adulto;
  }
}

class Convidado {
  final String idConvidado;
  final String idEvento;
  final String nome;
  final String contato;
  final String? email;
  final StatusConvidado status;
  final TipoConvidado tipoConvidado;
  final String? idGrupo;
  final String? nomeGrupo;
  final String? idMesa;
  final int? numeroMesa;
  final bool ocupaAssento;
  final bool cuidadoEspecial;
  final DateTime? dataEnvio;
  final DateTime? dataResposta;
  final DateTime dataCadastro;
  final DateTime dataAtualizacao;
  final String conviteToken;
  final String? idUsuario;
  final String? conviteStatus;
  final String? emailUsuario;
  final String? emailNormalizado;

  const Convidado({
    required this.idConvidado,
    required this.idEvento,
    required this.nome,
    required this.contato,
    this.email,
    this.status = StatusConvidado.pendente,
    this.tipoConvidado = TipoConvidado.adulto,
    this.idGrupo,
    this.nomeGrupo,
    this.idMesa,
    this.numeroMesa,
    this.ocupaAssento = true,
    this.cuidadoEspecial = false,
    this.dataEnvio,
    this.dataResposta,
    required this.dataCadastro,
    required this.dataAtualizacao,
    this.conviteToken = '',
    this.idUsuario,
    this.conviteStatus,
    this.emailUsuario,
    this.emailNormalizado,
  });

  bool get adulto => tipoConvidado == TipoConvidado.adulto;
  bool get crianca => tipoConvidado == TipoConvidado.crianca;
  bool get bebe => tipoConvidado == TipoConvidado.bebe;
  bool get confirmado => status == StatusConvidado.confirmado;

  /// Token usado em `/convite/{token}`. Cai no id do convidado se o campo ainda não existir.
  String get tokenParaLink {
    final token = conviteToken.trim();
    return token.isNotEmpty ? token : idConvidado.trim();
  }

  bool get temLinkGerado => tokenParaLink.isNotEmpty;

  bool get temEmail {
    return _pareceEmail(email) ||
        _pareceEmail(emailUsuario) ||
        _pareceEmail(emailNormalizado);
  }

  bool get contaVinculada {
    final uid = idUsuario?.trim() ?? '';
    if (uid.isNotEmpty) return true;
    return _conviteVinculado;
  }

  bool get _conviteVinculado =>
      (conviteStatus ?? '').trim().toLowerCase() == 'vinculado';

  /// E-mail gravado na vinculação da conta (não o e-mail do convite).
  String get emailDaConta {
    final daConta = normalizarEmail(emailUsuario);
    if (daConta.isNotEmpty) return daConta;
    return normalizarEmail(emailNormalizado);
  }

  /// Convite + conta (e-mail/Google). Auth anônimo não preenche esses campos.
  String get emailNormalizadoEfetivo {
    final daConta = emailDaConta;
    if (daConta.isNotEmpty) return daConta;
    return normalizarEmail(email);
  }

  /// Só conta real (e-mail/Google) pode ser responsável de tarefa.
  /// Auth anônimo não grava `id_usuario` nem `email_usuario`.
  bool get podeSerResponsavelTarefa {
    if ((idUsuario?.trim() ?? '').isNotEmpty) return true;
    if (_conviteVinculado) return true;
    return _pareceEmail(emailUsuario) || _pareceEmail(emailNormalizado);
  }

  bool mesmoIdentificador(Convidado outro) {
    if (idConvidado.trim().isNotEmpty &&
        idConvidado.trim() == outro.idConvidado.trim()) {
      return true;
    }
    final uid = idUsuario?.trim() ?? '';
    final outroUid = outro.idUsuario?.trim() ?? '';
    if (uid.isNotEmpty && uid == outroUid) return true;
    final email = emailNormalizadoEfetivo;
    final outroEmail = outro.emailNormalizadoEfetivo;
    return email.isNotEmpty && email == outroEmail;
  }

  static String normalizarEmail(String? value) =>
      (value ?? '').trim().toLowerCase();

  static bool _pareceEmail(String? value) {
    final texto = (value ?? '').trim();
    return texto.contains('@') && texto.contains('.');
  }

  Convidado comTokenConvite() {
    final token = tokenParaLink;
    if (token.isEmpty || conviteToken.trim() == token) return this;
    return copyWith(
      conviteToken: token,
      conviteStatus: contaVinculada ? 'vinculado' : 'link_gerado',
    );
  }

  Convidado copyWith({
    String? idConvidado,
    String? idEvento,
    String? nome,
    String? contato,
    String? email,
    StatusConvidado? status,
    TipoConvidado? tipoConvidado,
    String? idGrupo,
    String? nomeGrupo,
    String? idMesa,
    int? numeroMesa,
    bool? ocupaAssento,
    bool? cuidadoEspecial,
    DateTime? dataEnvio,
    DateTime? dataResposta,
    DateTime? dataCadastro,
    DateTime? dataAtualizacao,
    String? conviteToken,
    String? idUsuario,
    String? conviteStatus,
    String? emailUsuario,
    String? emailNormalizado,
  }) {
    return Convidado(
      idConvidado: idConvidado ?? this.idConvidado,
      idEvento: idEvento ?? this.idEvento,
      nome: nome ?? this.nome,
      contato: contato ?? this.contato,
      email: email ?? this.email,
      status: status ?? this.status,
      tipoConvidado: tipoConvidado ?? this.tipoConvidado,
      idGrupo: idGrupo ?? this.idGrupo,
      nomeGrupo: nomeGrupo ?? this.nomeGrupo,
      idMesa: idMesa ?? this.idMesa,
      numeroMesa: numeroMesa ?? this.numeroMesa,
      ocupaAssento: ocupaAssento ?? this.ocupaAssento,
      cuidadoEspecial: cuidadoEspecial ?? this.cuidadoEspecial,
      dataEnvio: dataEnvio ?? this.dataEnvio,
      dataResposta: dataResposta ?? this.dataResposta,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      conviteToken: conviteToken ?? this.conviteToken,
      idUsuario: idUsuario ?? this.idUsuario,
      conviteStatus: conviteStatus ?? this.conviteStatus,
      emailUsuario: emailUsuario ?? this.emailUsuario,
      emailNormalizado: emailNormalizado ?? this.emailNormalizado,
    );
  }
}
