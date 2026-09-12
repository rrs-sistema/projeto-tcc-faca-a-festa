import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/evento.dart';
export 'package:app_faca_festa/domain/entities/evento.dart'
    show Evento, StatusEvento, StatusEventoExtension;

// ======================================================
// 🗓️ MODELO - EventoModel
// ======================================================
class EventoModel extends Evento {
  EventoModel({
    required super.idEvento,
    required super.idTipoEvento,
    required super.idUsuario,
    required super.nomeEvento,
    required super.localEvento,
    required super.data,
    super.nomePessoalPrincipal,
    super.idCidade,
    super.nomeCidade,
    super.uf,
    super.hora,
    super.custoEstimado,
    super.totalConvidados,
    super.totalAdultos,
    super.totalCriancas,
    super.totalBebes,
    super.status,
    super.descricao,
    super.mensagemConvidado,
    super.cep,
    super.logradouro,
    super.numero,
    super.complemento,
    super.bairro,
    super.ativo,
    super.dataCadastro,
    super.nomeNoiva,
    super.nomeNoivo,
    super.tipoCerimonia,
    super.estiloCasamento,
    super.padrinhos,
    super.nomeAniversariante,
    super.idade,
    super.idTema,
    super.tema,
    super.imagemCapaUrl,
    super.rotuloBanner,
    super.nomeResponsavel,
    super.nomeGestante,
    super.nomeBebe,
    super.tipoCha,
    super.dataPrevistaNascimento,
    super.hashtagEvento,
    super.siteEvento,
    super.dressCode,
  });

  factory EventoModel.fromEntity(Evento evento) {
    return EventoModel(
      idEvento: evento.idEvento,
      idTipoEvento: evento.idTipoEvento,
      idUsuario: evento.idUsuario,
      nomeEvento: evento.nomeEvento,
      localEvento: evento.localEvento,
      data: evento.data,
      nomePessoalPrincipal: evento.nomePessoalPrincipal,
      idCidade: evento.idCidade,
      nomeCidade: evento.nomeCidade,
      uf: evento.uf,
      hora: evento.hora,
      custoEstimado: evento.custoEstimado,
      totalConvidados: evento.totalConvidados,
      totalAdultos: evento.totalAdultos,
      totalCriancas: evento.totalCriancas,
      totalBebes: evento.totalBebes,
      status: evento.status,
      descricao: evento.descricao,
      mensagemConvidado: evento.mensagemConvidado,
      cep: evento.cep,
      logradouro: evento.logradouro,
      numero: evento.numero,
      complemento: evento.complemento,
      bairro: evento.bairro,
      ativo: evento.ativo,
      dataCadastro: evento.dataCadastro,
      nomeNoiva: evento.nomeNoiva,
      nomeNoivo: evento.nomeNoivo,
      tipoCerimonia: evento.tipoCerimonia,
      estiloCasamento: evento.estiloCasamento,
      padrinhos: evento.padrinhos,
      nomeAniversariante: evento.nomeAniversariante,
      idade: evento.idade,
      idTema: evento.idTema,
      tema: evento.tema,
      imagemCapaUrl: evento.imagemCapaUrl,
      rotuloBanner: evento.rotuloBanner,
      nomeResponsavel: evento.nomeResponsavel,
      nomeGestante: evento.nomeGestante,
      nomeBebe: evento.nomeBebe,
      tipoCha: evento.tipoCha,
      dataPrevistaNascimento: evento.dataPrevistaNascimento,
      hashtagEvento: evento.hashtagEvento,
      siteEvento: evento.siteEvento,
      dressCode: evento.dressCode,
    );
  }

  // ======================================================
  // 🔹 Conversão para Firestore
  // ======================================================
  Map<String, dynamic> toMap() {
    return {
      'id_evento': idEvento,
      'id_tipo_evento': idTipoEvento,
      'id_usuario': idUsuario,
      'id_cidade': idCidade,
      'nome_cidade': nomeCidade,
      'uf': uf,
      'nome_pessoa_principal': nomePessoalPrincipal,
      'nome_evento': nomeEvento,
      'local_evento': localEvento,
      'data': Timestamp.fromDate(data),
      'hora': hora,
      'custo_estimado': custoEstimado,
      'total_convidados': totalConvidadosCalculado,
      'total_adultos': totalAdultosCalculado,
      'total_criancas': totalCriancasCalculado,
      'total_bebes': totalBebesCalculado,
      'status': status?.value ?? StatusEvento.planejamento.value,
      'descricao': descricao,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'ativo': ativo,
      'data_cadastro': Timestamp.fromDate(dataCadastro),

      // Campos específicos
      'nome_noiva': nomeNoiva,
      'nome_noivo': nomeNoivo,
      'tipo_cerimonia': tipoCerimonia,
      'estilo_casamento': estiloCasamento,
      'padrinhos': padrinhos,
      'nome_aniversariante': nomeAniversariante,
      'idade': idade,
      'id_tema': idTema,
      'tema': tema,
      'imagem_capa_url': imagemCapaUrl,
      'rotulo_banner': rotuloBanner,
      'nome_responsavel': nomeResponsavel,
      'nome_gestante': nomeGestante,
      'nome_bebe': nomeBebe,
      'tipo_cha': tipoCha,
      'data_prevista_nascimento': dataPrevistaNascimento != null
          ? Timestamp.fromDate(dataPrevistaNascimento!)
          : null,
      'hashtag_evento': hashtagEvento,
      'site_evento': siteEvento,
      'dress_code': dressCode,
    };
  }

