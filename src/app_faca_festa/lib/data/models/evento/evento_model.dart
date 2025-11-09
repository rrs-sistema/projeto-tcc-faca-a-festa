// ======================================================
// 🏷️ ENUM - Status do Evento
// ======================================================
import 'package:cloud_firestore/cloud_firestore.dart';

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

  String get value => toString().split('.').last;
}

// ======================================================
// 🗓️ MODELO - EventoModel
// ======================================================
class EventoModel {
  final String idEvento;
  final String idTipoEvento;
  final String idUsuario;

  // 🗺️ Localização
  final String? idCidade;
  final String? nomeCidade;
  final String? uf;
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? complemento;
  final String? bairro;

  // 📅 Informações gerais
  final String? nomePessoalPrincipal;
  final String nomeEvento;

  final String localEvento;
  final DateTime data;
  final String? hora;
  final double? custoEstimado;
  final StatusEvento? status;
  final String? descricao;

  // ⚙️ Controle
  final bool ativo;
  final DateTime dataCadastro;

  // 💍 Casamento
  final String? nomeNoiva;
  final String? nomeNoivo;
  final String? tipoCerimonia;
  final String? estiloCasamento;
  final List<String>? padrinhos;

  // 🎂 Aniversário / 🎈 Festa Infantil
  final String? nomeAniversariante;
  final int? idade;
  final String? tema;
  final String? nomeResponsavel;

  // 🍼 Chá de Bebê
  final String? nomeGestante;
  final String? nomeBebe;
  final String? tipoCha;
  final DateTime? dataPrevistaNascimento;

  // 🌐 Personalização
  final String? hashtagEvento;
  final String? siteEvento;
  final String? dressCode;

  EventoModel({
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
    this.status = StatusEvento.planejamento,
    this.descricao,
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
      'data': Timestamp.fromDate(data),
      'hora': hora,
      'custo_estimado': custoEstimado,
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
      'tema': tema,
      'nome_responsavel': nomeResponsavel,
      'nome_gestante': nomeGestante,
      'nome_bebe': nomeBebe,
      'tipo_cha': tipoCha,
      'data_prevista_nascimento':
          dataPrevistaNascimento != null ? Timestamp.fromDate(dataPrevistaNascimento!) : null,
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
      nomeEvento: map['nome_evento'] ?? '',
      nomePessoalPrincipal: map['nome_pessoa_principal'] ?? '',
      localEvento: map['local_evento'] ?? map['logradouro'],
      data: map['data'] is Timestamp
          ? (map['data'] as Timestamp).toDate()
          : DateTime.tryParse(map['data']?.toString() ?? '') ?? DateTime.now(),
      hora: map['hora'],
      custoEstimado:
          map['custo_estimado'] != null ? (map['custo_estimado'] as num).toDouble() : null,
      status: _parseStatus(map['status']),
      descricao: map['descricao'],
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
      padrinhos: map['padrinhos'] != null ? List<String>.from(map['padrinhos']) : null,
      nomeAniversariante: map['nome_aniversariante'],
      idade: map['idade'],
      tema: map['tema'],
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
    StatusEvento? status,
    String? descricao,
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
    String? tema,
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
      status: status ?? this.status,
      descricao: descricao ?? this.descricao,
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
      tema: tema ?? this.tema,
      nomeResponsavel: nomeResponsavel ?? this.nomeResponsavel,
      nomeGestante: nomeGestante ?? this.nomeGestante,
      nomeBebe: nomeBebe ?? this.nomeBebe,
      tipoCha: tipoCha ?? this.tipoCha,
      dataPrevistaNascimento: dataPrevistaNascimento ?? this.dataPrevistaNascimento,
      hashtagEvento: hashtagEvento ?? this.hashtagEvento,
      siteEvento: siteEvento ?? this.siteEvento,
      dressCode: dressCode ?? this.dressCode,
    );
  }
}
