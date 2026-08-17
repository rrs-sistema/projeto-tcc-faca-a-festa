import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/evento/evento_model.dart';
import '../../models/evento/tipo_evento.dart';

/// Isolates the existing Firestore operations for Eventos.
class EventoRemoteDatasource {
  EventoRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _eventos =>
      firestore.collection('evento');

  Future<EventoModel?> buscarPorId(String idEvento) async {
    final snapshot = await _eventos
        .where('id_evento', isEqualTo: idEvento)
        .orderBy('data_cadastro', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return EventoModel.fromMap(snapshot.docs.first.data());
  }

  Future<EventoModel?> buscarUltimoPorUsuario(String idUsuario) async {
    final snapshot = await _eventos
        .where('id_usuario', isEqualTo: idUsuario)
        .orderBy('data_cadastro', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return EventoModel.fromMap(snapshot.docs.first.data());
  }

  Stream<EventoModel?> observarUltimoPorUsuario(String idUsuario) {
    return _eventos
        .where('id_usuario', isEqualTo: idUsuario)
        .orderBy('data_cadastro', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isEmpty
              ? null
              : EventoModel.fromMap(snapshot.docs.first.data()),
        );
  }

  Stream<EventoModel?> observarPorId(String idEvento) {
    return _eventos.doc(idEvento).snapshots().map(
          (document) =>
              document.exists ? EventoModel.fromMap(document.data()!) : null,
        );
  }

  Future<TipoEventoModel?> buscarTipoPorId(String idTipoEvento) async {
    final snapshot = await firestore
        .collection('tipo_evento')
        .where('id_tipo_evento', isEqualTo: idTipoEvento)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return TipoEventoModel.fromMap(snapshot.docs.first.data());
  }

  Future<List<TipoEventoModel>> listarTiposAtivos() async {
    final snapshot = await firestore
        .collection('tipo_evento')
        .where('ativo', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((document) => TipoEventoModel.fromMap(document.data()))
        .toList();
  }

  Future<void> salvar(EventoModel evento) {
    return _eventos.doc(evento.idEvento).set(evento.toMap());
  }

  Future<void> excluir(String idEvento) {
    return _eventos.doc(idEvento).delete();
  }

  Stream<List<EventoModel>> listarPorUsuario(String idUsuario) {
    return _eventos.where('id_usuario', isEqualTo: idUsuario).snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => EventoModel.fromMap(document.data()))
              .toList(),
        );
  }
}
