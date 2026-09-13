import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/comunidade.dart';


class ComunidadeComentarioModel extends ComunidadeComentario {
  ComunidadeComentarioModel({
    required super.id,
    required super.autor,
    required super.texto,
    required super.data,
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
