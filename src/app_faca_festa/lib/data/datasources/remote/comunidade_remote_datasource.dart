import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/comunidade/comunidade_comentario_model.dart';
import '../../models/comunidade/comunidade_post_model.dart';

class ComunidadeRemoteDatasource {
  ComunidadeRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<ComunidadePostModel>> observarPosts() {
    return _db
        .collection('posts')
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ComunidadePostModel.fromFirestore(doc))
              .toList(),
        );
  }

  Stream<List<ComunidadeComentarioModel>> observarComentarios(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comentarios')
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ComunidadeComentarioModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> adicionarPost(
    String texto, {
    required String autor,
    String? imagem,
  }) {
    return _db.collection('posts').add({
      'autor': autor,
      'texto': texto,
      'imagem': imagem,
      'data': Timestamp.now(),
      'curtidas': 0,
    });
  }

  Future<void> adicionarComentario(
    String postId,
    String texto, {
    required String autor,
  }) {
    return _db.collection('posts').doc(postId).collection('comentarios').add({
      'autor': autor,
      'texto': texto,
      'data': Timestamp.now(),
    });
  }
}
