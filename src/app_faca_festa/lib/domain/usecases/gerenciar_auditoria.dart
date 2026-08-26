import '../entities/auditoria_evento.dart';
import '../repositories/auditoria_repository.dart';

class GerenciarAuditoria {
  GerenciarAuditoria(this.repository);

  final AuditoriaRepository repository;

  Future<String> registrar(RegistroAuditoria registro) {
    return repository.registrar(registro);
  }

  Future<List<AuditoriaEvento>> listar(AuditoriaConsulta consulta) {
    return repository.listar(consulta);
  }
}
