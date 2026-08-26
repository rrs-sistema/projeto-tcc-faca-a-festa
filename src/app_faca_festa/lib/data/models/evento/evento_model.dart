import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/entities/evento.dart';
export '../../../domain/entities/evento.dart'
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
    return EventoModel(
      idEvento: map['id_evento'] ?? '',
      idTipoEvento: map['id_tipo_evento'] ?? '',
      idUsuario: map['id_usuario'] ?? '',
      idCidade: map['id_cidade']?.toString(),
      nomeCidade: map['nome_cidade'],
      uf: map['uf'],
      nomeEvento: map['nome_evento'] ?? map['nome'] ?? '',
      nomePessoalPrincipal: map['nome_pessoa_principal'] ?? '',
      localEvento: map['local_evento'] ?? map['logradouro'] ?? '',
      data: map['data'] is Timestamp
          ? (map['data'] as Timestamp).toDate()
          : DateTime.tryParse(map['data']?.toString() ?? '') ?? DateTime.now(),
      hora: map['hora'],
      custoEstimado: map['custo_estimado'] != null
          ? (map['custo_estimado'] as num).toDouble()
          : null,
      totalConvidados: _parseTotalConvidados(map),
      totalAdultos: _parseIntNullable(map['total_adultos']),
      totalCriancas: _parseIntNullable(map['total_criancas']),
      totalBebes: _parseIntNullable(map['total_bebes']),
      status: _parseStatus(map['status']),
      descricao: map['descricao'],
      mensagemConvidado: map['mensagem'] ?? map['mensagem_convidado'],
      cep: map['cep'],
      logradouro: map['logradouro'],
      numero: map['numero'],
      complemento: map['complemento'],
      bairro: map['bairro'],
      ativo: map['ativo'] ?? true,
      dataCadastro: map['data_cadastro'] is Timestamp
          ? (map['data_cadastro'] as Timestamp).toDate()
          : DateTime.now(),
      nomeNoiva: map['nome_noiva'],
      nomeNoivo: map['nome_noivo'],
      tipoCerimonia: map['tipo_cerimonia'],
      estiloCasamento: map['estilo_casamento'],
      padrinhos:
          map['padrinhos'] != null ? List<String>.from(map['padrinhos']) : null,
      nomeAniversariante: map['nome_aniversariante'],
      idade: map['idade'],
      idTema: map['id_tema']?.toString(),
      tema: map['tema'],
      imagemCapaUrl: map['imagem_capa_url']?.toString(),
      rotuloBanner: map['rotulo_banner']?.toString(),
      nomeResponsavel: map['nome_responsavel'],
      nomeGestante: map['nome_gestante'],
      nomeBebe: map['nome_bebe'],
      tipoCha: map['tipo_cha'],
      dataPrevistaNascimento: map['data_prevista_nascimento'] is Timestamp
          ? (map['data_prevista_nascimento'] as Timestamp).toDate()
          : null,
      hashtagEvento: map['hashtag_evento'],
      siteEvento: map['site_evento'],
      dressCode: map['dress_code'],
    );
  }

  // ======================================================
  // 🔹 Funções auxiliares
  // ======================================================

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

  // ======================================================
  // 🔹 Função auxiliar - converte string em enum
  // ======================================================
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
  EventoModel copyWith({
    String? idTipoEvento,
    String? idUsuario,
    String? idCidade,
    String? nomeCidade,
    String? uf,
    String? nomeEvento,
    String? nomePessoalPrincipal,
    String? localEvento,
    DateTime? data,
    String? hora,
    double? custoEstimado,
    int? totalConvidados,
    int? totalAdultos,
    int? totalCriancas,
    int? totalBebes,
    StatusEvento? status,
    String? descricao,
    String? mensagemConvidado,
    String? cep,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    bool? ativo,
    DateTime? dataCadastro,
    String? nomeNoiva,
    String? nomeNoivo,
    String? tipoCerimonia,
    String? estiloCasamento,
    List<String>? padrinhos,
    String? nomeAniversariante,
    int? idade,
    String? idTema,
    String? tema,
    String? imagemCapaUrl,
    bool limparImagemCapaUrl = false,
    String? rotuloBanner,
    bool limparRotuloBanner = false,
    String? nomeResponsavel,
    String? nomeGestante,
    String? nomeBebe,
    String? tipoCha,
    DateTime? dataPrevistaNascimento,
    String? hashtagEvento,
    String? siteEvento,
    String? dressCode,
  }) {
    return EventoModel(
      idEvento: idEvento,
      idTipoEvento: idTipoEvento ?? this.idTipoEvento,
      idUsuario: idUsuario ?? this.idUsuario,
      idCidade: idCidade ?? this.idCidade,
      nomeCidade: nomeCidade ?? this.nomeCidade,
      uf: uf ?? this.uf,
      nomePessoalPrincipal: nomePessoalPrincipal ?? this.nomePessoalPrincipal,
      nomeEvento: nomeEvento ?? this.nomeEvento,
      localEvento: localEvento ?? this.localEvento,
      data: data ?? this.data,
      hora: hora ?? this.hora,
      custoEstimado: custoEstimado ?? this.custoEstimado,
      totalConvidados: totalConvidados ?? this.totalConvidados,
      totalAdultos: totalAdultos ?? this.totalAdultos,
      totalCriancas: totalCriancas ?? this.totalCriancas,
      totalBebes: totalBebes ?? this.totalBebes,
      status: status ?? this.status,
      descricao: descricao ?? this.descricao,
      mensagemConvidado: mensagemConvidado ?? this.mensagemConvidado,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      ativo: ativo ?? this.ativo,
      dataCadastro: dataCadastro ?? this.dataCadastro,
      nomeNoiva: nomeNoiva ?? this.nomeNoiva,
      nomeNoivo: nomeNoivo ?? this.nomeNoivo,
      tipoCerimonia: tipoCerimonia ?? this.tipoCerimonia,
      estiloCasamento: estiloCasamento ?? this.estiloCasamento,
      padrinhos: padrinhos ?? this.padrinhos,
      nomeAniversariante: nomeAniversariante ?? this.nomeAniversariante,
      idade: idade ?? this.idade,
      idTema: idTema ?? this.idTema,
      tema: tema ?? this.tema,
      imagemCapaUrl:
          limparImagemCapaUrl ? null : (imagemCapaUrl ?? this.imagemCapaUrl),
      rotuloBanner:
          limparRotuloBanner ? null : (rotuloBanner ?? this.rotuloBanner),
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      nomeGestante: nomeGestante ?? this.nomeGestante,
      nomeBebe: nomeBebe ?? this.nomeBebe,
      tipoCha: tipoCha ?? this.tipoCha,
      dataPrevistaNascimento:
          dataPrevistaNascimento ?? this.dataPrevistaNascimento,
      hashtagEvento: hashtagEvento ?? this.hashtagEvento,
      siteEvento: siteEvento ?? this.siteEvento,
      dressCode: dressCode ?? this.dressCode,
    );
  }
}
