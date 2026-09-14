import '../entities/auditoria_evento.dart';

abstract class AuditoriaRegistrar {
  void registrar({
    required String acao,
    required String resumo,
    String? entidadeTipo,
    String? entidadeId,
    String? entidadeNome,
    String? idFornecedor,
    String? idEvento,
    String? idServico,
    String? idCotacao,
    String? idOrcamento,
    List<AuditoriaMudanca> mudancas = const [],
    AuditoriaDetalhe? detalhe,
    String? rota,
  });
}

class AuditoriaRegistrarVazio implements AuditoriaRegistrar {
  const AuditoriaRegistrarVazio();

  @override
  void registrar({
    required String acao,
    required String resumo,
    String? entidadeTipo,
    String? entidadeId,
    String? entidadeNome,
    String? idFornecedor,
    String? idEvento,
    String? idServico,
    String? idCotacao,
    String? idOrcamento,
    List<AuditoriaMudanca> mudancas = const [],
    AuditoriaDetalhe? detalhe,
    String? rota,
  }) {}
}
