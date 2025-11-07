import 'package:cloud_firestore/cloud_firestore.dart';

class InspiracaoModel {
  final String id;
  final String tipoEvento; // Ex: "casamento", "aniversário"
  final String titulo;
  final String descricao;
  final String imagemUrl;
  final List<String> tags; // ex: ["bolo", "rosa", "romântico"]
  final List<String>? galeriaUrls; // imagens extras
  final List<String>? paletaCores; // cores em formato "0xFFxxxxxx"
  final String? categoria; // ex: "Decoração", "Flores"
  final List<String>? fornecedoresRelacionados; // IDs ou nomes de fornecedores
  final bool favorito;
  final DateTime? criadoEm;

  InspiracaoModel({
    required this.id,
    required this.tipoEvento,
    required this.titulo,
    required this.descricao,
    required this.imagemUrl,
    required this.tags,
    this.galeriaUrls,
    this.paletaCores,
    this.categoria,
    this.fornecedoresRelacionados,
    this.favorito = false,
    this.criadoEm,
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
      galeriaUrls: data['galeriaUrls'] != null ? List<String>.from(data['galeriaUrls']) : null,
      paletaCores: data['paletaCores'] != null ? List<String>.from(data['paletaCores']) : null,
      categoria: (data['categoria'] ?? '').toString(),
      fornecedoresRelacionados: data['fornecedoresRelacionados'] != null
          ? List<String>.from(data['fornecedoresRelacionados'])
          : null,
      favorito: data['favorito'] ?? false,
      criadoEm: (data['criadoEm'] is Timestamp) ? (data['criadoEm'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tipoEvento': tipoEvento.toLowerCase(),
      'titulo': titulo,
      'descricao': descricao,
      'imagemUrl': imagemUrl,
      'tags': tags,
      'galeriaUrls': galeriaUrls,
      'paletaCores': paletaCores,
      'categoria': categoria,
      'fornecedoresRelacionados': fornecedoresRelacionados,
      'favorito': favorito,
      'criadoEm': criadoEm ?? FieldValue.serverTimestamp(),
    };
  }

  InspiracaoModel copyWith({
    String? id,
    String? tipoEvento,
    String? titulo,
    String? descricao,
    String? imagemUrl,
    List<String>? tags,
    List<String>? galeriaUrls,
    List<String>? paletaCores,
    String? categoria,
    List<String>? fornecedoresRelacionados,
    bool? favorito,
    DateTime? criadoEm,
  }) {
    return InspiracaoModel(
      id: id ?? this.id,
      tipoEvento: tipoEvento ?? this.tipoEvento,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      tags: tags ?? this.tags,
      galeriaUrls: galeriaUrls ?? this.galeriaUrls,
      paletaCores: paletaCores ?? this.paletaCores,
      categoria: categoria ?? this.categoria,
      fornecedoresRelacionados: fornecedoresRelacionados ?? this.fornecedoresRelacionados,
      favorito: favorito ?? this.favorito,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
