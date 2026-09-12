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
  final String? idTema;
  final String? tema;

  /// Capa personalizada do organizador; se vazia, usa a capa do tema.
  final String? imagemCapaUrl;

  /// Texto do topo do banner; se vazio, usa "tipo · tema".
  final String? rotuloBanner;
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
    this.idTema,
    this.tema,
    this.imagemCapaUrl,
    this.rotuloBanner,
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

  /// Texto exibido no topo do banner (personalizado ou tipo · tema).
  String rotuloBannerEfetivo({String? nomeTipoEvento}) {
    final personalizado = (rotuloBanner ?? '').trim();
    if (personalizado.isNotEmpty) return personalizado;
    final tipo = (nomeTipoEvento ?? '').trim();
    final nomeTema = (tema ?? '').trim();
    return [
      tipo.isEmpty ? 'Faça a Festa' : tipo,
      if (nomeTema.isNotEmpty) nomeTema,
    ].join(' · ');
  }

  Evento copyWith({
    String? idEvento,
    String? idTipoEvento,
    String? idUsuario,
    String? idCidade,
    bool limparIdCidade = false,
    String? nomeCidade,
    bool limparNomeCidade = false,
    String? uf,
    bool limparUf = false,
    String? cep,
    bool limparCep = false,
    String? logradouro,
    bool limparLogradouro = false,
    String? numero,
    bool limparNumero = false,
    String? complemento,
    bool limparComplemento = false,
    String? bairro,
    bool limparBairro = false,
    String? nomePessoalPrincipal,
    bool limparNomePessoalPrincipal = false,
    String? nomeEvento,
    String? localEvento,
    DateTime? data,
    String? hora,
    bool limparHora = false,
    double? custoEstimado,
    bool limparCustoEstimado = false,
    int? totalConvidados,
    bool limparTotalConvidados = false,
    int? totalAdultos,
    bool limparTotalAdultos = false,
    int? totalCriancas,
    bool limparTotalCriancas = false,
    int? totalBebes,
    bool limparTotalBebes = false,
    StatusEvento? status,
    String? descricao,
    bool limparDescricao = false,
    String? mensagemConvidado,
    bool limparMensagemConvidado = false,
    bool? ativo,
    DateTime? dataCadastro,
    String? nomeNoiva,
    bool limparNomeNoiva = false,
    String? nomeNoivo,
    bool limparNomeNoivo = false,
    String? tipoCerimonia,
    bool limparTipoCerimonia = false,
    String? estiloCasamento,
    bool limparEstiloCasamento = false,
    List<String>? padrinhos,
    bool limparPadrinhos = false,
    String? nomeAniversariante,
    bool limparNomeAniversariante = false,
    int? idade,
    bool limparIdade = false,
    String? idTema,
    bool limparIdTema = false,
    String? tema,
    bool limparTema = false,
    String? imagemCapaUrl,
    bool limparImagemCapaUrl = false,
    String? rotuloBanner,
    bool limparRotuloBanner = false,
    String? nomeResponsavel,
    bool limparNomeResponsavel = false,
    String? nomeGestante,
    bool limparNomeGestante = false,
    String? nomeBebe,
    bool limparNomeBebe = false,
    String? tipoCha,
    bool limparTipoCha = false,
    DateTime? dataPrevistaNascimento,
    bool limparDataPrevistaNascimento = false,
    String? hashtagEvento,
    bool limparHashtagEvento = false,
    String? siteEvento,
    bool limparSiteEvento = false,
    String? dressCode,
    bool limparDressCode = false,
  }) {
    return Evento(
      idEvento: idEvento ?? this.idEvento,
      idTipoEvento: idTipoEvento ?? this.idTipoEvento,
      idUsuario: idUsuario ?? this.idUsuario,
      idCidade: limparIdCidade ? null : (idCidade ?? this.idCidade),
      nomeCidade: limparNomeCidade ? null : (nomeCidade ?? this.nomeCidade),
      uf: limparUf ? null : (uf ?? this.uf),
      cep: limparCep ? null : (cep ?? this.cep),
      logradouro: limparLogradouro ? null : (logradouro ?? this.logradouro),
      numero: limparNumero ? null : (numero ?? this.numero),
      complemento: limparComplemento ? null : (complemento ?? this.complemento),
      bairro: limparBairro ? null : (bairro ?? this.bairro),
      nomePessoalPrincipal: limparNomePessoalPrincipal
          ? null
          : (nomePessoalPrincipal ?? this.nomePessoalPrincipal),
      nomeEvento: nomeEvento ?? this.nomeEvento,
      localEvento: localEvento ?? this.localEvento,
      data: data ?? this.data,
      hora: limparHora ? null : (hora ?? this.hora),
      custoEstimado:
          limparCustoEstimado ? null : (custoEstimado ?? this.custoEstimado),
      totalConvidados: limparTotalConvidados
          ? null
          : (totalConvidados ?? this.totalConvidados),
      totalAdultos:
          limparTotalAdultos ? null : (totalAdultos ?? this.totalAdultos),
      totalCriancas:
          limparTotalCriancas ? null : (totalCriancas ?? this.totalCriancas),
      totalBebes: limparTotalBebes ? null : (totalBebes ?? this.totalBebes),
      status: status ?? this.status,
      descricao: limparDescricao ? null : (descricao ?? this.descricao),
      mensagemConvidado: limparMensagemConvidado
          ? null
          : (mensagemConvidado ?? this.mensagemConvidado),
      ativo: ativo ?? this.ativo,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      nomeNoiva: limparNomeNoiva ? null : (nomeNoiva ?? this.nomeNoiva),
      nomeNoivo: limparNomeNoivo ? null : (nomeNoivo ?? this.nomeNoivo),
      tipoCerimonia:
          limparTipoCerimonia ? null : (tipoCerimonia ?? this.tipoCerimonia),
      estiloCasamento: limparEstiloCasamento
          ? null
          : (estiloCasamento ?? this.estiloCasamento),
      padrinhos: limparPadrinhos ? null : (padrinhos ?? this.padrinhos),
      nomeAniversariante: limparNomeAniversariante
          ? null
          : (nomeAniversariante ?? this.nomeAniversariante),
      idade: limparIdade ? null : (idade ?? this.idade),
      idTema: limparIdTema ? null : (idTema ?? this.idTema),
      tema: limparTema ? null : (tema ?? this.tema),
      imagemCapaUrl:
          limparImagemCapaUrl ? null : (imagemCapaUrl ?? this.imagemCapaUrl),
      rotuloBanner:
          limparRotuloBanner ? null : (rotuloBanner ?? this.rotuloBanner),
      nomeResponsavel: limparNomeResponsavel
          ? null
          : (nomeResponsavel ?? this.nomeResponsavel),
      nomeGestante:
          limparNomeGestante ? null : (nomeGestante ?? this.nomeGestante),
      nomeBebe: limparNomeBebe ? null : (nomeBebe ?? this.nomeBebe),
      tipoCha: limparTipoCha ? null : (tipoCha ?? this.tipoCha),
      dataPrevistaNascimento: limparDataPrevistaNascimento
          ? null
          : (dataPrevistaNascimento ?? this.dataPrevistaNascimento),
      hashtagEvento:
          limparHashtagEvento ? null : (hashtagEvento ?? this.hashtagEvento),
      siteEvento: limparSiteEvento ? null : (siteEvento ?? this.siteEvento),
      dressCode: limparDressCode ? null : (dressCode ?? this.dressCode),
    );
  }
}
