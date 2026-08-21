import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/comunidade/comunidade_post_model.dart';

class ComunidadeRemoteDatasource {
  ComunidadeRemoteDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

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

  Future<void> adicionarPost(String texto, {String? imagem}) {
    return _db.collection('posts').add({
      'autor': 'Usuário Atual',
      'texto': texto,
      'imagem': imagem,
      'data': Timestamp.now(),
      'curtidas': 0,
    });
  }

  Future<void> adicionarComentario(String postId, String texto) {
    return _db.collection('posts').doc(postId).collection('comentarios').add({
      'autor': 'Usuário Atual',
      'texto': texto,
      'data': Timestamp.now(),
    });
  }
}
