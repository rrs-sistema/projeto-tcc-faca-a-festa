import 'package:cloud_firestore/cloud_firestore.dart';

class EventoAdminModel {
  final String id;
  final String nome;
  final String tipoNome;
  final String cidade;
  final String organizador;
  final DateTime? data;
  final bool aprovado;

  EventoAdminModel({
    required this.id,
    required this.nome,
    required this.tipoNome,
    required this.cidade,
    required this.organizador,
    required this.data,
    required this.aprovado,
  });

  factory EventoAdminModel.fromMap(Map<String, dynamic> map, String id, String tipoNome) {
    return EventoAdminModel(
      id: id,
      nome: map['nome'] ?? 'Sem nome',
      tipoNome: tipoNome,
      cidade: map['cidade'] ?? '-',
      organizador: map['organizador'] ?? '-',
      data: map['data'] != null ? (map['data'] as Timestamp).toDate() : null,
      aprovado: map['aprovado'] ?? false,
    );
  }
}
