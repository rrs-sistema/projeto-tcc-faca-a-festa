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
  final DateTime? dataResposta;
  final bool? adulto; // true = adulto, false = criança
  final String? grupoMesa; // Ex: "Família", "Principal", "Amigos"

  const ConvidadoModel({
    required this.idConvidado,
    required this.idEvento,
    required this.nome,
    required this.contato,
    this.email,
    this.status = StatusConvidado.pendente,
    this.dataResposta,
    this.adulto,
    this.grupoMesa,
  });

  Map<String, dynamic> toMap() => {
        'id_convidado': idConvidado,
        'id_evento': idEvento,
        'nome': nome,
        'contato': contato,
        'email': email,
        'status': status.firestoreValue,
        'data_resposta': dataResposta != null ? Timestamp.fromDate(dataResposta!) : null,
        'adulto': adulto,
        'grupo_mesa': grupoMesa,
      };

  factory ConvidadoModel.fromMap(Map<String, dynamic> map) {
    return ConvidadoModel(
      idConvidado: map['id_convidado'] ?? '',
      idEvento: map['id_evento'] ?? '',
      nome: map['nome'] ?? '',
      contato: map['contato'] ?? '',
      email: map['email'],
      status: StatusConvidado.fromString(map['status']),
      dataResposta:
          map['data_resposta'] is Timestamp ? (map['data_resposta'] as Timestamp).toDate() : null,
      adulto: map['adulto'],
      grupoMesa: map['grupo_mesa'],
    );
  }

  /// 🔹 Atualização parcial
  ConvidadoModel copyWith({
    String? nome,
    String? contato,
    String? email,
    StatusConvidado? status,
    DateTime? dataResposta,
    bool? adulto,
    String? grupoMesa,
  }) {
    return ConvidadoModel(
      idConvidado: idConvidado,
      idEvento: idEvento,
      nome: nome ?? this.nome,
      contato: contato ?? this.contato,
      email: email ?? this.email,
      status: status ?? this.status,
      dataResposta: dataResposta ?? this.dataResposta,
      adulto: adulto ?? this.adulto,
      grupoMesa: grupoMesa ?? this.grupoMesa,
    );
  }
}
