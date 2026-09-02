import '../../domain/entities/auditoria_evento.dart';
import '../../domain/repositories/auditoria_repository.dart';
import '../datasources/remote/auditoria_remote_datasource.dart';

class AuditoriaRepositoryImpl implements AuditoriaRepository {
  AuditoriaRepositoryImpl(this.remote);

  final AuditoriaRemoteDatasource remote;

  @override
  Future<String> registrar(RegistroAuditoria registro) {
    return remote.registrar(registro);
  }

  @override
  Future<void> registrarFalhaLogin(RegistroFalhaLogin registro) {
    return remote.registrarFalhaLogin(registro);
  }

  @override
  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta) {
    return remote.listar(consulta);
  }

  @override
  Future<AuditoriaPagina> listarPagina(AuditoriaConsulta consulta) {
    return remote.listarPagina(consulta);
  }
}
