import 'package:cloud_firestore/cloud_firestore.dart';

class UfCidadeRemoteDatasource {
  UfCidadeRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Future<List<Map<String, dynamic>>> carregarEstados() async {
    final snapshot = await _db.collection('estado').orderBy('nome').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'nome': data['nome'],
        'uf': data['uf'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> carregarCidades(String idEstado) async {
    final snapshot = await _db
        .collection('estado')
        .doc(idEstado)
        .collection('cidades')
        .orderBy('nome')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'nome': data['nome'],
        'uf': data['uf'],
        'id_cidade': data['id_cidade'],
      };
    }).toList();
  }
}
