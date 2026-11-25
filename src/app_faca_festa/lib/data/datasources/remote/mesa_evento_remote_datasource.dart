import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/evento/mesa_evento_model.dart';

class MesaEventoRemoteDatasource {
  MesaEventoRemoteDatasource(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _mesas =>
      firestore.collection('mesa_evento');

  CollectionReference<Map<String, dynamic>> get _convidados =>
      firestore.collection('convidado');

  Stream<List<MesaEventoModel>> observarMesas(String idEvento) {
    return _mesas
        .where('id_evento', isEqualTo: idEvento)
        .snapshots()
        .map((snapshot) => _mapearMesas(snapshot, idEvento));
  }

  Future<List<MesaEventoModel>> buscarMesas(String idEvento) async {
    final snapshot =
        await _mesas.where('id_evento', isEqualTo: idEvento).get();
    return _mapearMesas(snapshot, idEvento);
  }

  List<MesaEventoModel> _mapearMesas(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String idEvento,
  ) {
    final mesas = snapshot.docs.map((document) {
      final data = Map<String, dynamic>.from(document.data());
      data['id_mesa'] = document.id;
      if ((data['id_evento'] ?? '').toString().trim().isEmpty) {
        data['id_evento'] = idEvento;
      }
      return MesaEventoModel.fromMap(data);
    }).toList();

    mesas.sort((a, b) {
      final porNumero = a.numeroMesa.compareTo(b.numeroMesa);
      if (porNumero != 0) return porNumero;
      return a.nomeMesa.toLowerCase().compareTo(b.nomeMesa.toLowerCase());
    });
    return mesas;
  }

  Future<void> salvarMesa(MesaEventoModel mesa) async {
    final data = Map<String, dynamic>.from(mesa.toMap())
      ..['id_mesa'] = mesa.idMesa
      ..['id_evento'] = mesa.idEvento
      ..['id_grupo'] = mesa.idGrupo
      ..['nome_grupo'] = mesa.nomeGrupo
      ..['data_atualizacao'] = FieldValue.serverTimestamp()
      ..removeWhere(
        (key, value) =>
            value == null && key != 'id_grupo' && key != 'nome_grupo',
      );
    await _mesas.doc(mesa.idMesa).set(data, SetOptions(merge: true));
  }

  Future<void> excluirMesa(
    String idMesa, {
    String? idEvento,
    required bool desvincularConvidados,
  }) async {
    final batch = firestore.batch();
    if (desvincularConvidados) {
      // Precisa filtrar por id_evento: senão o list do convidado cai em
      // PERMISSION_DENIED (regra exige eventoDono(id_evento) na query).
      final eventoId = (idEvento ?? '').trim();
      final query = eventoId.isEmpty
          ? _convidados.where('id_mesa', isEqualTo: idMesa)
          : _convidados
              .where('id_evento', isEqualTo: eventoId)
              .where('id_mesa', isEqualTo: idMesa);
      final snapshot = await query.get();
      for (final document in snapshot.docs) {
        batch.update(document.reference, {
          'id_mesa': null,
          'numero_mesa': null,
          'data_atualizacao': FieldValue.serverTimestamp(),
        });
      }
    }
    batch.delete(_mesas.doc(idMesa));
    await batch.commit();
  }

  Future<void> atualizarOcupacao({
    required String idMesa,
    required int totalOcupados,
  }) {
    return _mesas.doc(idMesa).set({
      'total_ocupados': totalOcupados,
      'data_atualizacao': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
