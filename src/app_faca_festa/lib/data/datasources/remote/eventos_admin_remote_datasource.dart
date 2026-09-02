import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin/evento_com_tipo_model.dart';

class EventosAdminRemoteDatasource {
  EventosAdminRemoteDatasource({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  Future<List<EventoComTipoModel>> listarEventosComTipo() async {
    final eventosSnap = await _db.collection('evento').get();
    final listaEventos = <EventoComTipoModel>[];

    for (final doc in eventosSnap.docs) {
      final data = doc.data();
      final idTipoEvento =
          (data['id_tipo_evento'] ?? data['idTipoEvento'] ?? '').toString();

      final nomeTipo = await _buscarNomeTipoEvento(idTipoEvento);
      listaEventos.add(EventoComTipoModel.fromMap(data, doc.id, nomeTipo));
    }

    return listaEventos;
  }

  Future<void> aprovarEvento(String id) {
    return _db.collection('evento').doc(id).update({'aprovado': true});
  }

  Future<void> excluirEvento(String id) {
    return _db.collection('evento').doc(id).delete();
  }

  Future<String> _buscarNomeTipoEvento(String idTipoEvento) async {
    const nomePadrao = 'Tipo não informado';
    if (idTipoEvento.isEmpty) return nomePadrao;

    final tipoDoc = await _db.collection('tipo_evento').doc(idTipoEvento).get();
    if (tipoDoc.exists) {
      return (tipoDoc.data()?['nome'] ?? nomePadrao).toString();
    }

    final tipoSnap = await _db
        .collection('tipo_evento')
        .where('id_tipo_evento', isEqualTo: idTipoEvento)
        .limit(1)
        .get();
    if (tipoSnap.docs.isEmpty) return nomePadrao;

    return (tipoSnap.docs.first.data()['nome'] ?? nomePadrao).toString();
  }
}
