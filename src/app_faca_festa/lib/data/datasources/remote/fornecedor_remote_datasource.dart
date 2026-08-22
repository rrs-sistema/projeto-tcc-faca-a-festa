import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/fornecedor/fornecedor_model.dart';

abstract interface class FornecedorRemoteDatasource {
  Future<FornecedorModel?> buscarPorUsuario(String idUsuario);

  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario);

  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor);

  Future<void> atualizarFornecedor(FornecedorModel fornecedor);

  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  });

  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  });

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
  Future<FornecedorModel?> buscarPorIdUsuario(String idUsuario) async {
    final snapshot = await firestore
        .collection('fornecedor')
        .where('id_usuario', isEqualTo: idUsuario)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return FornecedorModel.fromMap(doc.data(), documentId: doc.id);
  }

  @override
  Stream<FornecedorModel?> observarFornecedorAtivo(String idFornecedor) {
    return firestore
        .collection('fornecedor')
        .where('id_fornecedor', isEqualTo: idFornecedor)
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return FornecedorModel.fromMap(doc.data(), documentId: doc.id);
    });
  }

  @override
  Future<void> atualizarFornecedor(FornecedorModel fornecedor) {
    return firestore
        .collection('fornecedor')
        .doc(fornecedor.idFornecedor)
        .update(fornecedor.toMap());
  }

  @override
  Future<void> atualizarStatusAtivo({
    required String idFornecedor,
    required bool ativo,
  }) {
    return firestore.collection('fornecedor').doc(idFornecedor).update({
      'ativo': ativo,
    });
  }

  @override
  Future<void> atualizarAptoParaOperar({
    required String idFornecedor,
    required bool apto,
  }) {
    return firestore.collection('fornecedor').doc(idFornecedor).update({
      'apto_para_operar': apto,
    });
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
