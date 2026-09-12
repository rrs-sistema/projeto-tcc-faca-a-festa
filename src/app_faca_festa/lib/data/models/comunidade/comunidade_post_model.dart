import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/comunidade.dart';

export 'package:app_faca_festa/domain/entities/comunidade.dart'
    show ComunidadePost;

class ComunidadePostModel extends ComunidadePost {
  ComunidadePostModel({
    required super.id,
    required super.autor,
    required super.texto,
    required super.data,
    super.imagem,
    super.curtidas = 0,
  });

  /// 🔹 Cria uma instância a partir do Firestore
  factory ComunidadePostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ComunidadePostModel(
      id: doc.id,
      autor: data['autor'] ?? 'Usuário Anônimo',
      imagem: data['imagem'],
      texto: data['texto'] ?? '',
      data: (data['data'] as Timestamp).toDate(),
      curtidas: data['curtidas'] ?? 0,
    );
  }

  /// 🔹 Converte para formato Firestore
  Map<String, dynamic> toMap() {
    return {
      'autor': autor,
      'imagem': imagem,
      'texto': texto,
      'data': Timestamp.fromDate(data),
      'curtidas': curtidas,
    };
  }

  /// 🔹 Cria uma cópia com modificações
  @override
  ComunidadePostModel copyWith({
    String? autor,
    String? imagem,
    String? texto,
    DateTime? data,
    int? curtidas,
  }) {
    return ComunidadePostModel(
      id: id,
      autor: autor ?? this.autor,
      imagem: imagem ?? this.imagem,
      texto: texto ?? this.texto,
      data: data ?? this.data,
      curtidas: curtidas ?? this.curtidas,
    );
  }
}
