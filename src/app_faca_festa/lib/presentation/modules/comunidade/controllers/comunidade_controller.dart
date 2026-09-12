import 'dart:async';

import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/comunidade.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_comunidade.dart';

class ComunidadeController extends GetxController {
  ComunidadeController({required GerenciarComunidade comunidade})
      : _comunidade = comunidade;

  final GerenciarComunidade _comunidade;

  final posts = <ComunidadePost>[].obs;
  final loading = false.obs;

  StreamSubscription<List<ComunidadePost>>? _postsSubscription;

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

  Stream<List<ComunidadePost>> observarPosts() {
    return _comunidade.observarPosts();
  }

  Stream<List<ComunidadeComentario>> observarComentarios(String postId) {
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
