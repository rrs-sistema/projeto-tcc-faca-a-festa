import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../models/evento/evento_model.dart';
import '../../models/evento/tipo_evento.dart';

/// Isolates the existing Firestore operations for Eventos.
class EventoRemoteDatasource {
  EventoRemoteDatasource(
    this.firestore, {
    required this.storage,
  });

  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

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
    final document =
        await firestore.collection('tipo_evento').doc(idTipoEvento).get();

    if (document.exists && document.data() != null) {
      final data = document.data()!;
      return TipoEventoModel.fromMap({
        ...data,
        'id_tipo_evento': data['id_tipo_evento'] ?? document.id,
      });
    }

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

  Future<String> enviarCapa({
    required String idEvento,
    required List<int> bytes,
  }) async {
    final ref =
        storage.ref().child('eventos').child(idEvento).child('capa.jpg');
    final payload = Uint8List.fromList(bytes);
    await ref.putData(
      payload,
      SettableMetadata(contentType: _contentTypeCapa(payload)),
    );
    final url = await ref.getDownloadURL();
    return '$url${url.contains('?') ? '&' : '?'}v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> removerArquivoCapa(String idEvento) {
    return storage
        .ref()
        .child('eventos')
        .child(idEvento)
        .child('capa.jpg')
        .delete();
  }

  Future<void> atualizarImagemCapa({
    required String idEvento,
    String? imagemCapaUrl,
  }) {
    final url = (imagemCapaUrl ?? '').trim();
    if (url.isEmpty) {
      return _eventos.doc(idEvento).update({
        'imagem_capa_url': FieldValue.delete(),
      });
    }
    return _eventos.doc(idEvento).update({'imagem_capa_url': url});
  }

  Future<void> atualizarRotuloBanner({
    required String idEvento,
    String? rotuloBanner,
  }) {
    final texto = (rotuloBanner ?? '').trim();
    if (texto.isEmpty) {
      return _eventos.doc(idEvento).update({
        'rotulo_banner': FieldValue.delete(),
      });
    }
    return _eventos.doc(idEvento).update({'rotulo_banner': texto});
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

  String _contentTypeCapa(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }
}
