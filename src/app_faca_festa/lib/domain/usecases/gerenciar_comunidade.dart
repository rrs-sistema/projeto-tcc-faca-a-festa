import '../entities/comunidade.dart';
import '../repositories/comunidade_repository.dart';

class GerenciarComunidade {
  GerenciarComunidade(this.repository);

  final ComunidadeRepository repository;

  Stream<List<ComunidadePost>> observarPosts() {
    return repository.observarPosts();
  }

  Stream<List<ComunidadeComentario>> observarComentarios(String postId) {
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
