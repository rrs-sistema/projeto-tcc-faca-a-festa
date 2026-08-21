import 'dart:async';

import 'package:get/get.dart';

import './../data/models/comunidade/comunidade_post_model.dart';
import '../domain/usecases/gerenciar_comunidade.dart';

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

  Future<void> adicionarPost(String texto, {String? imagem}) async {
    await _comunidade.adicionarPost(texto, imagem: imagem);
  }

  Future<void> adicionarComentario(String postId, String texto) async {
    await _comunidade.adicionarComentario(postId, texto);
  }

  @override
  void onClose() {
    _postsSubscription?.cancel();
    super.onClose();
  }
}
