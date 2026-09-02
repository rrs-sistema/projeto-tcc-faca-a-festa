import '../../domain/repositories/comunidade_repository.dart';
import '../datasources/remote/comunidade_remote_datasource.dart';
import '../models/comunidade/comunidade_comentario_model.dart';
import '../models/comunidade/comunidade_post_model.dart';

class ComunidadeRepositoryImpl implements ComunidadeRepository {
  ComunidadeRepositoryImpl(this.remote);

  final ComunidadeRemoteDatasource remote;

  @override
  Stream<List<ComunidadePostModel>> observarPosts() {
    return remote.observarPosts();
  }

  @override
  Stream<List<ComunidadeComentarioModel>> observarComentarios(String postId) {
    return remote.observarComentarios(postId);
  }

  @override
  Future<void> adicionarPost(
    String texto, {
    required String autor,
    String? imagem,
  }) {
    return remote.adicionarPost(texto, autor: autor, imagem: imagem);
  }

  @override
  Future<void> adicionarComentario(
    String postId,
    String texto, {
    required String autor,
  }) {
    return remote.adicionarComentario(postId, texto, autor: autor);
  }
}
