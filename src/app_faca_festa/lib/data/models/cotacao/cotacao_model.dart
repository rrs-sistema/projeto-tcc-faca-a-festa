import 'package:cloud_firestore/cloud_firestore.dart';

class CotacaoModel {
  final int idCotacao;
  final String? descricao;
  final DateTime? dataCotacao;
  final DateTime dataCadastro;

  CotacaoModel({
    required this.idCotacao,
    this.descricao,
    this.dataCotacao,
    DateTime? dataCadastro,
  }) : dataCadastro = dataCadastro ?? DateTime.now();

  /// 🔹 Conversão para Firebase / API
  Map<String, dynamic> toMap() {
    return {
      'id': idCotacao,
      'descricao': descricao,
      'data_cotacao': dataCotacao != null ? Timestamp.fromDate(dataCotacao!) : null,
      'data_cadastro': Timestamp.fromDate(dataCadastro),
    };
  }

  /// 🔹 Conversão a partir do Firestore
  factory CotacaoModel.fromMap(Map<String, dynamic> map) {
    return CotacaoModel(
      idCotacao: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      descricao: map['descricao'],
      dataCotacao: map['data_cotacao'] is Timestamp
          ? (map['data_cotacao'] as Timestamp).toDate()
          : DateTime.tryParse(map['data_cotacao']?.toString() ?? ''),
      dataCadastro: map['data_cadastro'] is Timestamp
          ? (map['data_cadastro'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  CotacaoModel copyWith({
    String? descricao,
    DateTime? dataCotacao,
  }) {
    return CotacaoModel(
      idCotacao: idCotacao,
      descricao: descricao ?? this.descricao,
      dataCotacao: dataCotacao ?? this.dataCotacao,
      dataCadastro: dataCadastro,
    );
  }
}
