import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/auditoria_evento.dart';
import 'package:app_faca_festa/domain/repositories/auditoria_repository.dart';
import '../datasources/remote/auditoria_remote_datasource.dart';

class AuditoriaRepositoryImpl implements AuditoriaRepository {
  AuditoriaRepositoryImpl(this.remote);

  final AuditoriaRemoteDatasource remote;

  @override
  Future<String> registrar(RegistroAuditoria registro) {
    return UpdateOperations.run(() async {
      return remote.registrar(registro);
    });
  }

  @override
  Future<void> registrarFalhaLogin(RegistroFalhaLogin registro) {
    return UpdateOperations.run(() async {
      return remote.registrarFalhaLogin(registro);
    });
  }

  @override
  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta) {
    return UpdateOperations.run(() async {
      return remote.listar(consulta);
    });
  }

  @override
  Future<AuditoriaPagina> listarPagina(AuditoriaConsulta consulta) {
    return UpdateOperations.run(() async {
      return remote.listarPagina(consulta);
    });
  }
}
