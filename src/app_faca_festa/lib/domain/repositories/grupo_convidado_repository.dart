import '../entities/convidado.dart';
import '../entities/grupo_convidado.dart';

class ResumoGrupoConvidado {
  final String idGrupo;
  final int total;
  final int adultos;
  final int criancas;
  final int bebes;
  final int confirmados;

  const ResumoGrupoConvidado({
    required this.idGrupo,
    required this.total,
    required this.adultos,
    required this.criancas,
    required this.bebes,
    required this.confirmados,
  });
}

abstract interface class GrupoConvidadoRepository {
  Stream<List<GrupoConvidado>> observarGrupos(String idEvento);

  Stream<List<Convidado>> observarConvidados(String idEvento);

  Future<void> salvarGrupo(GrupoConvidado grupo);

  Future<void> excluirGrupo(
    String idGrupo, {
    bool desvincularConvidados = true,
  });

  Future<void> vincularConvidadoAoGrupo(
    Convidado convidado,
    GrupoConvidado grupo,
  );

  Future<void> removerConvidadoDoGrupo(Convidado convidado);

  Future<void> vincularConvidadoNaMesa(
    Convidado convidado,
    String idMesa,
    int numeroMesa,
  );

  Future<void> removerConvidadoDaMesa(Convidado convidado);

  Future<void> atualizarResumos(List<ResumoGrupoConvidado> resumos);
}
