import 'package:cloud_firestore/cloud_firestore.dart';

class FornecedorInteracaoModel {
  final String id;
  final String idUsuario;
  final String idEvento;
  final String idFornecedor;
  final String acao;
  final int peso;
  final String? tipoEventoId;
  final String? tipoEventoNome;
  final String? cidade;
  final DateTime? createdAt;

  const FornecedorInteracaoModel({
    required this.id,
    required this.idUsuario,
    required this.idEvento,
    required this.idFornecedor,
    required this.acao,
    required this.peso,
    this.tipoEventoId,
    this.tipoEventoNome,
    this.cidade,
    this.createdAt,
  });

  factory FornecedorInteracaoModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return FornecedorInteracaoModel(
      id: documentId ?? (map['id'] ?? '').toString(),
      idUsuario: (map['id_usuario'] ?? '').toString(),
      idEvento: (map['id_evento'] ?? '').toString(),
      idFornecedor: (map['id_fornecedor'] ?? '').toString(),
      acao: (map['acao'] ?? '').toString(),
      peso: (map['peso'] as num?)?.toInt() ?? 0,
      tipoEventoId: map['tipo_evento_id']?.toString(),
      tipoEventoNome: map['tipo_evento_nome']?.toString(),
      cidade: map['cidade']?.toString(),
      createdAt: parseDate(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_usuario': idUsuario,
      'id_evento': idEvento,
      'id_fornecedor': idFornecedor,
      'acao': acao,
      'peso': peso,
      'tipo_evento_id': tipoEventoId,
      'tipo_evento_nome': tipoEventoNome,
      'cidade': cidade,
      'created_at': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }
}
