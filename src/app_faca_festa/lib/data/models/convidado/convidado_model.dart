import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  String get firestoreValue {
    switch (this) {
      case StatusConvidado.pendente:
        return 'pendente';
      case StatusConvidado.confirmado:
        return 'confirmado';
      case StatusConvidado.recusado:
        return 'recusado';
    }
  }

  static StatusConvidado fromString(String? value) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'confirmado':
      case 'c':
        return StatusConvidado.confirmado;
      case 'recusado':
      case 'r':
        return StatusConvidado.recusado;
      case 'pendente':
      case 'p':
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

  String get firestoreValue {
    switch (this) {
      case TipoConvidado.adulto:
        return 'adulto';
      case TipoConvidado.crianca:
        return 'crianca';
      case TipoConvidado.bebe:
        return 'bebe';
    }
  }

  static TipoConvidado fromString(String? value) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'adulto':
        return TipoConvidado.adulto;
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
    if (adulto == false) return TipoConvidado.crianca;
    return TipoConvidado.adulto;
  }
}

class ConvidadoModel {
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

  const ConvidadoModel({
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

  Map<String, dynamic> toMap() {
    try {
      return {
        'id_convidado': idConvidado,
        'id_evento': idEvento,
        'nome': nome,
        'contato': contato,
        'email': email,
        'status': status.firestoreValue,
        'tipo_convidado': tipoConvidado.firestoreValue,
        // Campo legado opcional para compatibilidade com telas antigas.
        'adulto': tipoConvidado == TipoConvidado.adulto,
        'id_grupo': idGrupo,
        'nome_grupo': nomeGrupo,
        'id_mesa': idMesa,
        'numero_mesa': numeroMesa,
        'ocupa_assento': ocupaAssento,
        'cuidado_especial': cuidadoEspecial,
        'data_envio': dataEnvio != null ? Timestamp.fromDate(dataEnvio!) : null,
        'data_resposta': dataResposta != null ? Timestamp.fromDate(dataResposta!) : null,
        'data_cadastro': Timestamp.fromDate(dataCadastro),
        'data_atualizacao': Timestamp.fromDate(dataAtualizacao),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao listar os grupos toMap: ${e.toString()}');
      }
      return {};
    }
  }

  factory ConvidadoModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final tipoConvidado = map['tipo_convidado'] != null
        ? TipoConvidado.fromString(map['tipo_convidado'])
        : TipoConvidado.fromLegacyAdulto(map['adulto']);

    try {
      return ConvidadoModel(
        idConvidado: map['id_convidado']?.toString() ?? '',
        idEvento: map['id_evento']?.toString() ?? '',
        nome: map['nome']?.toString() ?? '',
        contato: map['contato']?.toString() ?? '',
        email: map['email']?.toString(),
        status: StatusConvidado.fromString(map['status']),
        tipoConvidado: tipoConvidado,
        idGrupo: map['id_grupo']?.toString(),
        nomeGrupo: map['nome_grupo']?.toString(),
        idMesa: map['id_mesa']?.toString(),
        numeroMesa: map['numero_mesa'] is num ? (map['numero_mesa'] as num).toInt() : null,
        ocupaAssento: map['ocupa_assento'] ?? tipoConvidado != TipoConvidado.bebe,
        cuidadoEspecial: map['cuidado_especial'] ?? false,
        dataEnvio: parseDate(map['data_envio']),
        dataResposta: parseDate(map['data_resposta']),
        dataCadastro: parseDate(map['data_cadastro']) ?? DateTime.now(),
        dataAtualizacao: parseDate(map['data_atualizacao']) ?? DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao listar os grupos fromMap: ${e.toString()}');
      }
      return ConvidadoModel(
          idConvidado: '',
          idEvento: '',
          nome: '',
          contato: '',
          dataCadastro: DateTime.now(),
          dataAtualizacao: DateTime.now());
    }
  }

  ConvidadoModel copyWith({
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
    DateTime? dataAtualizacao,
  }) {
    return ConvidadoModel(
      idConvidado: idConvidado,
      idEvento: idEvento,
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
      dataCadastro: dataCadastro,
      dataAtualizacao: dataAtualizacao ?? DateTime.now(),
    );
  }
}
