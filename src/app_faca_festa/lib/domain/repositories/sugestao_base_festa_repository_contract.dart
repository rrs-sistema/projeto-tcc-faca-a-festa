import '../../data/models/evento/sugestao_base_festa_model.dart';

abstract class SugestaoBaseFestaRepositoryContract {
  Future<List<SugestaoBaseFestaModel>> listarSugestoes();

  Future<void> salvarSugestao(SugestaoBaseFestaModel sugestao);

  Future<void> atualizarSugestao(SugestaoBaseFestaModel sugestao);

  Future<void> ativarDesativarSugestao({
    required String id,
    required bool ativo,
  });

  Future<void> excluirLogicamente(String id);

  Future<int> importarSugestoesTeste(
    List<Map<String, dynamic>> sugestoes, {
    bool sobrescrever = true,
  });
}
