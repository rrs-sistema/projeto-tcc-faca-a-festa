import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/fornecedor/fornecedor_model.dart';

abstract interface class FornecedorRemoteDatasource {
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario);

  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  });
}

class FirebaseFornecedorRemoteDatasource implements FornecedorRemoteDatasource {
  FirebaseFornecedorRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario) async {
    final doc = await firestore.collection('fornecedor').doc(idUsuario).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return FornecedorModel.fromMap(data, documentId: doc.id);
  }

  @override
  Future<void> atualizarFcmToken({
    required String idFornecedor,
    required String token,
  }) {
    return firestore.collection('fornecedor').doc(idFornecedor).update({
      'fcm_token': token,
    });
  }
}
