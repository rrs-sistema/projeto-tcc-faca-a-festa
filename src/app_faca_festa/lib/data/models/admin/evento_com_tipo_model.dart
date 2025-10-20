import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo unificado com o tipo do evento
class EventoComTipoModel {
  final String id;
  final String nome;
  final String tipoNome;
  final String organizador;
  final String? cidade;
  final bool aprovado;
  final DateTime? data;

  EventoComTipoModel({
    required this.id,
    required this.nome,
    required this.tipoNome,
    required this.organizador,
    this.cidade,
    this.data,
    this.aprovado = false,
  });

  factory EventoComTipoModel.fromMap(Map<String, dynamic> map, String id, String tipoNome) {
    return EventoComTipoModel(
      id: id,
      nome: map['nome'] ?? 'Sem nome',
      tipoNome: tipoNome,
      organizador: map['organizador'] ?? '-',
      cidade: map['cidade'] ?? '-',
      aprovado: map['aprovado'] ?? false,
      data: map['data'] != null ? (map['data'] as Timestamp).toDate() : null,
    );
  }
}
