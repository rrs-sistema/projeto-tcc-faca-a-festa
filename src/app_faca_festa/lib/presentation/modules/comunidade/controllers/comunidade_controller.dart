import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/data/models/comunidade/comunidade_comentario_model.dart';
import 'package:app_faca_festa/data/models/comunidade/comunidade_post_model.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_comunidade.dart';

class ComunidadeController extends GetxController {
  ComunidadeController({required GerenciarComunidade comunidade})
      : _comunidade = comunidade;

  final GerenciarComunidade _comunidade;

  final posts = <ComunidadePostModel>[].obs;
  final loading = false.obs;

  StreamSubscription<List<ComunidadePostModel>>? _postsSubscription;

  @override
  void onInit() {
    super.onInit();
    _carregarPosts();
  }

  void _carregarPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = _comunidade.observarPosts().listen((lista) {
      posts.value = lista;
    });
  }

  Stream<List<ComunidadePostModel>> observarPosts() {
    return _comunidade.observarPosts();
  }

  Stream<List<ComunidadeComentarioModel>> observarComentarios(String postId) {
    return _comunidade.observarComentarios(postId);
  }

  Future<void> adicionarPost(
    String texto, {
    required String autor,
    String? imagem,
  }) async {
    await _comunidade.adicionarPost(texto, autor: autor, imagem: imagem);
  }

  Future<void> adicionarComentario(
    String postId,
    String texto, {
    required String autor,
  }) async {
    await _comunidade.adicionarComentario(postId, texto, autor: autor);
  }

  @override
  void onClose() {
    _postsSubscription?.cancel();
    super.onClose();
  }
}
