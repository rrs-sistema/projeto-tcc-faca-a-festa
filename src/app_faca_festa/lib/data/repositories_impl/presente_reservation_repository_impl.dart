import 'package:app_faca_festa/data/datasources/remote/presente_reservation_remote_datasource.dart';
import 'package:app_faca_festa/domain/repositories/presente_reservation_repository.dart';

class PresenteReservationRepositoryImpl
    implements PresenteReservationRepository {
  PresenteReservationRepositoryImpl(this._remote);

  final PresenteReservationRemoteDatasource _remote;

  @override
  Future<void> reservar({
    required String idEvento,
    required String idPresente,
    required String idConvidado,
    required String nomeConvidado,
    required DateTime dataReserva,
  }) {
    return _remote.reservar(
      idEvento: idEvento,
      idPresente: idPresente,
      idConvidado: idConvidado,
      nomeConvidado: nomeConvidado,
      dataReserva: dataReserva,
    );
  }
}
