import '../entities/auditoria_evento.dart';

abstract class AuditoriaRepository {
  Future<String> registrar(RegistroAuditoria registro);

  Future<void> registrarFalhaLogin(RegistroFalhaLogin registro);

  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta);

  Future<AuditoriaPagina> listarPagina(AuditoriaConsulta consulta);
}
