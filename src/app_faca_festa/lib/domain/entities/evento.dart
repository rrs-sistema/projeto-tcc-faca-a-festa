enum StatusEvento {
  rascunho,
  planejamento,
  confirmado,
  emAndamento,
  finalizado,
  adiado,
  cancelado,
}

extension StatusEventoExtension on StatusEvento {
  String get label {
    switch (this) {
      case StatusEvento.rascunho:
        return 'Rascunho';
      case StatusEvento.planejamento:
        return 'Em planejamento';
      case StatusEvento.confirmado:
        return 'Confirmado';
      case StatusEvento.emAndamento:
        return 'Em andamento';
      case StatusEvento.finalizado:
        return 'Finalizado';
      case StatusEvento.adiado:
        return 'Adiado';
      case StatusEvento.cancelado:
        return 'Cancelado';
    }
  }

  String get value => name;
}

/// Framework-independent representation of an event.
class Evento {
  final String idEvento;
  final String idTipoEvento;
  final String idUsuario;
  final String? idCidade;
  final String? nomeCidade;
  final String? uf;
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? nomePessoalPrincipal;
  final String nomeEvento;
  final String localEvento;
  final DateTime data;
  final String? hora;
  final double? custoEstimado;
  final int? totalConvidados;
  final int? totalAdultos;
  final int? totalCriancas;
  final int? totalBebes;
  final StatusEvento? status;
  final String? descricao;
  final String? mensagemConvidado;
  final bool ativo;
  final DateTime dataCadastro;
  final String? nomeNoiva;
  final String? nomeNoivo;
  final String? tipoCerimonia;
  final String? estiloCasamento;
  final List<String>? padrinhos;
  final String? nomeAniversariante;
  final int? idade;
  final String? tema;
  final String? nomeResponsavel;
  final String? nomeGestante;
  final String? nomeBebe;
  final String? tipoCha;
  final DateTime? dataPrevistaNascimento;
  final String? hashtagEvento;
  final String? siteEvento;
  final String? dressCode;

  Evento({
    required this.idEvento,
    required this.idTipoEvento,
    required this.idUsuario,
    required this.nomeEvento,
    required this.localEvento,
    required this.data,
    this.nomePessoalPrincipal,
    this.idCidade,
    this.nomeCidade,
    this.uf,
    this.hora,
    this.custoEstimado,
    this.totalConvidados,
    this.totalAdultos,
    this.totalCriancas,
    this.totalBebes,
    this.status = StatusEvento.planejamento,
    this.descricao,
    this.mensagemConvidado,
    this.cep,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.ativo = true,
    DateTime? dataCadastro,
    this.nomeNoiva,
    this.nomeNoivo,
    this.tipoCerimonia,
    this.estiloCasamento,
    this.padrinhos,
    this.nomeAniversariante,
    this.idade,
    this.tema,
    this.nomeResponsavel,
    this.nomeGestante,
    this.nomeBebe,
    this.tipoCha,
    this.dataPrevistaNascimento,
    this.hashtagEvento,
    this.siteEvento,
    this.dressCode,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  int get totalAdultosCalculado => totalAdultos ?? 0;

  int get totalCriancasCalculado => totalCriancas ?? 0;

  int get totalBebesCalculado => totalBebes ?? 0;

  int get totalConvidadosPorTipo =>
      totalAdultosCalculado + totalCriancasCalculado + totalBebesCalculado;

  int get totalConvidadosCalculado {
    if (totalConvidados != null && totalConvidados! > 0) {
      return totalConvidados!;
    }
    return totalConvidadosPorTipo;
  }

  bool get possuiQuantidadePorTipo => totalConvidadosPorTipo > 0;
}
