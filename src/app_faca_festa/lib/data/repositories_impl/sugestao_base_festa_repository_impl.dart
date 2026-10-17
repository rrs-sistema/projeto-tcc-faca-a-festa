import 'package:app_faca_festa/core/services/update_operations.dart';
import 'package:app_faca_festa/domain/entities/sugestao_base_festa.dart';
import 'package:app_faca_festa/domain/repositories/sugestao_base_festa_repository_contract.dart';

import '../datasources/remote/sugestao_base_festa_remote_datasource.dart';

class SugestaoBaseFestaRepositoryImpl
    implements SugestaoBaseFestaRepositoryContract {
  SugestaoBaseFestaRepositoryImpl(this.remote);

  final SugestaoBaseFestaRemoteDatasource remote;

  @override
  Future<List<SugestaoBaseFesta>> listarSugestoes() {
    return UpdateOperations.run(() async {
      return remote.listarSugestoes();
    });
  }

  @override
  Future<void> salvarSugestao(SugestaoBaseFesta sugestao) {
    return UpdateOperations.run(() async {
      return remote.salvarSugestao(sugestao);
    });
  }

  @override
  Future<void> atualizarSugestao(SugestaoBaseFesta sugestao) {
    return UpdateOperations.run(() async {
      return remote.atualizarSugestao(sugestao);
    });
  }

  @override
  Future<void> ativarDesativarSugestao({
    required String id,
    required bool ativo,
  }) {
    return UpdateOperations.run(() async {
      return remote.ativarDesativarSugestao(id: id, ativo: ativo);
    });
  }

  @override
  Future<void> excluirLogicamente(String id) {
    return UpdateOperations.run(() async {
      return remote.excluirLogicamente(id);
    });
  }

  @override
  Future<int> importarSugestoesTeste({
    bool sobrescrever = true,
  }) {
    return UpdateOperations.run(() async {
      return remote.importarSugestoesTeste(
        sobrescrever: sobrescrever,
      );
    });
  }
}
