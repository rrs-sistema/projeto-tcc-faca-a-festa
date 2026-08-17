import '../entities/convidado.dart';

class MigracaoTipoConvidadoResultado {
  final int totalEncontrados;
  final int totalAtualizados;
  final int totalIgnorados;

  const MigracaoTipoConvidadoResultado({
    required this.totalEncontrados,
    required this.totalAtualizados,
    required this.totalIgnorados,
  });
}

abstract interface class ConvidadoRepository {
  Future<Convidado?> buscarPorId(String idConvidado);

  Future<Convidado?> buscarPrimeiroPorEvento(String idEvento);

  Future<Convidado?> buscarPorToken(String token);

  Stream<List<Convidado>> observarPorEvento(String idEvento);

  Future<void> salvar(Convidado convidado);

  Future<void> excluir(String idConvidado);

  Future<void> atualizarStatus(
    String idConvidado,
    StatusConvidado status,
    DateTime dataResposta,
  );

  Future<MigracaoTipoConvidadoResultado> migrarTiposLegados();

  Future<void> marcarConvitesEnviados(
    List<String> idsConvidados,
    String tipoEnvio,
  );
}
