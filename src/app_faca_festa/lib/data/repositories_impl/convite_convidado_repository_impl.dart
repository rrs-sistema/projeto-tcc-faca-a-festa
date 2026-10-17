import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/repositories/convite_convidado_repository.dart';
import '../datasources/remote/convite_convidado_remote_datasource.dart';

class ConviteConvidadoRepositoryImpl implements ConviteConvidadoRepository {
  ConviteConvidadoRepositoryImpl(this.remote);

  final ConviteConvidadoRemoteDatasource remote;

  @override
  Future<Convidado?> vincularPorToken({
    required String token,
    required String uid,
    required String email,
  }) {
    return UpdateOperations.run(() async {
      return remote.vincularPorToken(token: token, uid: uid, email: email);
    });
  }

  @override
  Future<Convidado?> buscarOuVincularPorUsuario({
    required String uid,
    required String email,
  }) {
    return UpdateOperations.run(() async {
      return remote.buscarOuVincularPorUsuario(uid: uid, email: email);
    });
  }
}
