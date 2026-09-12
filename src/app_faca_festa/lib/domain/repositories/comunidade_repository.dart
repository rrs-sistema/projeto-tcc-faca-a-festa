import '../entities/comunidade.dart';

abstract class ComunidadeRepository {
  Stream<List<ComunidadePost>> observarPosts();

  Stream<List<ComunidadeComentario>> observarComentarios(String postId);

  Future<void> adicionarPost(
    String texto, {
    required String autor,
    String? imagem,
  });

  Future<void> adicionarComentario(
    String postId,
    String texto, {
    required String autor,
  });
}
