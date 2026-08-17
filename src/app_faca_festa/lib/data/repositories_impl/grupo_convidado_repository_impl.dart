import '../../domain/entities/convidado.dart';
import '../../domain/entities/grupo_convidado.dart';
import '../../domain/repositories/grupo_convidado_repository.dart';
import '../datasources/remote/grupo_convidado_remote_datasource.dart';
import '../models/convidado/convidado_model.dart' hide Convidado;
import '../models/convidado/grupo_convidado_model.dart' hide GrupoConvidado;

class GrupoConvidadoRepositoryImpl implements GrupoConvidadoRepository {
  GrupoConvidadoRepositoryImpl(this.remote);

  final GrupoConvidadoRemoteDatasource remote;

  @override
  Stream<List<GrupoConvidado>> observarGrupos(String idEvento) =>
      remote.observarGrupos(idEvento);

  @override
  Stream<List<Convidado>> observarConvidados(String idEvento) =>
      remote.observarConvidados(idEvento);

  @override
  Future<void> salvarGrupo(GrupoConvidado grupo) => remote.salvarGrupo(
        grupo is GrupoConvidadoModel
            ? grupo
            : GrupoConvidadoModel.fromEntity(grupo),
      );

  @override
  Future<void> excluirGrupo(
    String idGrupo, {
    bool desvincularConvidados = true,
  }) =>
      remote.excluirGrupo(
        idGrupo,
        desvincularConvidados: desvincularConvidados,
      );

  ConvidadoModel _convidadoModel(Convidado convidado) =>
      convidado is ConvidadoModel
          ? convidado
          : ConvidadoModel.fromEntity(convidado);

  GrupoConvidadoModel _grupoModel(GrupoConvidado grupo) =>
      grupo is GrupoConvidadoModel
          ? grupo
          : GrupoConvidadoModel.fromEntity(grupo);

  @override
  Future<void> vincularConvidadoAoGrupo(
    Convidado convidado,
    GrupoConvidado grupo,
  ) =>
      remote.vincularConvidadoAoGrupo(
        _convidadoModel(convidado),
        _grupoModel(grupo),
      );

  @override
  Future<void> removerConvidadoDoGrupo(Convidado convidado) =>
      remote.removerConvidadoDoGrupo(_convidadoModel(convidado));

  @override
  Future<void> vincularConvidadoNaMesa(
    Convidado convidado,
    String idMesa,
    int numeroMesa,
  ) =>
      remote.vincularConvidadoNaMesa(
        _convidadoModel(convidado),
        idMesa,
        numeroMesa,
      );

  @override
  Future<void> removerConvidadoDaMesa(Convidado convidado) =>
      remote.removerConvidadoDaMesa(_convidadoModel(convidado));

  @override
  Future<void> atualizarResumos(List<ResumoGrupoConvidado> resumos) =>
      remote.atualizarResumos(resumos);
}
