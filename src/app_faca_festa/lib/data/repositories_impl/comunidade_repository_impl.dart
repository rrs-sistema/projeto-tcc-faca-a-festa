import '../../domain/repositories/comunidade_repository.dart';
import '../datasources/remote/comunidade_remote_datasource.dart';
import '../models/comunidade/comunidade_post_model.dart';

class ComunidadeRepositoryImpl implements ComunidadeRepository {
  ComunidadeRepositoryImpl(this.remote);

  final ComunidadeRemoteDatasource remote;

  @override
  Stream<List<ComunidadePostModel>> observarPosts() {
    return remote.observarPosts();
  }

  @override
  Future<void> adicionarPost(String texto, {String? imagem}) {
    return remote.adicionarPost(texto, imagem: imagem);
  }

  @override
  Future<void> adicionarComentario(String postId, String texto) {
    return remote.adicionarComentario(postId, texto);
  }
}
