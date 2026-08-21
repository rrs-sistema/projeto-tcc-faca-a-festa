import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/fornecedor/territorio_model.dart';

class AdminTerritorioRemoteDatasource {
  AdminTerritorioRemoteDatasource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<List<TerritorioModel>> listarTerritorios() async {
    final snap = await _db.collection('territorio').get();

    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data['id_territorio'] = data['id_territorio'] ?? doc.id;
      return TerritorioModel.fromMap(data);
    }).toList();
  }

  Future<void> salvarTerritorio(TerritorioModel territorio) {
    return _db
        .collection('territorio')
        .doc(territorio.idTerritorio)
        .set(territorio.toMap());
  }

  Future<void> atualizarAtivo(String idTerritorio, bool ativo) {
    return _db
        .collection('territorio')
        .doc(idTerritorio)
        .update({'ativo': ativo});
  }
}
