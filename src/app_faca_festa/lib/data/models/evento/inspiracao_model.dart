import 'package:cloud_firestore/cloud_firestore.dart';

class InspiracaoModel {
  final String id;
  final String tipoEvento;
  final String titulo;
  final String descricao;
  final String imagemUrl;
  final List<String> tags;
  final bool favorito;

  InspiracaoModel({
    required this.id,
    required this.tipoEvento,
    required this.titulo,
    required this.descricao,
    required this.imagemUrl,
    required this.tags,
    this.favorito = false,
  });

  factory InspiracaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InspiracaoModel(
      id: doc.id,
      tipoEvento: (data['tipoEvento'] ?? '').toString(),
      titulo: (data['titulo'] ?? '').toString(),
      descricao: (data['descricao'] ?? '').toString(),
      imagemUrl: (data['imagemUrl'] ?? '').toString(),
      tags: List<String>.from(data['tags'] ?? []),
      favorito: data['favorito'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipoEvento': tipoEvento.toLowerCase(),
      'titulo': titulo,
      'descricao': descricao,
      'imagemUrl': imagemUrl,
      'tags': tags,
      'favorito': favorito,
    };
  }

  InspiracaoModel copyWith({
    String? id,
    String? tipoEvento,
    String? titulo,
    String? descricao,
    String? imagemUrl,
    List<String>? tags,
    bool? favorito,
  }) {
    return InspiracaoModel(
      id: id ?? this.id,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      tags: tags ?? this.tags,
      favorito: favorito ?? this.favorito,
    );
  }
}
