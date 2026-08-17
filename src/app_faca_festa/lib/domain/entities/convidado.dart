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
  });

  bool get adulto => tipoConvidado == TipoConvidado.adulto;
  bool get crianca => tipoConvidado == TipoConvidado.crianca;
  bool get bebe => tipoConvidado == TipoConvidado.bebe;
  bool get confirmado => status == StatusConvidado.confirmado;

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
    );
  }
}
