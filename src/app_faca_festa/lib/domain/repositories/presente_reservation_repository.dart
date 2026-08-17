abstract interface class PresenteReservationRepository {
  Future<void> reservar({
    required String idEvento,
    required String idPresente,
    required String idConvidado,
    required String nomeConvidado,
    required DateTime dataReserva,
  });
}
