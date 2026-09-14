import 'package:cloud_firestore/cloud_firestore.dart';

class PresenteReservationRemoteDatasource {
  PresenteReservationRemoteDatasource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> reservar({
    required String idEvento,
    required String idPresente,
    required String idConvidado,
    required String nomeConvidado,
    required DateTime dataReserva,
  }) {
    return _firestore
        .collection('evento')
        .doc(idEvento)
        .collection('presentes')
        .doc(idPresente)
        .update({
      'reservado_por': nomeConvidado,
      'id_convidado': idConvidado,
      'data_reserva': Timestamp.fromDate(dataReserva),
    });
  }
}
