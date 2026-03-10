import 'package:cloud_firestore/cloud_firestore.dart';

//P (pendente), C (confirmado), N (não vai)
enum StatusConvidado {
  pendente,
  confirmado,
  recusado;

  /// 🔹 Retorna uma string legível para a interface
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

  /// 🔹 Retorna o valor usado no Firestore
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

  /// 🔹 Converte uma string do Firestore em enum
  static StatusConvidado fromString(String? value) {
    if (value == null) return StatusConvidado.pendente;

    final normalized = value.trim().toLowerCase();

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

class ConvidadoModel {
  final String idConvidado;
  final String idEvento;
  final String nome;
  final String contato;
  final String? email;
  final StatusConvidado status;
  final DateTime? dataEnvio;
  final DateTime? dataResposta;
  final String? grupoMesa;
  final bool? adulto;
  final bool? cuidadoEspecial;

  const ConvidadoModel({
    required this.idConvidado,
    required this.idEvento,
    required this.nome,
    required this.contato,
    this.email,
    this.status = StatusConvidado.pendente,
    this.dataEnvio,
    this.dataResposta,
    this.adulto,
    this.grupoMesa,
    this.cuidadoEspecial,
  });

  Map<String, dynamic> toMap() => {
        'id_convidado': idConvidado,
        'id_evento': idEvento,
        'nome': nome,
        'contato': contato,
        'email': email,
        'status': status.firestoreValue,
        'data_envio': dataEnvio != null ? Timestamp.fromDate(dataEnvio!) : null,
        'data_resposta': dataResposta != null ? Timestamp.fromDate(dataResposta!) : null,
        'adulto': adulto,
        'grupo_mesa': grupoMesa,
        'cuidado_especial': cuidadoEspecial,
      };

  factory ConvidadoModel.fromMap(Map<String, dynamic> map) {
    final dados = map.containsKey('data_envio');
    return ConvidadoModel(
      idConvidado: map['id_convidado'] ?? '',
      idEvento: map['id_evento'] ?? '',
      nome: map['nome'] ?? '',
      contato: map['contato'] ?? '',
      email: map['email'],
      status: StatusConvidado.fromString(map['status']),
      dataEnvio: dados
          ? (map['data_envio'] is Timestamp ? (map['data_envio'] as Timestamp).toDate() : null)
          : null,
      dataResposta:
          map['data_resposta'] is Timestamp ? (map['data_resposta'] as Timestamp).toDate() : null,
      adulto: map['adulto'],
      grupoMesa: map['grupo_mesa'],
      cuidadoEspecial: map['cuidado_especial'],
    );
  }

  /// 🔹 Atualização parcial
  ConvidadoModel copyWith({
    String? nome,
    String? contato,
    String? email,
    StatusConvidado? status,
    DateTime? dataEnvio,
    DateTime? dataResposta,
    bool? adulto,
    String? grupoMesa,
    bool? cuidadoEspecial,
  }) {
    return ConvidadoModel(
      idConvidado: idConvidado,
      idEvento: idEvento,
      nome: nome ?? this.nome,
      contato: contato ?? this.contato,
      email: email ?? this.email,
      status: status ?? this.status,
      dataEnvio: dataEnvio ?? this.dataEnvio,
      dataResposta: dataResposta ?? this.dataResposta,
      adulto: adulto ?? this.adulto,
      grupoMesa: grupoMesa ?? this.grupoMesa,
      cuidadoEspecial: cuidadoEspecial ?? this.cuidadoEspecial,
    );
  }
}
