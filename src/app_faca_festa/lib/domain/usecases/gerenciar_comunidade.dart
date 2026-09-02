import '../../data/models/comunidade/comunidade_comentario_model.dart';
import '../../data/models/comunidade/comunidade_post_model.dart';
import '../repositories/comunidade_repository.dart';

class GerenciarComunidade {
  GerenciarComunidade(this.repository);

  final ComunidadeRepository repository;

  Stream<List<ComunidadePostModel>> observarPosts() {
    return repository.observarPosts();
  }

  Stream<List<ComunidadeComentarioModel>> observarComentarios(String postId) {
    return repository.observarComentarios(postId);
  }

  Future<void> adicionarPost(
    String texto, {
    required String autor,
    String? imagem,
  }) {
    return repository.adicionarPost(texto, autor: autor, imagem: imagem);
  }

  Future<void> adicionarComentario(
    String postId,
    String texto, {
    required String autor,
  }) {
    return repository.adicionarComentario(postId, texto, autor: autor);
  }
}
