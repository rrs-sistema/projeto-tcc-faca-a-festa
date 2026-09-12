import 'package:app_faca_festa/domain/entities/comunidade.dart';
import 'package:app_faca_festa/domain/repositories/comunidade_repository.dart';
import '../datasources/remote/comunidade_remote_datasource.dart';

class ComunidadeRepositoryImpl implements ComunidadeRepository {
  ComunidadeRepositoryImpl(this.remote);

  final ComunidadeRemoteDatasource remote;

  @override
  Stream<List<ComunidadePost>> observarPosts() {
    return remote.observarPosts();
  }

  @override
  Stream<List<ComunidadeComentario>> observarComentarios(String postId) {
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
