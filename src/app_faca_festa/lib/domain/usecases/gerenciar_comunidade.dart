import '../../data/models/comunidade/comunidade_post_model.dart';
import '../repositories/comunidade_repository.dart';

class GerenciarComunidade {
  GerenciarComunidade(this.repository);

  final ComunidadeRepository repository;

  Stream<List<ComunidadePostModel>> observarPosts() {
    return repository.observarPosts();
  }

  Future<void> adicionarPost(String texto, {String? imagem}) {
    return repository.adicionarPost(texto, imagem: imagem);
  }

  Future<void> adicionarComentario(String postId, String texto) {
    return repository.adicionarComentario(postId, texto);
  }
}
