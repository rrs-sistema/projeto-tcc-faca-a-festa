import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/presente_reservation_repository.dart';

class PresenteReservationRepositoryImpl
    implements PresenteReservationRepository {
  PresenteReservationRepositoryImpl(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<void> reservar({
    required String idEvento,
    required String idPresente,
    required String idConvidado,
    required String nomeConvidado,
    required DateTime dataReserva,
  }) {
    return firestore
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
