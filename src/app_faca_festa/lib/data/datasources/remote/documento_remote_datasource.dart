import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class DocumentoRemoteDatasource {
  Future<void> excluirDocumento({
    required String colecao,
    required String idDocumento,
  });
}

class FirebaseDocumentoRemoteDatasource implements DocumentoRemoteDatasource {
  FirebaseDocumentoRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<void> excluirDocumento({
    required String colecao,
    required String idDocumento,
  }) {
    return firestore.collection(colecao).doc(idDocumento).delete();
  }
}
