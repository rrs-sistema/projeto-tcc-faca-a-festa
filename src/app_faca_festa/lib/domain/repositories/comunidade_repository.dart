import '../../data/models/comunidade/comunidade_post_model.dart';

abstract class ComunidadeRepository {
  Stream<List<ComunidadePostModel>> observarPosts();

  Future<void> adicionarPost(String texto, {String? imagem});

  Future<void> adicionarComentario(String postId, String texto);
}
