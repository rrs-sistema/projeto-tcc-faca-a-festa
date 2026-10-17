import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/convidado.dart';
import 'package:app_faca_festa/domain/entities/grupo_convidado.dart';
import 'package:app_faca_festa/domain/repositories/grupo_convidado_repository.dart';
import '../datasources/remote/grupo_convidado_remote_datasource.dart';
import '../models/convidado/convidado_model.dart';
import '../models/convidado/grupo_convidado_model.dart';

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
  Future<void> salvarGrupo(GrupoConvidado grupo) {
    return UpdateOperations.run(() async {
      return remote.salvarGrupo(
        grupo is GrupoConvidadoModel
            ? grupo
            : GrupoConvidadoModel.fromEntity(grupo),
      );
    });
  }

  @override
  Future<void> excluirGrupo(
    String idGrupo, {
    bool desvincularConvidados = true,
  }) {
    return UpdateOperations.run(() async {
      return remote.excluirGrupo(
        idGrupo,
        desvincularConvidados: desvincularConvidados,
      );
    });
  }

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
  ) {
    return UpdateOperations.run(() async {
      return remote.vincularConvidadoAoGrupo(
        _convidadoModel(convidado),
        _grupoModel(grupo),
      );
    });
  }

  @override
  Future<void> removerConvidadoDoGrupo(Convidado convidado) {
    return UpdateOperations.run(() async {
      return remote.removerConvidadoDoGrupo(_convidadoModel(convidado));
    });
  }

  @override
  Future<void> vincularConvidadoNaMesa(
    Convidado convidado,
    String idMesa,
    int numeroMesa,
  ) {
    return UpdateOperations.run(() async {
      return remote.vincularConvidadoNaMesa(
        _convidadoModel(convidado),
        idMesa,
        numeroMesa,
      );
    });
  }

  @override
  Future<void> removerConvidadoDaMesa(Convidado convidado) {
    return UpdateOperations.run(() async {
      return remote.removerConvidadoDaMesa(_convidadoModel(convidado));
    });
  }

  @override
  Future<void> atualizarResumos(List<ResumoGrupoConvidado> resumos) {
    return UpdateOperations.run(() async {
      return remote.atualizarResumos(resumos);
    });
  }
}
