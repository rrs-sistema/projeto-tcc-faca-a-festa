import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:app_faca_festa/domain/entities/comunidade.dart';
import 'package:app_faca_festa/domain/usecases/gerenciar_comunidade.dart';
import 'package:app_faca_festa/domain/repositories/autenticacao_repository.dart';

class ComunidadeController extends GetxController {
  ComunidadeController({required GerenciarComunidade comunidade})
      : _comunidade = comunidade;

  final GerenciarComunidade _comunidade;

  final posts = <ComunidadePost>[].obs;
  final loading = false.obs;

  StreamSubscription<List<ComunidadePost>>? _postsSubscription;

  bool get _usuarioAutenticado {
    if (!Get.isRegistered<AutenticacaoRepository>()) return false;
    return Get.find<AutenticacaoRepository>().idUsuarioAtual != null;
  }

  /// Inicia a escuta de posts apenas com sessão autenticada.
  void garantirEscuta() {
    if (!_usuarioAutenticado) {
      debugPrint(
        '⏭️ [ComunidadeController] Escuta de posts ignorada: sem autenticação.',
      );
      return;
    }
    if (_postsSubscription != null) return;
    _carregarPosts();
  }

  void _carregarPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = _comunidade.observarPosts().listen(
      (lista) {
        posts.value = lista;
      },
      onError: (Object e, StackTrace s) {
        debugPrint('❌ [ComunidadeController] Erro ao escutar posts: $e\n$s');
      },
      cancelOnError: true,
    );
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
