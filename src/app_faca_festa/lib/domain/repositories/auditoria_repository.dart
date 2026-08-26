import '../entities/auditoria_evento.dart';

abstract class AuditoriaRepository {
  Future<String> registrar(RegistroAuditoria registro);

  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta);
}