  // ======================================================
  // 🔹 Conversão do Firestore
  // ======================================================
  factory EventoModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      try {
        final converted = value?.toDate();
        if (converted is DateTime) return converted;
      } catch (_) {
        // Valor não é um Timestamp-like; tenta parse por texto abaixo.
      }
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return EventoModel(
      idEvento: map['id_evento']?.toString() ?? '',
      idTipoEvento: map['id_tipo_evento']?.toString() ?? '',
      idUsuario: map['id_usuario']?.toString() ?? '',
      idCidade: map['id_cidade']?.toString(),
      nomeCidade: map['nome_cidade']?.toString(),
      uf: map['uf']?.toString(),
      nomeEvento:
          map['nome_evento']?.toString() ?? map['nome']?.toString() ?? '',
      nomePessoalPrincipal: map['nome_pessoa_principal']?.toString() ?? '',
      localEvento: map['local_evento']?.toString() ??
          map['logradouro']?.toString() ??
          '',
      data: parseDate(map['data']) ?? DateTime.now(),
      hora: map['hora']?.toString(),
      custoEstimado: map['custo_estimado'] != null
          ? (map['custo_estimado'] as num).toDouble()
          : null,
      totalConvidados: _parseTotalConvidados(map),
      totalAdultos: _parseIntNullable(map['total_adultos']),
      totalCriancas: _parseIntNullable(map['total_criancas']),
      totalBebes: _parseIntNullable(map['total_bebes']),
      status: _parseStatus(map['status']),
      descricao: map['descricao']?.toString(),
      mensagemConvidado:
          map['mensagem']?.toString() ?? map['mensagem_convidado']?.toString(),
      cep: map['cep']?.toString(),
      logradouro: map['logradouro']?.toString(),
      numero: map['numero']?.toString(),
      complemento: map['complemento']?.toString(),
      bairro: map['bairro']?.toString(),
      ativo: map['ativo'] ?? true,
      dataCadastro: parseDate(map['data_cadastro']) ?? DateTime.now(),
      nomeNoiva: map['nome_noiva']?.toString(),
      nomeNoivo: map['nome_noivo']?.toString(),
      tipoCerimonia: map['tipo_cerimonia']?.toString(),
      estiloCasamento: map['estilo_casamento']?.toString(),
      padrinhos:
          map['padrinhos'] != null ? List<String>.from(map['padrinhos']) : null,
      nomeAniversariante: map['nome_aniversariante']?.toString(),
      idade: _parseIntNullable(map['idade']),
      idTema: map['id_tema']?.toString(),
      tema: map['tema']?.toString(),
      imagemCapaUrl: map['imagem_capa_url']?.toString(),
      rotuloBanner: map['rotulo_banner']?.toString(),
      nomeResponsavel: map['nome_responsavel']?.toString(),
      nomeGestante: map['nome_gestante']?.toString(),
      nomeBebe: map['nome_bebe']?.toString(),
      tipoCha: map['tipo_cha']?.toString(),
      dataPrevistaNascimento: parseDate(map['data_prevista_nascimento']),
      hashtagEvento: map['hashtag_evento']?.toString(),
      siteEvento: map['site_evento']?.toString(),
      dressCode: map['dress_code']?.toString(),
    );
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int _parseTotalConvidados(Map<String, dynamic> map) {
    final total = _parseIntNullable(map['total_convidados']);
    if (total != null && total > 0) return total;

    final adultos = _parseIntNullable(map['total_adultos']) ?? 0;
    final criancas = _parseIntNullable(map['total_criancas']) ?? 0;
    final bebes = _parseIntNullable(map['total_bebes']) ?? 0;

    return adultos + criancas + bebes;
  }

  static StatusEvento _parseStatus(dynamic value) {
    if (value == null) return StatusEvento.planejamento;
    final str = value.toString().toLowerCase();
    return StatusEvento.values.firstWhere(
      (e) => e.value == str,
      orElse: () => StatusEvento.planejamento,
    );
  }

  // ======================================================
  // 🔹 copyWith
  // ======================================================
  @override
  EventoModel copyWith({
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
    String? nomeEvento,
    String? nomePessoalPrincipal,
    bool limparNomePessoalPrincipal = false,
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
    return EventoModel(
      idEvento: idEvento ?? this.idEvento,
      idTipoEvento: idTipoEvento ?? this.idTipoEvento,
      idUsuario: idUsuario ?? this.idUsuario,
      idCidade: limparIdCidade ? null : (idCidade ?? this.idCidade),
      nomeCidade: limparNomeCidade ? null : (nomeCidade ?? this.nomeCidade),
      uf: limparUf ? null : (uf ?? this.uf),
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
      cep: limparCep ? null : (cep ?? this.cep),
      logradouro: limparLogradouro ? null : (logradouro ?? this.logradouro),
      numero: limparNumero ? null : (numero ?? this.numero),
      complemento: limparComplemento ? null : (complemento ?? this.complemento),
      bairro: limparBairro ? null : (bairro ?? this.bairro),
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
