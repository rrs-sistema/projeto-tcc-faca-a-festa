import 'package:cloud_firestore/cloud_firestore.dart';

class ConvidadoModel {
  final String idConvidado;
  final String idEvento;
  final String nome;
  final String? email;
  final String status; // P (pendente), C (confirmado), N (não vai)
  final DateTime? dataResposta;
  final bool? adulto; // true = adulto, false = criança

  const ConvidadoModel({
    required this.idConvidado,
    required this.idEvento,
    required this.nome,
    this.email,
    this.status = 'P',
    this.dataResposta,
    this.adulto,
  });

  /// 🔹 Conversão para Firebase / API REST
  Map<String, dynamic> toMap() {
    return {
      'id_convidado': idConvidado,
      'id_evento_evento': idEvento,
      'nome': nome,
      'email': email,
      'status': status,
      'data_resposta': dataResposta != null ? Timestamp.fromDate(dataResposta!) : null,
      'adulto': adulto,
    };
  }

  /// 🔹 Conversão a partir do Firestore
  factory ConvidadoModel.fromMap(Map<String, dynamic> map) {
    return ConvidadoModel(
      idConvidado: map['id_convidado'] ?? '',
      idEvento: map['id_evento_evento'] ?? '',
      nome: map['nome'] ?? '',
      email: map['email'],
      status: map['status'] ?? 'P',
      dataResposta:
          map['data_resposta'] is Timestamp ? (map['data_resposta'] as Timestamp).toDate() : null,
      adulto: map['adulto'],
    );
  }

  /// 🔹 Atualização parcial
  ConvidadoModel copyWith({
    String? nome,
    String? email,
    String? status,
    DateTime? dataResposta,
    bool? adulto,
  }) {
    return ConvidadoModel(
      idConvidado: idConvidado,
      idEvento: idEvento,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      status: status ?? this.status,
      dataResposta: dataResposta ?? this.dataResposta,
      adulto: adulto ?? this.adulto,
    );
  }

  /// 🔹 Status legível
  String get statusDescricao {
    switch (status) {
      case 'C':
        return 'Confirmado';
      case 'N':
        return 'Não vai';
      default:
        return 'Pendente';
    }
  }
}
