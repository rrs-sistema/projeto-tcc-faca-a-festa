import '../entities/sugestao_base_festa.dart';

abstract class SugestaoBaseFestaRepositoryContract {
  Future<List<SugestaoBaseFesta>> listarSugestoes();

  Future<void> salvarSugestao(SugestaoBaseFesta sugestao);

  Future<void> atualizarSugestao(SugestaoBaseFesta sugestao);

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
