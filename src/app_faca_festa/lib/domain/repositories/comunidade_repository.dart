import '../../data/models/comunidade/comunidade_post_model.dart';
import '../../data/models/comunidade/comunidade_comentario_model.dart';

abstract class ComunidadeRepository {
  Stream<List<ComunidadePostModel>> observarPosts();

  Stream<List<ComunidadeComentarioModel>> observarComentarios(String postId);

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
