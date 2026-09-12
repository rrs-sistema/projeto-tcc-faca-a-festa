class ComunidadePost {
  ComunidadePost({
    required this.id,
    required this.autor,
    required this.texto,
    required this.data,
    this.imagem,
    this.curtidas = 0,
  });

  final String id;
  final String autor;
  final String? imagem;
  final String texto;
  final DateTime data;
  final int curtidas;

  ComunidadePost copyWith({
    String? autor,
    String? imagem,
    String? texto,
    DateTime? data,
    int? curtidas,
  }) {
    return ComunidadePost(
      id: id,
      autor: autor ?? this.autor,
      imagem: imagem ?? this.imagem,
      texto: texto ?? this.texto,
      data: data ?? this.data,
      curtidas: curtidas ?? this.curtidas,
    );
  }
}

class ComunidadeComentario {
  ComunidadeComentario({
    required this.id,
    required this.autor,
    required this.texto,
    required this.data,
  });

  final String id;
  final String autor;
  final String texto;
  final DateTime data;
}
