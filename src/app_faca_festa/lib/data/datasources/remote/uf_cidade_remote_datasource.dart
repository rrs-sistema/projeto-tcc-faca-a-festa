import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:app_faca_festa/domain/entities/uf_cidade.dart';

class UfCidadeRemoteDatasource {
  UfCidadeRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Future<List<Estado>> carregarEstados() async {
    final snapshot = await _db.collection('estado').orderBy('nome').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Estado(
        id: doc.id,
        nome: (data['nome'] ?? '').toString(),
        uf: (data['uf'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<Cidade>> carregarCidades(String idEstado) async {
    final snapshot = await _db
        .collection('estado')
        .doc(idEstado)
        .collection('cidades')
        .orderBy('nome')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Cidade(
        id: doc.id,
        nome: (data['nome'] ?? '').toString(),
        uf: (data['uf'] ?? '').toString(),
        idCidade: _paraInt(data['id_cidade']),
      );
    }).toList();
  }

  int? _paraInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
