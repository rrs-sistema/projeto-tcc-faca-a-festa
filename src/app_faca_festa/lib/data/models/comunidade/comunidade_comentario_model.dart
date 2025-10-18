import 'package:cloud_firestore/cloud_firestore.dart';

class ComunidadeComentarioModel {
  final String id;
  final String autor;
  final String texto;
  final DateTime data;

  ComunidadeComentarioModel({
    required this.id,
    required this.autor,
    required this.texto,
    required this.data,
  });

  factory ComunidadeComentarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComunidadeComentarioModel(
      id: doc.id,
      autor: data['autor'] ?? 'Usuário',
      texto: data['texto'] ?? '',
      data: (data['data'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autor': autor,
      'texto': texto,
      'data': Timestamp.fromDate(data),
    };
  }
}
