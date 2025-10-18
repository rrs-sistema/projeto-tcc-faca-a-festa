import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import './../data/models/comunidade/comunidade_post_model.dart';

class ComunidadeController extends GetxController {
  final posts = <ComunidadePostModel>[].obs;
  final loading = false.obs;
  final _db = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _carregarPosts();
  }

  void _carregarPosts() {
    _db.collection('posts').orderBy('data', descending: true).snapshots().listen((snap) {
      posts.value = snap.docs.map((d) => ComunidadePostModel.fromFirestore(d)).toList();
    });
  }

  Future<void> adicionarPost(String texto, {String? imagem}) async {
    await _db.collection('posts').add({
      'autor': 'Usuário Atual',
      'texto': texto,
      'imagem': imagem,
      'data': Timestamp.now(),
      'curtidas': 0,
    });
  }

  Future<void> adicionarComentario(String postId, String texto) async {
    await _db.collection('posts').doc(postId).collection('comentarios').add({
      'autor': 'Usuário Atual',
      'texto': texto,
      'data': Timestamp.now(),
    });
  }
}
