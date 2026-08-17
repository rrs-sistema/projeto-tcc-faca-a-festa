import '../entities/convidado.dart';

class ConviteJaVinculadoException implements Exception {
  const ConviteJaVinculadoException();
}

abstract interface class ConviteConvidadoRepository {
  Future<Convidado?> vincularPorToken({
    required String token,
    required String uid,
    required String email,
  });

  Future<Convidado?> buscarOuVincularPorUsuario({
    required String uid,
    required String email,
  });
}
